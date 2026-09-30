"""Publish LOOK! Food prereleases without changing the stable Latest release."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.error
import urllib.parse
import urllib.request


ARCHIVE_TAG = re.compile(r"nightly-(\d+)-(\d+)\Z")
SHA_MARKER = re.compile(r"<!-- look-food-nightly:([0-9a-f]{40}) -->")
KEEP_VERSIONS = 8


class GitHub:
    def __init__(self, repo, token):
        self.prefix = f"/repos/{repo}"
        self.token = token

    def request(self, method, path, body=None, missing_ok=False):
        url = "https://api.github.com" + self.prefix + path
        data = None if body is None else json.dumps(body).encode()
        return self._request(method, url, data, "application/json", missing_ok)

    def _request(self, method, url, data, content_type, missing_ok=False):
        request = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "Authorization": f"Bearer {self.token}",
                "Accept": "application/vnd.github+json",
                "Content-Type": content_type,
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": "look-food-nightly",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                result = response.read()
                return json.loads(result) if result else None
        except urllib.error.HTTPError as error:
            if missing_ok and error.code == 404:
                return None
            raise RuntimeError(f"GitHub {method} failed with HTTP {error.code}") from None

    def release(self, tag):
        return self.request("GET", f"/releases/tags/{tag}", missing_ok=True)

    def releases(self):
        releases = []
        page = 1
        while True:
            batch = self.request("GET", f"/releases?per_page=100&page={page}")
            releases.extend(batch)
            if len(batch) < 100:
                return releases
            page += 1

    def upload(self, release, path, name):
        data = path.read_bytes()
        digest = "sha256:" + hashlib.sha256(data).hexdigest()
        for asset in release.get("assets", []):
            if asset["name"] == name:
                if asset.get("state") == "uploaded" and asset.get("digest") == digest:
                    return asset
                raise RuntimeError(f"Asset {name} already exists with different content")
        url = release["upload_url"].split("{", 1)[0]
        if not url.startswith("https://uploads.github.com/"):
            raise RuntimeError("Unexpected GitHub asset upload host")
        url += "?" + urllib.parse.urlencode({"name": name})
        asset = self._request("POST", url, data, "application/vnd.android.package-archive")
        if asset["state"] != "uploaded" or asset["size"] != len(data):
            raise RuntimeError("Incomplete APK upload")
        return asset


def owned_release(release):
    return bool(release.get("prerelease") and SHA_MARKER.search(release.get("body") or ""))


def source_sha(release):
    marker = SHA_MARKER.search((release or {}).get("body") or "")
    return marker.group(1) if marker else None


def prepare(api, force=False):
    sha = api.request("GET", "/git/ref/heads/dev")["object"]["sha"]
    latest = api.release("nightly")
    if latest and not owned_release(latest):
        raise RuntimeError("The nightly release is not managed by LOOK! Food")
    if latest and latest.get("immutable"):
        raise RuntimeError("The nightly release must allow updates; disable release immutability")
    build = force or not latest or latest.get("draft") or source_sha(latest) != sha
    return {"sha": sha, "build": "true" if build else "false"}


def ensure_tag(api, tag, sha, moving=False):
    ref = api.request("GET", f"/git/ref/tags/{tag}", missing_ok=True)
    if ref is None:
        api.request("POST", "/git/refs", {"ref": f"refs/tags/{tag}", "sha": sha})
    elif ref["object"]["sha"] != sha:
        if not moving:
            raise RuntimeError(f"Archive tag {tag} points at a different commit")
        api.request("PATCH", f"/git/refs/tags/{tag}", {"sha": sha, "force": True})


def ensure_release(api, tag, sha, title, body):
    release = api.release(tag)
    if release:
        if not owned_release(release) or release.get("immutable"):
            raise RuntimeError(f"Release {tag} cannot safely be updated")
        return release
    return api.request("POST", "/releases", {
        "tag_name": tag, "target_commitish": sha, "name": title,
        "body": body, "draft": True, "prerelease": True, "make_latest": "false",
    })


def archive_order(release):
    match = ARCHIVE_TAG.fullmatch(release["tag_name"])
    return tuple(map(int, match.groups()))


def cleanup(api, current_tag):
    archives = [release for release in api.releases()
                if ARCHIVE_TAG.fullmatch(release["tag_name"])
                and owned_release(release) and not release.get("draft")]
    archives.sort(key=archive_order, reverse=True)
    # Always protect the current download, even if release metadata is unexpected.
    keep = {current_tag}
    for release in archives:
        if len(keep) >= KEEP_VERSIONS:
            break
        keep.add(release["tag_name"])
    for release in archives:
        if release["tag_name"] not in keep and not release.get("immutable"):
            api.request("DELETE", f"/releases/{release['id']}")
            api.request("DELETE", f"/git/refs/tags/{release['tag_name']}", missing_ok=True)


def publish(api, repo, sha, run, attempt, version, apk, run_url):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("A full commit SHA is required")
    latest = api.release("nightly")
    if latest and (not owned_release(latest) or latest.get("immutable")):
        raise RuntimeError("The nightly release cannot safely be updated")
    if api.request("GET", "/git/ref/heads/dev")["object"]["sha"] != sha:
        print("dev advanced during the build; skipping publication")
        return False
    tag = f"nightly-{run}-{attempt}"
    name = f"LOOK-Food-Dev-{run}-{attempt}.apk"
    body = (
        f"LOOK! Food Dev **{version}** — a development prerelease.\n\n"
        f"Commit: [{sha[:7]}](https://github.com/{repo}/commit/{sha})\n\n"
        f"Built at: {datetime.now(timezone.utc).isoformat(timespec='seconds')}\n\n"
        f"[Build details and publication date]({run_url})\n\n"
        "Installs alongside LOOK! Food with separate app data.\n\n"
        f"<!-- look-food-nightly:{sha} -->\n"
    )
    ensure_tag(api, tag, sha)
    archive = ensure_release(api, tag, sha, f"LOOK! Food Dev {version}", body)
    archive_asset = api.upload(archive, apk, name)
    api.request("PATCH", f"/releases/{archive['id']}", {
        "draft": False, "prerelease": True, "make_latest": "false", "body": body,
    })
    # Upload a uniquely named asset before touching the previous working download.
    # A failed upload therefore leaves the old nightly usable.
    if latest is None:
        ensure_tag(api, "nightly", sha)
        latest = ensure_release(api, "nightly", sha, "LOOK! Food Dev — Nightly", body)
    api.upload(latest, apk, name)
    ensure_tag(api, "nightly", sha, moving=True)
    latest_body = (
        f"[Download the latest APK]({archive_asset['browser_download_url']})\n\n"
        + body + f"\n[Archived release](https://github.com/{repo}/releases/tag/{tag})\n"
    )
    api.request("PATCH", f"/releases/{latest['id']}", {
        "name": "LOOK! Food Dev — Nightly", "body": latest_body,
        "draft": False, "prerelease": True, "make_latest": "false",
    })
    # Only old assets of this managed alias are removed, after the new link is live.
    for asset in latest.get("assets", []):
        if re.fullmatch(r"LOOK-Food-Dev-\d+-\d+\.apk", asset["name"]) and asset["name"] != name:
            api.request("DELETE", f"/releases/assets/{asset['id']}")
    cleanup(api, tag)
    print(f"Published https://github.com/{repo}/releases/tag/nightly")
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["prepare", "publish"])
    parser.add_argument("--apk", type=Path)
    args = parser.parse_args()
    repo = os.environ["GITHUB_REPOSITORY"]
    api = GitHub(repo, os.environ["GH_TOKEN"])
    if args.command == "prepare":
        values = prepare(api, os.environ.get("FORCE") == "true")
        with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
            for key, value in values.items():
                output.write(f"{key}={value}\n")
        print(f"dev: {values['sha']}; build: {values['build']}")
    else:
        run = int(os.environ["GITHUB_RUN_NUMBER"])
        attempt = int(os.environ["GITHUB_RUN_ATTEMPT"])
        run_url = f"https://github.com/{repo}/actions/runs/{os.environ['GITHUB_RUN_ID']}"
        publish(api, repo, os.environ["NIGHTLY_SHA"], run, attempt,
                os.environ["NIGHTLY_VERSION"], args.apk, run_url)


if __name__ == "__main__":
    main()
