"""Exercise bootstrap's no-restart mode using isolated HOME and stubbed services."""
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'remote_server' / 'setup_watcher.sh'


@unittest.skipUnless(shutil.which('bash'), 'requires Bash (run on Linux)')
class BootstrapTests(unittest.TestCase):
    def run_script(self, mode, automatic=True):
        with tempfile.TemporaryDirectory(prefix='rtlflow-bootstrap-test-') as directory:
            root = Path(directory).resolve()
            home, tools = root / 'home', root / 'bin'
            home.mkdir()
            tools.mkdir()
            (home / 'rexec_watcher.py').write_text('# test fixture only\n')
            (home / 'rexec.key').write_text('test-key\n')
            tmux = tools / 'tmux'
            tmux.write_text('''#!/bin/bash
printf '%s\\n' "$1" >> "$TEST_LOG"
case "$1" in
  has-session) [ "$TEST_MODE" = existing ]; exit $? ;;
  new-session)
    [ "$TEST_MODE" = race ] && exit 42
    printf '{}' > "$HOME/jobs/outbox/heartbeat.json"
    exit 0 ;;
  kill-session) exit 0 ;;
esac
exit 1
''')
            for name in ('python3.11', 'sleep', 'crontab'):
                (tools / name).write_text('#!/bin/sh\nexit 0\n')
            for file in tools.iterdir():
                file.chmod(0o755)
            log = root / 'tmux.log'
            env = dict(os.environ, HOME=str(home), PATH=str(tools) + os.pathsep + os.environ['PATH'],
                       TEST_LOG=str(log), TEST_MODE=mode)
            command = [shutil.which('bash'), str(SCRIPT)] + (['--if-stopped'] if automatic else [])
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=10)
            calls = log.read_text().splitlines() if log.exists() else []
            return result, calls, (home / 'jobs').exists()

    def test_existing_session_is_left_completely_untouched(self):
        result, calls, jobs = self.run_script('existing')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ['has-session'])
        self.assertFalse(jobs)

    def test_concurrent_session_is_never_killed(self):
        result, calls, _ = self.run_script('race')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(calls, ['has-session', 'new-session'])

    def test_first_bootstrap_starts_without_kill(self):
        result, calls, jobs = self.run_script('absent')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ['has-session', 'new-session'])
        self.assertTrue(jobs)

    def test_explicit_legacy_restart_preserved(self):
        result, calls, _ = self.run_script('absent', automatic=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ['kill-session', 'new-session'])


if __name__ == '__main__':
    unittest.main()
