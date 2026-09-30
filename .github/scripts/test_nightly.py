"""Exercise release lifecycle decisions against an in-memory GitHub API."""

import copy
import hashlib
from pathlib import Path
import tempfile
import unittest

from nightly import cleanup, owned_release, prepare, publish


SHA = "a" * 40
OTHER_SHA = "b" * 40


class FakeGitHub:
    def __init__(self):
        self.head = SHA
        self.refs = {}
        self.records = {}
        self.calls = []
        self.fail_upload_tag = None
        self.next_id = 1

    def add_release(self, tag, sha=SHA, prerelease=True, draft=False, immutable=False):
        release = {
            "id": self.next_id, "tag_name": tag, "prerelease": prerelease,
            "draft": draft, "immutable": immutable, "assets": [],
            "body": f"<!-- look-food-nightly:{sha} -->" if prerelease else "Stable release",
        }
        self.next_id += 1
        self.records[tag] = release
        self.refs[tag] = sha
        return release

    def release(self, tag):
        return copy.deepcopy(self.records.get(tag))

    def releases(self):
        return copy.deepcopy(list(self.records.values()))

    def request(self, method, path, body=None, missing_ok=False):
        self.calls.append((method, path, copy.deepcopy(body)))
        if path == "/git/ref/heads/dev":
            return {"object": {"sha": self.head}}
        if method == "GET" and path.startswith("/git/ref/tags/"):
            sha = self.refs.get(path.removeprefix("/git/ref/tags/"))
            return {"object": {"sha": sha}} if sha else None
        if method == "POST" and path == "/git/refs":
            self.refs[body["ref"].removeprefix("refs/tags/")] = body["sha"]
            return {}
        if method == "PATCH" and path.startswith("/git/refs/tags/"):
            self.refs[path.removeprefix("/git/refs/tags/")] = body["sha"]
            return {}
        if method == "POST" and path == "/releases":
            release = self.add_release(body["tag_name"], body["target_commitish"])
            release.update(body)
            return copy.deepcopy(release)
        if path.startswith("/releases/assets/"):
            asset_id = int(path.rsplit("/", 1)[1])
            for release in self.records.values():
                release["assets"] = [asset for asset in release["assets"] if asset["id"] != asset_id]
            return None
        if path.startswith("/releases/"):
            release_id = int(path.rsplit("/", 1)[1])
            tag = next(tag for tag, value in self.records.items() if value["id"] == release_id)
            if method == "PATCH":
                self.records[tag].update(body)
                return copy.deepcopy(self.records[tag])
            if method == "DELETE":
                del self.records[tag]
                return None
        if method == "DELETE" and path.startswith("/git/refs/tags/"):
            self.refs.pop(path.removeprefix("/git/refs/tags/"), None)
            return None
        raise AssertionError((method, path, body))

    def upload(self, release, path, name):
        self.calls.append(("UPLOAD", release["tag_name"], name))
        if self.fail_upload_tag == release["tag_name"]:
            raise RuntimeError("Simulated upload failure")
        asset = {
            "id": self.next_id, "name": name, "state": "uploaded",
            "size": path.stat().st_size,
            "digest": "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest(),
            "browser_download_url": f"https://github.com/owner/repo/releases/download/{'untagged-draft' if release['draft'] else release['tag_name']}/{name}",
        }
        self.next_id += 1
        self.records[release["tag_name"]]["assets"].append(asset)
        return asset


class NightlyTests(unittest.TestCase):
    def setUp(self):
        self.api = FakeGitHub()
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.apk = Path(self.directory.name) / "app.apk"
        self.apk.write_bytes(b"test APK")

    def publish(self, run=9, attempt=1):
        return publish(self.api, "owner/repo", SHA, run, attempt,
                       f"0.3.0-dev.{run}.{attempt}", self.apk,
                       "https://github.com/owner/repo/actions/runs/123")

    def test_first_build_and_new_commit_are_built(self):
        self.assertEqual(prepare(self.api), {"sha": SHA, "build": "true"})
        self.api.add_release("nightly", OTHER_SHA)
        self.assertEqual(prepare(self.api)["build"], "true")

    def test_unchanged_commit_skips_unless_forced(self):
        self.api.add_release("nightly")
        self.assertEqual(prepare(self.api)["build"], "false")
        self.assertEqual(prepare(self.api, force=True)["build"], "true")

    def test_unpublished_draft_does_not_skip_build(self):
        self.api.add_release("nightly", draft=True)
        self.assertEqual(prepare(self.api)["build"], "true")

    def test_immutable_or_unmanaged_alias_is_rejected_without_mutation(self):
        for immutable, prerelease in [(True, True), (False, False)]:
            with self.subTest(immutable=immutable):
                self.api = FakeGitHub()
                self.api.add_release("nightly", immutable=immutable, prerelease=prerelease)
                with self.assertRaises(RuntimeError):
                    prepare(self.api)
                with self.assertRaises(RuntimeError):
                    self.publish()
                self.assertTrue(all(method == "GET" for method, _, _ in self.api.calls))

    def test_success_keeps_stable_latest_and_uses_exact_sha(self):
        stable = copy.deepcopy(self.api.add_release("v0.3.0", prerelease=False))
        self.assertTrue(self.publish())
        self.assertEqual(self.api.records["v0.3.0"], stable)
        self.assertEqual(self.api.refs["nightly"], SHA)
        self.assertEqual(self.api.refs["nightly-9-1"], SHA)
        self.assertIn("/releases/download/nightly-9-1/LOOK-Food-Dev-9-1.apk", self.api.records["nightly"]["body"])
        self.assertNotIn("untagged-", self.api.records["nightly"]["body"])
        self.assertEqual(prepare(self.api)["build"], "false")
        for method, path, body in self.api.calls:
            if method in ("POST", "PATCH") and path.startswith("/releases"):
                self.assertTrue(body["prerelease"])
                self.assertEqual(body["make_latest"], "false")

    def test_outdated_build_publishes_nothing(self):
        self.api.head = OTHER_SHA
        self.assertFalse(self.publish())
        self.assertEqual(self.api.records, {})
        self.assertEqual(self.api.refs, {})

    def test_archive_upload_failure_keeps_previous_nightly(self):
        before = copy.deepcopy(self.api.add_release("nightly", OTHER_SHA))
        self.api.fail_upload_tag = "nightly-9-1"
        with self.assertRaises(RuntimeError):
            self.publish()
        self.assertEqual(self.api.records["nightly"], before)
        self.assertEqual(self.api.refs["nightly"], OTHER_SHA)
        self.assertFalse(any(method == "DELETE" for method, _, _ in self.api.calls))

    def test_alias_upload_failure_keeps_previous_nightly_and_archive(self):
        before = copy.deepcopy(self.api.add_release("nightly", OTHER_SHA))
        self.api.fail_upload_tag = "nightly"
        with self.assertRaises(RuntimeError):
            self.publish()
        self.assertEqual(self.api.records["nightly"], before)
        self.assertEqual(self.api.refs["nightly"], OTHER_SHA)
        self.assertFalse(self.api.records["nightly-9-1"]["draft"])
        self.assertFalse(any(method == "DELETE" for method, _, _ in self.api.calls))

    def test_old_alias_asset_is_removed_only_after_success(self):
        previous = self.api.add_release("nightly", OTHER_SHA)
        self.api.upload(previous, self.apk, "LOOK-Food-Dev-8-1.apk")
        self.publish()
        names = [asset["name"] for asset in self.api.records["nightly"]["assets"]]
        self.assertEqual(names, ["LOOK-Food-Dev-9-1.apk"])
        upload_index = next(i for i, call in enumerate(self.api.calls) if call[:2] == ("UPLOAD", "nightly") and call[2] == names[0])
        delete_index = next(i for i, call in enumerate(self.api.calls) if call[0] == "DELETE")
        self.assertGreater(delete_index, upload_index)

    def test_cleanup_retains_eight_versions_and_protects_unrelated_releases(self):
        for run in range(1, 12):
            self.api.add_release(f"nightly-{run}-1")
        self.api.add_release("nightly-11-2")
        stable = copy.deepcopy(self.api.add_release("v1.0.0", prerelease=False))
        unrelated = self.api.add_release("nightly-0-1")
        unrelated["body"] = "An unrelated release"
        alias = copy.deepcopy(self.api.add_release("nightly"))
        cleanup(self.api, "nightly-11-2")
        managed = [tag for tag, release in self.api.records.items()
                   if tag.startswith("nightly-") and owned_release(release)]
        self.assertEqual(len(managed), 8)
        self.assertIn("nightly-11-2", managed)
        self.assertNotIn("nightly-1-1", self.api.refs)
        self.assertEqual(self.api.records["v1.0.0"], stable)
        self.assertEqual(self.api.records["nightly"], alias)
        self.assertIn("nightly-0-1", self.api.records)

    def test_rerun_uses_separate_archive_and_download(self):
        self.publish(attempt=1)
        self.publish(attempt=2)
        self.assertIn("nightly-9-1", self.api.records)
        self.assertIn("nightly-9-2", self.api.records)
        self.assertEqual(self.api.records["nightly"]["assets"][0]["name"], "LOOK-Food-Dev-9-2.apk")

    def test_wrong_archive_tag_is_not_overwritten(self):
        self.api.refs["nightly-9-1"] = OTHER_SHA
        with self.assertRaises(RuntimeError):
            self.publish()
        self.assertEqual(self.api.refs["nightly-9-1"], OTHER_SHA)
        self.assertEqual(self.api.records, {})


if __name__ == "__main__":
    unittest.main()
