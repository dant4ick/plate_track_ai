# LOOK! Food Android builds

The download badge and `/releases/latest` link in the main README always point
to the stable channel. Stable APK and AAB releases still run only on `v*` tags.

## Nightly channel

[Download the latest LOOK! Food Dev build](https://github.com/dant4ick/plate_track_ai/releases/tag/nightly).

The workflow runs daily at **03:17 Moscow time** (00:17 UTC), and only builds
if the current `dev` commit has not already been successfully published.
It does not run on push. GitHub may delay scheduled runs and disables them in
public repositories after 60 days without activity.

For a manual build, open **Actions → LOOK! Food Android Nightly → Run workflow**.
Select `main`; the workflow always builds the exact `dev` commit resolved at
startup. Enable **force** to rebuild an already published commit.
The schedule requires the workflow to exist on the default branch (`main`).

Each successful build creates a prerelease tagged `nightly-<run>-<attempt>`.
The permanent `nightly` prerelease links to and contains the latest APK.
Eight archived versions are retained: the latest and seven previous builds.
Stable releases are never marked, modified, or deleted by this workflow.
A failed build leaves the previous nightly available. A build of an outdated
`dev` commit is not published; the next scheduled or manual run picks up changes.

## Repository configuration

The existing `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, and `KEY_PASSWORD` secrets
sign both channels with the same persistent release keystore (`upload` alias).
Add **NIGHTLY_RELEASE_TOKEN** as a repository Actions secret. Use a fine-grained
GitHub token scoped only to this repository with **Contents: Read and write**
and **Workflows: Read and write**. The second permission allows publishing
commits whose workflows differ from `main`. Renew the secret before its token
expires; the workflow reports missing or invalid credentials as a failed run.

Release immutability must remain disabled for the moving `nightly` release.
The repository was checked before setup; existing releases are mutable.

## Local Android builds

On Bazzite, enter the project container first:

```bash
distrobox enter plate-dev
cd /var/home/dant4ick/plate_track_ai
git lfs pull
flutter run --flavor dev
flutter build apk --release --flavor dev
flutter build apk --release --flavor prod
flutter build appbundle --release --flavor prod
```

`prod` is the default flavor. The production app keeps its existing application
ID and is displayed as **LOOK! Food**. The dev flavor is **LOOK! Food Dev** with
application ID `io.github.dant4ick.plate_track_ai.dev`; it installs alongside
production and uses separate app data. Release builds require the signing files.

Nightly versions use `<project-version>-dev.<run>.<attempt>` and an Android
versionCode of `run * 100 + attempt`. The source version is not modified.
Newer nightlies can update previous nightlies without losing their data.
An older APK normally requires uninstalling the newer app before installation.
The first signed nightly also requires uninstalling an existing debug-signed
`.dev` app; uninstalling removes that app's local data.
