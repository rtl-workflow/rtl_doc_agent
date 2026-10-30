#!/usr/bin/env python3.11
"""rexec watcher: runs signed jobs that remote_exec.py drops into ~/jobs/inbox via FTP.

Protocol (all paths under ~/jobs, FTP path /jobs):
  inbox/<id>.tar.gz          optional payload, uploaded first
  inbox/<id>.job.json        job spec + HMAC signature, uploaded last
  inbox/<id>.kill.json       signed request to kill a queued/running job
  outbox/<id>.log            combined stdout/stderr, written live
  outbox/<id>.summary.txt    status, error-like lines and log tail
  outbox/<id>.result.tar.gz  files collected after the command (optional)
  outbox/<id>.done           final status JSON, written last
  outbox/heartbeat.json      refreshed every loop

Started by setup_watcher.sh inside tmux session "rexec". The watcher reloads itself
when watcher.py is replaced (e.g. via FTP) and no job is running.
Optional ~/jobs/watcher.json overrides {"max_parallel": N, "default_timeout": S, "keep_days": D}.
"""
import collections
import fcntl
import glob
import hashlib
import hmac
import json
import logging
import logging.handlers
import os
import py_compile
import re
import shutil
import signal
import socket
import subprocess
import sys
import tarfile
import threading
import time
from pathlib import Path

VERSION = "1.2"
HOME = Path.home().resolve()
JOBS = HOME / "jobs"
INBOX, OUTBOX, WORK, ARCHIVE = (JOBS / d for d in ("inbox", "outbox", "work", "archive"))
KEY_FILE = JOBS / "rexec.key"
SETTINGS_FILE = JOBS / "watcher.json"
SELF = Path(__file__).resolve()


def _settings():
    try:
        return json.loads(SETTINGS_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


_S = _settings()
POLL = 1.0                     # inbox scan interval, seconds
MAX_PARALLEL = int(_S.get("max_parallel", 8))       # jobs running at the same time (VCS waits for licenses)
DEFAULT_TIMEOUT = int(_S.get("default_timeout", 1800))  # seconds, when the job does not give one
MAX_TIMEOUT = 24 * 3600
KEEP_DAYS = int(_S.get("keep_days", 7))             # outbox/archive/work entries older than this are removed
MAX_COLLECT_MB = 500
PARTIAL_GRACE = 120            # seconds to wait for a half-uploaded job file
MAX_JOB_AGE = 24 * 3600        # reject jobs created longer ago than this (replay guard)
EXIT_LOCKED = 3                # another watcher holds the lock; setup loop stops on this

ID_RE = re.compile(r"^[A-Za-z0-9_.-]{1,80}$")
ERROR_RE = re.compile(r"\bError\b|\bERROR\b|\bFatal\b|\bFATAL\b|UVM_ERROR|UVM_FATAL|\bFAIL(ED)?\b"
                      r"|Assertion|^\s*\*[EF],|Error-\[|Traceback")
ENV_RE = re.compile(r"licen[cs]e.*(fail|error|unavailable|not available|checkout)"
                    r"|unable to (check ?out|obtain).*licen|FLEXnet|lmgrd|command not found", re.I)
MAX_MATCH_LINES = 200
SCAN_SUFFIXES = (".log", ".rpt")   # collected files whose error-like lines go into the summary
TAIL_LINES = 80

log = logging.getLogger("rexec")


class JobError(Exception):
    pass


def canon(obj):
    body = {k: v for k, v in obj.items() if k != "sig"}
    return json.dumps(body, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()


def verify(obj, key):
    want = hmac.new(key, canon(obj), hashlib.sha256).hexdigest()
    return hmac.compare_digest(str(obj.get("sig", "")), want)


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def write_atomic(path, data):
    tmp = path.with_name("." + path.name + ".tmp")
    tmp.write_bytes(data)
    os.replace(tmp, path)


def rpath(p, base=HOME):
    p = os.path.expanduser(str(p))
    return (Path(p) if os.path.isabs(p) else base / p).resolve()


def inside_home(p):
    return p == HOME or HOME in p.parents


def kill_tree(proc, grace=10):
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(proc.pid, sig)
        except ProcessLookupError:
            return
        try:
            proc.wait(timeout=grace)
            return
        except subprocess.TimeoutExpired:
            pass


def scan_log(path):
    """Return (error-like lines, tail lines, env-problem flag) without loading the whole log."""
    matches, tail, env = [], collections.deque(maxlen=TAIL_LINES), False
    if not path.exists():
        return matches, list(tail), env
    with open(path, "rb") as f:
        for n, raw in enumerate(f, 1):
            line = raw.decode("utf-8", "replace").rstrip("\r\n")[:500]
            tail.append(line)
            if len(matches) < MAX_MATCH_LINES and ERROR_RE.search(line):
                matches.append(f"{n}: {line}")
            if not env and ENV_RE.search(line):
                env = True
    return matches, list(tail), env


class Watcher:
    def __init__(self):
        self.key = KEY_FILE.read_bytes().strip()
        self.started = time.time()
        self.lock = threading.Lock()
        self.running = {}      # id -> state dict
        self.queue = []        # accepted jobs waiting for a slot
        self.seen = set()
        self.self_mtime = SELF.stat().st_mtime
        self.last_clean = 0.0
        self.mark_orphans()

    # ---------- main loop ----------
    def loop(self):
        log.info("watcher %s started, pid %d", VERSION, os.getpid())
        while True:
            try:
                self.scan()
                self.start_queued()
                self.heartbeat()
                if time.time() - self.last_clean > 3600:
                    self.cleanup()
                self.maybe_reload()
            except Exception:
                log.exception("loop error")
            time.sleep(POLL)

    def scan(self):
        for f in sorted(INBOX.glob("*.kill.json")):
            self.handle_kill(f, f.name[:-len(".kill.json")])
        for f in sorted(INBOX.glob("*.job.json")):
            jid = f.name[:-len(".job.json")]
            if jid not in self.seen:
                self.accept(f, jid)

    # ---------- intake ----------
    def accept(self, f, jid):
        age = time.time() - f.stat().st_mtime
        try:
            job = json.loads(f.read_text(encoding="utf-8"))
        except (ValueError, UnicodeDecodeError):
            if age < PARTIAL_GRACE:
                return  # still uploading
            return self.reject(f, jid, "job file is not valid JSON")
        if not ID_RE.match(jid) or job.get("id") != jid:
            return self.reject(f, jid, "bad job id")
        if not verify(job, self.key):
            return self.reject(f, jid, "bad signature (key mismatch?)")
        if abs(time.time() - float(job.get("created", 0))) > MAX_JOB_AGE:
            return self.reject(f, jid, "job too old")
        adir = ARCHIVE / jid
        if adir.exists() or (OUTBOX / f"{jid}.done").exists():
            log.warning("duplicate job %s ignored", jid)
            f.unlink()
            return
        payload = INBOX / f"{jid}.tar.gz"
        pl = job.get("payload")
        if pl:
            ok = payload.exists() and payload.stat().st_size == pl["size"] and sha256_file(payload) == pl["sha256"]
            if not ok:
                if age < PARTIAL_GRACE:
                    return
                return self.reject(f, jid, "payload missing or checksum mismatch")
        adir.mkdir(parents=True)
        shutil.move(str(f), adir / "job.json")
        if pl:
            shutil.move(str(payload), adir / "payload.tar.gz")
        self.seen.add(jid)
        self.queue.append(job)
        log.info("accepted %s: %s", jid, (job.get("cmd") or "")[:200])

    def reject(self, f, jid, msg):
        log.warning("reject %s: %s", f.name, msg)
        rdir = ARCHIVE / "_rejected"
        rdir.mkdir(parents=True, exist_ok=True)
        shutil.move(str(f), rdir / f"{int(time.time())}_{f.name}")
        if ID_RE.match(jid) and not (OUTBOX / f"{jid}.done").exists():
            self.seen.add(jid)
            now = time.time()
            self.finish({"id": jid, "status": "rejected", "exit_code": None, "error": msg,
                         "start": now, "end": now, "duration": 0, "notes": []})

    def handle_kill(self, f, jid):
        try:
            req = json.loads(f.read_text(encoding="utf-8"))
        except (ValueError, UnicodeDecodeError):
            if time.time() - f.stat().st_mtime < PARTIAL_GRACE:
                return
            req = {}
        f.unlink()
        if req.get("id") != jid or req.get("action") != "kill" or not verify(req, self.key):
            log.warning("ignored invalid kill request %s", f.name)
            return
        with self.lock:
            st = self.running.get(jid)
            queued = next((j for j in self.queue if j["id"] == jid), None)
            if queued:
                self.queue.remove(queued)
        if st:
            log.info("killing %s", jid)
            st["killed"] = True
            if st.get("proc"):
                threading.Thread(target=kill_tree, args=(st["proc"],), daemon=True).start()
        elif queued:
            now = time.time()
            self.finish({"id": jid, "status": "killed", "exit_code": None, "error": "killed before start",
                         "start": now, "end": now, "duration": 0, "notes": []})

    # ---------- execution ----------
    def start_queued(self):
        while self.queue and len(self.running) < MAX_PARALLEL:
            job = self.queue.pop(0)
            st = {"proc": None, "killed": False, "timed_out": False, "start": time.time()}
            with self.lock:
                self.running[job["id"]] = st
            threading.Thread(target=self.run_job, args=(job, st), daemon=True).start()

    def run_job(self, job, st):
        jid = job["id"]
        res = {"id": jid, "status": "error", "exit_code": None, "error": None,
               "start": st["start"], "notes": [], "meta": job.get("meta") or {}}
        cwd = None
        log_path = OUTBOX / f"{jid}.log"
        try:
            with open(log_path, "wb") as logf:
                dest = None
                if job.get("payload"):
                    dest = rpath(job.get("dest") or WORK / jid)
                    if not inside_home(dest) or dest in (HOME, JOBS) or JOBS in dest.parents and WORK not in dest.parents:
                        raise JobError(f"dest {dest} must be a sub-directory of {HOME} (outside ~/jobs)")
                    if job.get("clean") and dest.exists():
                        shutil.rmtree(dest)
                    dest.mkdir(parents=True, exist_ok=True)
                    with tarfile.open(ARCHIVE / jid / "payload.tar.gz") as tf:
                        tf.extractall(dest, filter="data")
                    logf.write(f"[rexec] payload extracted to {dest}\n".encode())
                    res["dest"] = str(dest)
                cwd = rpath(job.get("cwd") or dest or WORK / jid)
                if not cwd.exists():
                    if not inside_home(cwd):
                        raise JobError(f"cwd {cwd} does not exist")
                    cwd.mkdir(parents=True)
                res["cwd"] = str(cwd)
                if job.get("cmd") and not st["killed"]:
                    timeout = min(int(job.get("timeout") or DEFAULT_TIMEOUT), MAX_TIMEOUT)
                    logf.flush()
                    proc = subprocess.Popen(["bash", "-lc", job["cmd"]], cwd=cwd, stdin=subprocess.DEVNULL,
                                            stdout=logf, stderr=subprocess.STDOUT, start_new_session=True,
                                            env=dict(os.environ, REXEC_JOB_ID=jid))
                    st["proc"] = proc
                    try:
                        rc = proc.wait(timeout=timeout)
                    except subprocess.TimeoutExpired:
                        st["timed_out"] = True
                        kill_tree(proc)
                        rc = proc.wait()
                    res["exit_code"] = rc
                    if st["killed"]:
                        res["status"] = "killed"
                    elif st["timed_out"]:
                        res["status"], res["error"] = "timeout", f"timed out after {timeout}s"
                    else:
                        res["status"] = "ok" if rc == 0 else "fail"
                elif st["killed"]:
                    res["status"] = "killed"
                else:
                    res["status"], res["exit_code"] = "ok", 0
                if job.get("collect"):
                    self.collect(job, cwd, res)
        except JobError as e:
            res["error"] = str(e)
        except Exception as e:
            log.exception("job %s failed", jid)
            res["error"] = f"{type(e).__name__}: {e}"
        finally:
            res["end"] = time.time()
            res["duration"] = round(res["end"] - res["start"], 2)
            self.finish(res, log_path)
            # results are already in the outbox; build directories (simv, csrc) would fill the disk
            if job.get("cleanup") and cwd is not None and WORK in cwd.parents:
                shutil.rmtree(cwd, ignore_errors=True)
            with self.lock:
                self.running.pop(jid, None)
            log.info("finished %s: %s rc=%s", jid, res["status"], res["exit_code"])

    def collect(self, job, cwd, res):
        limit = int(job.get("max_collect_mb") or MAX_COLLECT_MB) << 20
        files, total = {}, 0
        for pat in job["collect"]:
            p = os.path.expanduser(pat)
            p = p if os.path.isabs(p) else str(cwd / p)
            matches = sorted(glob.glob(p, recursive=True))
            if not matches:
                res["notes"].append(f"collect: no match for {pat}")
            for m in matches:
                paths = [m]
                if os.path.isdir(m):
                    paths = [os.path.join(r, n) for r, _, ns in os.walk(m) for n in sorted(ns)]
                for fp in paths:
                    if fp in files or not os.path.isfile(fp):
                        continue
                    size = os.path.getsize(fp)
                    if total + size > limit:
                        res["notes"].append(f"collect: skipped {fp} ({size} bytes, over {limit >> 20} MB limit)")
                        continue
                    total += size
                    rp = Path(fp).resolve()
                    files[fp] = str(rp.relative_to(cwd)) if cwd in rp.parents else fp.lstrip("/")
        if not files:
            return
        out = OUTBOX / f"{job['id']}.result.tar.gz"
        tmp = out.with_name("." + out.name + ".tmp")
        with tarfile.open(tmp, "w:gz", dereference=True) as tf:
            for fp, arc in files.items():
                try:
                    tf.add(fp, arcname=arc, recursive=False)
                except OSError as e:
                    res["notes"].append(f"collect: {fp}: {e}")
        os.replace(tmp, out)
        res["result"] = out.name
        res["collected"] = len(files)
        res["_scan"] = [(fp, arc) for fp, arc in files.items() if arc.endswith(SCAN_SUFFIXES)]

    def finish(self, res, log_path=None):
        jid = res["id"]
        matches, tail, env = scan_log(log_path) if log_path else ([], [], False)
        for fp, arc in res.pop("_scan", []):
            m, _, e = scan_log(Path(fp))
            matches += [f"{arc}:{x}" for x in m][:max(0, MAX_MATCH_LINES - len(matches))]
            env = env or e
        if res["status"] == "fail" and env:
            res["env_error"] = True
        head = [f"job      {jid}",
                f"status   {res['status']}" + ("  (ENV_ERROR: license/tool environment problem)" if res.get("env_error") else ""),
                f"exit     {res['exit_code']}",
                f"duration {res.get('duration')}s",
                f"cwd      {res.get('cwd', '')}"]
        if res.get("error"):
            head.append(f"error    {res['error']}")
        head += [f"note     {n}" for n in res["notes"]]
        body = head + ["", f"==== error-like lines ({len(matches)}, max {MAX_MATCH_LINES}) ===="] + matches
        body += ["", f"==== last {len(tail)} lines ===="] + tail
        write_atomic(OUTBOX / f"{jid}.summary.txt", ("\n".join(body) + "\n").encode())
        write_atomic(OUTBOX / f"{jid}.done", json.dumps(res, ensure_ascii=False, indent=1).encode())

    # ---------- housekeeping ----------
    def heartbeat(self):
        with self.lock:
            running = sorted(self.running)
        hb = {"time": time.time(), "started": self.started, "pid": os.getpid(), "version": VERSION,
              "host": socket.gethostname(), "max_parallel": MAX_PARALLEL,
              "running": running, "queued": [j["id"] for j in self.queue]}
        write_atomic(OUTBOX / "heartbeat.json", json.dumps(hb).encode())

    def mark_orphans(self):
        """Jobs accepted by a previous watcher process that never finished."""
        for adir in ARCHIVE.iterdir():
            if adir.name.startswith("_") or (OUTBOX / f"{adir.name}.done").exists():
                continue
            if time.time() - adir.stat().st_mtime < KEEP_DAYS * 86400:
                self.seen.add(adir.name)
                now = time.time()
                self.finish({"id": adir.name, "status": "error", "exit_code": None,
                             "error": "watcher restarted while the job was queued or running",
                             "start": now, "end": now, "duration": 0, "notes": []},
                            OUTBOX / f"{adir.name}.log")

    def cleanup(self):
        self.last_clean = time.time()
        cutoff = self.last_clean - KEEP_DAYS * 86400
        with self.lock:
            busy = set(self.running) | {j["id"] for j in self.queue}
        for d in (ARCHIVE, WORK):
            for p in d.iterdir():
                if p.name not in busy and p.stat().st_mtime < cutoff:
                    shutil.rmtree(p, ignore_errors=True) if p.is_dir() else p.unlink()
        for p in OUTBOX.iterdir():
            if p.name != "heartbeat.json" and p.name.split(".")[0] not in busy and p.stat().st_mtime < cutoff:
                p.unlink()

    def maybe_reload(self):
        mtime = SELF.stat().st_mtime
        if mtime == self.self_mtime or time.time() - mtime < 3 or self.running or self.queue:
            return
        self.self_mtime = mtime
        try:
            py_compile.compile(str(SELF), doraise=True)
        except py_compile.PyCompileError as e:
            log.error("new watcher.py does not compile, keep running old one: %s", e)
            return
        log.info("watcher.py changed, reloading")
        os.execv(sys.executable, [sys.executable, str(SELF)])


def main():
    for d in (INBOX, OUTBOX, WORK, ARCHIVE):
        d.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s",
                        handlers=[logging.StreamHandler(),
                                  logging.handlers.RotatingFileHandler(JOBS / "watcher.log", maxBytes=5 << 20,
                                                                       backupCount=3)])
    lockf = open(JOBS / "watcher.lock", "w")
    try:
        fcntl.flock(lockf, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        log.error("another watcher is already running")
        sys.exit(EXIT_LOCKED)
    if not KEY_FILE.exists():
        log.error("missing %s; run setup_watcher.sh first", KEY_FILE)
        sys.exit(EXIT_LOCKED)
    Watcher().loop()


if __name__ == "__main__":
    main()
