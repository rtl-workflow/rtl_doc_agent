"""Offline security regression tests for the connect entry point."""
import argparse
import contextlib
import io
import json
import base64
import hashlib
import sys
import tempfile
import time
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import eda_connect as ec
import rtlflow


class ConnectTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        keyring = MagicMock()
        keyring.get_password.return_value = None
        patcher = patch.dict(sys.modules, keyring=keyring)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.addCleanup(self.tmp.cleanup)
        self.directory = Path(self.tmp.name)
        self.api = MagicMock()
        self.api.read_ini.return_value = {"host": "eda.example", "user": "alice", "port": "21"}
        self.rx = MagicMock()
        self.rx.config_dir.return_value = self.directory
        self.rx.key_file.return_value = self.directory / "key"
        self.rx.PASSWORD_FILE = "password"
        self.rx.KEYRING_SERVICE = "rexec-ftp"
        self.rx.FTP_JOBS = "/jobs"
        self.rx.HEARTBEAT_MAX_AGE = 60
        self.rx.submit.return_value = ("probe-job", {}, None)
        self.r = self.rx.Remote.return_value
        self.r.get.return_value = None
        self.rx.heartbeat.return_value = None
        self.args = SimpleNamespace(host=None, user=None, port=None, credential_dialog=False,
                                    start_watcher="manual", ssh_port="22", ssh_fingerprint=None, wait_seconds=1)
        self.creds = patch.object(ec, "password_for", return_value="secret")
        self.password = self.creds.start()
        self.addCleanup(self.creds.stop)

    def run_connect(self):
        return ec.run(self.args, self.api, self.rx)

    def live(self):
        self.rx.key_file.return_value.write_text("test-key")
        self.rx.heartbeat.return_value = dict(time=time.time(), running=[], queued=[])
        self.r.get.return_value = b"{}"
        fin = self.rx.fetch.return_value
        fin.status = "ok"
        fin.output.return_value = "PROBE_DONE"

    def test_configured_live_reuse_no_deployment_or_config_mutation(self):
        self.live()
        result, code = self.run_connect()
        self.assertEqual((result["action"], code), ("ready", 0))
        self.api.write_ini.assert_not_called()
        self.r.put.assert_not_called()
        self.rx.submit.assert_called_once()
        self.assertNotIn("pip", self.rx.submit.call_args.args[1])

    def test_cli_missing_metadata_emits_json_and_code(self):
        output = io.StringIO()
        output.reconfigure = lambda **kwargs: None
        with patch.object(sys, "argv", ["rtlflow.py", "connect"]), \
             patch.object(sys, "stdout", output), patch.dict(sys.modules, remote_exec=self.rx):
            code = rtlflow.main()
        self.assertEqual(code, 2)
        self.assertEqual(json.loads(output.getvalue())["action"], "input_required")

    def test_cli_bad_argument_redacts_value(self):
        output = io.StringIO()
        output.reconfigure = lambda **kwargs: None
        with patch.object(sys, "argv", ["rtlflow.py", "connect", "--password", "secret"]), \
             patch.object(sys, "stdout", output), self.assertRaises(SystemExit) as raised:
            rtlflow.main()
        self.assertEqual(raised.exception.code, 3)
        self.assertEqual(json.loads(output.getvalue())["action"], "invalid_input")
        self.assertNotIn("secret", output.getvalue())

    def test_cleanup_error_redacted(self):
        self.r.close.side_effect = RuntimeError("secret")
        self.assertNotIn("secret", str(self.run_connect()))

    def test_missing_input(self):
        self.api.read_ini.return_value = {}
        result, code = self.run_connect()
        self.assertEqual(result["fields"], ["host", "user"])
        self.assertEqual(code, 2)
        self.password.assert_not_called()

    def test_missing_credentials(self):
        self.password.side_effect = ec.Stop("credentials_required")
        self.assertEqual(self.run_connect()[0]["action"], "credentials_required")
        self.rx.Remote.assert_not_called()

    def test_endpoint_switch_does_not_read_credentials(self):
        self.args.host = "other.example"
        self.assertEqual(self.run_connect()[0]["action"], "endpoint_change_required")
        self.password.assert_not_called()
        self.api.write_ini.assert_not_called()

    def test_hostile_metadata(self):
        for field, value in [("host", "eda\nkey=x"), ("host", "host:22"), ("host", "$(id)"),
                             ("user", "x\rport=1"), ("user", "a;b"), ("port", "65536"), ("ssh_port", "0")]:
            with self.subTest(field=field, value=value):
                old = getattr(self.args, field)
                setattr(self.args, field, value)
                self.assertEqual(self.run_connect()[0]["action"], "invalid_input")
                setattr(self.args, field, old)
        self.password.assert_not_called()

    def test_manual_bootstrap_no_unbounded_wait(self):
        result, code = self.run_connect()
        self.assertEqual((result["action"], code), ("bootstrap_required", 2))
        self.assertEqual(result["command"], "bash ~/setup_watcher.sh --if-stopped")
        self.assertEqual(self.r.put.call_count, 3)
        self.rx.submit.assert_not_called()

    def test_live_missing_key_no_overwrite(self):
        self.rx.heartbeat.return_value = dict(time=time.time())
        self.assertEqual(self.run_connect()[0]["action"], "signing_key_required")
        self.r.put.assert_not_called()
        self.assertFalse(self.rx.key_file.return_value.exists())

    def test_signed_rejection_no_takeover(self):
        self.live()
        self.rx.fetch.return_value.status = "rejected"
        self.args.start_watcher = "ssh"
        with patch.object(ec, "ssh_preflight") as ssh:
            self.assertEqual(self.run_connect()[0]["action"], "signing_key_mismatch")
            ssh.assert_not_called()
        self.r.put.assert_not_called()

    def test_offline_mismatched_server_key_not_overwritten(self):
        self.r.get.return_value = b"server-key"
        self.assertEqual(self.run_connect()[0]["action"], "signing_key_mismatch")
        self.r.put.assert_not_called()
        self.assertFalse(self.rx.key_file.return_value.exists())

    def test_auth_failure_prevents_deployment(self):
        self.args.start_watcher = "ssh"
        with patch.object(ec, "ssh_preflight", side_effect=ec.Stop("ssh_auth_failed", 3)):
            self.assertEqual(self.run_connect()[0]["action"], "ssh_auth_failed")
        self.r.put.assert_not_called()
        self.api.write_ini.assert_not_called()

    def test_active_jobs_prevent_deployment(self):
        self.rx.heartbeat.return_value = dict(time=0, running=["job"])
        self.assertEqual(self.run_connect()[0]["action"], "active_jobs")
        self.r.put.assert_not_called()

    def test_bounded_wait(self):
        self.live()
        self.r.get.return_value = None
        with patch.object(ec.time, "monotonic", side_effect=[0, 0, 0, 2, 2]), patch.object(ec.time, "sleep"):
            result, code = self.run_connect()
        self.assertEqual((result["action"], code), ("timeout", 124))

    def test_exception_text_is_not_exposed(self):
        self.r.conn.side_effect = RuntimeError("secret password")
        self.assertNotIn("secret", str(self.run_connect()))

    def test_no_keyring_does_not_open_dialog(self):
        self.creds.stop()
        self.args.credential_dialog = True
        with patch.object(ec, "secure_store", side_effect=ec.Stop("credential_store_required")), \
             patch.object(ec, "credential_dialog") as dialog:
            self.assertEqual(self.run_connect()[0]["action"], "credential_store_required")
            dialog.assert_not_called()

    def test_cancelled_dialog(self):
        self.creds.stop()
        store = MagicMock()
        store.get_password.return_value = None
        self.args.credential_dialog = True
        with patch.object(ec, "secure_store", return_value=store), \
             patch.object(ec, "credential_dialog", side_effect=ec.Stop("cancelled", 130)):
            self.assertEqual(self.run_connect()[1], 130)
            store.set_password.assert_not_called()

    def test_dialog_forces_refresh_of_existing_password(self):
        self.creds.stop()
        sys.modules["keyring"].get_password.return_value = "old-secret"
        store = MagicMock()
        store.get_password.return_value = "new-secret"
        cfg = dict(host="eda.example", user="alice", dir=self.directory)
        with patch.object(ec, "secure_store", return_value=store), \
             patch.object(ec, "credential_dialog", return_value="new-secret") as dialog:
            self.assertEqual(ec.password_for(self.rx, cfg, True, True), "new-secret")
        dialog.assert_called_once_with("eda.example", "alice")
        store.set_password.assert_called_once_with("rexec-ftp", "alice@eda.example", "new-secret")
        sys.modules["keyring"].get_password.assert_not_called()

    def test_cancelled_refresh_preserves_existing_password(self):
        self.creds.stop()
        sys.modules["keyring"].get_password.return_value = "old-secret"
        store = MagicMock()
        store.get_password.return_value = "old-secret"
        cfg = dict(host="eda.example", user="alice", dir=self.directory)
        with patch.object(ec, "secure_store", return_value=store), \
             patch.object(ec, "credential_dialog", side_effect=ec.Stop("cancelled", 130)), \
             self.assertRaises(ec.Stop) as raised:
            ec.password_for(self.rx, cfg, True, True)
        self.assertEqual(raised.exception.code, 130)
        store.set_password.assert_not_called()
        store.delete_password.assert_not_called()
        self.assertEqual(store.get_password.return_value, "old-secret")

    def test_failed_ftp_auth_does_not_retry(self):
        self.r.conn.side_effect = RuntimeError("invalid password secret")
        self.assertEqual(self.run_connect()[0]["action"], "connection_failed")
        self.r.conn.assert_called_once()
        self.rx.heartbeat.assert_not_called()
        self.r.put.assert_not_called()

    def test_existing_cross_platform_keyring_reused(self):
        self.creds.stop()
        sys.modules["keyring"].get_password.return_value = "existing-secret"
        cfg = dict(host="eda.example", user="alice", dir=self.directory)
        with patch.object(ec, "secure_store") as native:
            self.assertEqual(ec.password_for(self.rx, cfg, True, False), "existing-secret")
            native.assert_not_called()

    def test_ssh_bootstrap_failed_without_reading_output(self):
        self.args.start_watcher = "ssh"
        ssh = MagicMock()
        channel = ssh.open_session.return_value
        channel.exit_status_ready.return_value = True
        channel.recv_exit_status.return_value = 1
        with patch.object(ec, "ssh_preflight", return_value=ssh):
            self.assertEqual(self.run_connect()[0]["action"], "bootstrap_failed")
        channel.exec_command.assert_called_once_with(ec.BOOTSTRAP)
        channel.recv.assert_not_called()
        channel.close.assert_called_once()

    def test_ssh_success_requires_heartbeat_and_signed_probe(self):
        self.args.start_watcher = "ssh"
        hb = dict(time=time.time(), running=[], queued=[])
        self.rx.heartbeat.side_effect = [None, None, None, hb, hb]
        self.r.get.side_effect = [None, None, b"{}"]
        self.rx.fetch.return_value.status = "ok"
        self.rx.fetch.return_value.output.return_value = "PROBE_DONE"
        ssh = MagicMock()
        with patch.object(ec, "ssh_preflight", return_value=ssh):
            result, code = self.run_connect()
        self.assertEqual((result["action"], code), ("ready", 0))
        ssh.open_session.return_value.exec_command.assert_called_once_with(ec.BOOTSTRAP)
        self.rx.submit.assert_called_once()

    def test_malformed_heartbeat_fails_closed(self):
        self.rx.heartbeat.return_value = {"running": []}
        self.assertEqual(self.run_connect()[0]["action"], "connection_failed")
        self.r.put.assert_not_called()

    def test_legacy_password_only_with_same_config(self):
        self.creds.stop()
        (self.directory / "password").write_text("legacy-secret")
        cfg = dict(host="eda.example", user="alice", dir=self.directory)
        with patch.object(ec, "secure_store", side_effect=ec.Stop("credential_store_required")):
            self.assertEqual(ec.password_for(self.rx, cfg, True, False), "legacy-secret")
            with self.assertRaises(ec.Stop):
                ec.password_for(self.rx, cfg, False, False)


class SSHTests(unittest.TestCase):
    def setUp(self):
        self.pm = MagicMock()
        self.pm.AuthenticationException = type("AuthenticationException", (Exception,), {})
        self.transport = self.pm.Transport.return_value
        self.transport.get_remote_server_key.return_value.asbytes.return_value = b"test-host-key"
        self.pin = "SHA256:" + base64.b64encode(hashlib.sha256(b"test-host-key").digest()).decode().rstrip("=")
        self.pm.HostKeys.return_value.lookup.return_value = None
        self.cfg = dict(host="eda.example", user="alice")

    def preflight(self, pin=None):
        with patch.dict(sys.modules, paramiko=self.pm), patch.object(ec.socket, "create_connection"), \
             patch.object(Path, "is_file", return_value=False):
            return ec.ssh_preflight(self.cfg, 22, pin, "secret")

    def test_missing_paramiko_returns_install_action(self):
        with patch.dict(sys.modules, paramiko=None), self.assertRaises(ec.Stop) as raised:
            ec.ssh_preflight(self.cfg, 22, None, "secret")
        self.assertEqual(raised.exception.result["action"], "dependency_required")
        self.assertEqual(raised.exception.result["command"], "python -m pip install paramiko")

    def test_unknown_key_returned_before_any_auth(self):
        with self.assertRaises(ec.Stop) as raised:
            self.preflight()
        self.assertEqual(raised.exception.result["action"], "ssh_host_key_required")
        self.assertEqual(raised.exception.result["fingerprint"], self.pin)
        self.transport.auth_password.assert_not_called()
        self.transport.auth_publickey.assert_not_called()
        self.pm.Agent.assert_not_called()

    def test_wrong_pin_rejected_before_auth(self):
        with self.assertRaises(ec.Stop) as raised:
            self.preflight("SHA256:" + "A" * 43)
        self.assertEqual(raised.exception.result["action"], "ssh_host_key_mismatch")
        self.pm.Agent.assert_not_called()

    def test_explicit_pin_allows_auth_without_modifying_trust(self):
        self.transport.is_authenticated.return_value = True
        self.assertIs(self.preflight(self.pin), self.transport)
        self.pm.HostKeys.return_value.save.assert_not_called()

    def test_changed_known_key_refused(self):
        self.pm.HostKeys.return_value.lookup.return_value = {"ssh-ed25519": "old"}
        self.pm.HostKeys.return_value.check.return_value = False
        with self.assertRaises(ec.Stop) as raised:
            self.preflight()
        self.assertEqual(raised.exception.result["action"], "ssh_host_key_mismatch")
        self.pm.Agent.assert_not_called()

    def test_auth_failure_redacts_details(self):
        self.transport.is_authenticated.return_value = False
        self.transport.auth_password.side_effect = self.pm.AuthenticationException("secret")
        with self.assertRaises(ec.Stop) as raised:
            self.preflight(self.pin)
        self.assertEqual(raised.exception.result["action"], "ssh_auth_failed")
        self.assertNotIn("secret", str(raised.exception.result))


if __name__ == "__main__":
    unittest.main()
