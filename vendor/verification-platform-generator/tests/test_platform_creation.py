"""Safety tests call the scaffold helper on temporary fixtures; no EDA runs."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "logic-verify-uvm-platform-gen" / "scripts" / "create_bt_platform.py"
spec = importlib.util.spec_from_file_location("platform_creation", SCRIPT)
creation = importlib.util.module_from_spec(spec)
spec.loader.exec_module(creation)


class PlatformCreationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.templates = self.root / "templates"
        self.output = self.root / "output"
        for demo in ("superbench_demo", "gaea_demo"):
            source = self.templates / demo / demo
            source.mkdir(parents=True)
            (source / "sample.sv").write_bytes(b"// source\r\n")
            (source / "binary.bin").write_bytes(b"\x00\r\n\xff")

    def create(self, name="unit", index="1"):
        return creation.create_platform(self.templates, self.output, index, name)

    def test_invalid_names_fail_before_creating_output(self):
        for name in ("", "../escape", "a/b", "a\\b", "/absolute", "C:\\escape", "1abc", "a\n", "CON", "nul", "LPT1"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                self.create(name)
        self.assertFalse(self.output.exists())

    def test_invalid_profile_and_missing_template_do_not_create_output(self):
        with self.assertRaises(ValueError):
            self.create(index="3")
        with self.assertRaises(ValueError):
            creation.create_platform(self.root / "absent", self.output, "1", "unit")
        self.assertFalse(self.output.exists())

    def test_both_profiles_copy_bytes_and_report_only_scaffold(self):
        for index, profile in (("1", "legacy_superbench"), ("2", "legacy_gaea")):
            result = self.create(index=index)
            dest = Path(result["platform_path"])
            self.assertIn(self.output.resolve(), dest.parents)
            self.assertEqual(dest.name, "unit")
            self.assertEqual((dest / "sample.sv").read_bytes(), b"// source\r\n")
            self.assertEqual((dest / "binary.bin").read_bytes(), b"\x00\r\n\xff")
            self.assertEqual(result["framework_profile"], profile)
            self.assertEqual(result["status"], "scaffold_created")
            self.assertEqual(result["compile_status"], "not_run")
            self.assertEqual(result["simulation_status"], "not_run")
            self.assertEqual(len(result["artifacts"]), 2)
            self.assertTrue(all(len(a["sha256"]) == 64 for a in result["artifacts"]))

    def test_same_timestamp_allocates_distinct_attempts_and_preserves_previous(self):
        with mock.patch.object(creation, "datetime") as clock:
            clock.now.return_value.strftime.return_value = "fixed"
            first = Path(self.create()["platform_path"])
            (first / "sentinel").write_text("keep", encoding="utf-8")
            second = Path(self.create()["platform_path"])
        self.assertNotEqual(first.parent, second.parent)
        self.assertEqual((first / "sentinel").read_text(), "keep")

    def test_copy_and_compatibility_sync_refuse_existing_file_or_directory(self):
        source = self.templates / "gaea_demo" / "gaea_demo"
        for is_dir in (False, True):
            target = self.root / ("existing_dir" if is_dir else "existing_file")
            if is_dir:
                target.mkdir()
                sentinel = target / "sentinel"
            else:
                sentinel = target
            sentinel.write_text("keep", encoding="utf-8")
            with self.assertRaises(FileExistsError):
                creation.copy_and_rename(source, target)
            with self.assertRaises(FileExistsError):
                creation.sync_directories(target, source)
            self.assertEqual(sentinel.read_text(), "keep")

    def test_output_nested_in_source_is_rejected(self):
        source = self.templates / "gaea_demo" / "gaea_demo"
        with self.assertRaises(ValueError):
            creation.create_platform(self.templates, source / "output", "2", "unit")
        self.assertFalse((source / "output").exists())

    def test_existing_bucket_file_is_preserved(self):
        self.output.mkdir()
        bucket = self.output / "BT_PLATFORM"
        bucket.write_text("keep", encoding="utf-8")
        with self.assertRaises(FileExistsError):
            self.create()
        self.assertEqual(bucket.read_text(), "keep")

    def test_copy_failure_is_not_success_and_does_not_clean_existing_attempts(self):
        previous = Path(self.create()["platform_path"])
        output = io.StringIO()
        with mock.patch.object(creation.shutil, "copytree", side_effect=OSError("disk full")), contextlib.redirect_stdout(output):
            status = creation.main(["--template_dir", str(self.templates), "--output_root", str(self.output), "--bt_index", "1", "--p_name", "unit"])
        result = json.loads(output.getvalue())
        self.assertEqual(status, 1)
        self.assertEqual(result["status"], "failed")
        self.assertIn("disk full", result["errors"][0])
        self.assertTrue((previous / "sample.sv").exists())

    def test_reparse_point_is_rejected_without_link_privilege(self):
        real_lstat = Path.lstat
        target = self.root / "junction"
        target.mkdir()
        def fake_lstat(path, *args, **kwargs):
            if path == target:
                return mock.Mock(st_mode=0o40755, st_file_attributes=0x400)
            return real_lstat(path, *args, **kwargs)
        with mock.patch.object(Path, "lstat", fake_lstat), self.assertRaises(ValueError):
            creation._no_links(target / "child")

    def test_containment_rejects_sibling_and_root(self):
        for path in (self.root, self.root.parent / "escape"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                creation._inside(self.root, path)

    def _symlink(self, link, target, directory=False):
        try:
            link.symlink_to(target, target_is_directory=directory)
        except OSError as exc:
            self.skipTest(f"host cannot create symlinks: {exc}")

    def test_linked_output_bucket_cannot_escape_root(self):
        self.output.mkdir()
        outside = self.root / "outside"
        outside.mkdir()
        self._symlink(self.output / "BT_PLATFORM", outside, True)
        with self.assertRaises(ValueError):
            self.create()
        self.assertEqual(list(outside.iterdir()), [])

    def test_template_link_and_dangling_destination_are_rejected(self):
        source = self.templates / "gaea_demo" / "gaea_demo"
        self._symlink(source / "link.sv", self.root / "missing")
        with self.assertRaises(ValueError):
            self.create(index="2")
        self.assertFalse(self.output.exists())
        dest = self.root / "dangling"
        self._symlink(dest, self.root / "missing")
        with self.assertRaises(ValueError):
            creation.copy_and_rename(self.templates / "superbench_demo" / "superbench_demo", dest)
        self.assertTrue(dest.is_symlink())


if __name__ == "__main__":
    unittest.main()
