# Release policy

- Keep the app at version `1.0.0+1` until the user explicitly requests a new version.
- Do not increment the version or create a higher release tag without that request.
- Never commit Android signing keys, passwords, or `android/key.properties`.

# Build and publishing policy

- Build release APKs and web release packages on GitHub Actions, not on the user's PC, unless the user explicitly asks for a local build.
- Local source edits, analysis, and tests are allowed; a missing local Android SDK is not a blocker for an Actions release.
- A commit on `main` containing `[release]` requests the existing release workflow to build and publish the version from `pubspec.yaml` after checks pass.
- When the user asks to push themselves, prepare the commit and leave GitHub Desktop at `Push origin`; do not push it for them.
