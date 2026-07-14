# GitHub Release Guide

This guide describes two release paths for Wake Pilot:

1. **Initial release path**: build a universal ZIP and publish it as a GitHub Release asset.
2. **Official distribution path**: sign with a Developer ID certificate, notarize with Apple, staple the result, and then publish the release asset.

The current workflow is [`.github/workflows/release.yml`](../.github/workflows/release.yml).

## 1. Initial Release: GitHub Release ZIP

This path is already configured. Pushing a tag that starts with `v` triggers the workflow.

```bash
git tag -a v0.1.0 -m "Wake Pilot 0.1.0"
git push origin v0.1.0
```

The workflow performs these steps:

1. Runs unit tests with strict Swift concurrency checks.
2. Builds a universal app bundle for Apple Silicon and Intel Macs.
3. Creates a ZIP archive and a SHA-256 checksum file.
4. Creates or updates the matching GitHub Release.

For tag `v0.1.0`, the release assets are:

```text
BrHxWakePilot-v0.1.0-macos-universal.zip
BrHxWakePilot-v0.1.0-macos-universal.zip.sha256
```

Users can download the ZIP from the repository's **Releases** page. In a public repository, the latest asset can also be linked through:

```text
https://github.com/<owner>/<repository>/releases/latest/download/BrHxWakePilot-v0.1.0-macos-universal.zip
```

### Important limitation

The initial workflow uses ad-hoc signing. The ZIP is suitable for testing and direct internal distribution, but macOS Gatekeeper can warn users when they open it. Rebuilding an ad-hoc app can also change its code identity, which may require Accessibility permission to be granted again.

## 2. Official Release: Developer ID Signing and Notarization

Use this path before distributing Wake Pilot broadly to external users.

### Prerequisites

- An active Apple Developer Program membership.
- A **Developer ID Application** certificate exported as a `.p12` file.
- An App Store Connect API key that can submit notarization requests.
- GitHub Actions permission to create releases (`contents: write` is already requested by the workflow).

Apple's current notarization documentation is available at [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

### GitHub Secrets

Create these repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `DEVELOPER_ID_CERTIFICATE_BASE64` | Base64-encoded Developer ID `.p12` certificate. |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` file. |
| `NOTARY_KEY_ID` | App Store Connect API key ID. |
| `NOTARY_ISSUER_ID` | App Store Connect issuer ID. |
| `NOTARY_PRIVATE_KEY_BASE64` | Base64-encoded contents of the API key `.p8` file. |

The signing identity itself is not secret. Store it as a repository variable, for example:

```text
SIGNING_IDENTITY=Developer ID Application: Your Organization (TEAMID)
```

On macOS, prepare the two Base64 values without committing the source files:

```bash
base64 -i "Developer ID Application.p12" | pbcopy
base64 -i "AuthKey_ABC123XYZ.p8" | pbcopy
```

### Required workflow changes

For the official path, extend `release.yml` with these stages:

1. Create a temporary keychain on the GitHub runner.
2. Decode and import the Developer ID certificate into that keychain.
3. Build using `BRHX_WAKE_PILOT_SIGNING_IDENTITY="${SIGNING_IDENTITY}"`.
4. Verify the signed app with `codesign --verify --strict --verbose=2`.
5. Create a ZIP of the signed app and submit it with `xcrun notarytool submit --wait` using the API key.
6. Staple the accepted notarization ticket to the app using `xcrun stapler staple`.
7. Recreate the ZIP after stapling, generate its SHA-256 file, and publish both assets.

Do not modify the app after notarization. Any change invalidates the signature and requires a new notarization submission.

## Versioning Strategy

Wake Pilot uses two version values in [`Resources/Info.plist`](../Resources/Info.plist):

| Key | Purpose | Initial value |
| --- | --- | --- |
| `CFBundleShortVersionString` | Public marketing version shown to users. | `0.1.0` |
| `CFBundleVersion` | Internal build number. | `1` |

### Recommended policy

Keep the public version deliberate and semantic:

```text
0.1.0  First preview release
0.1.1  Bug-fix release
0.2.0  Backward-compatible feature release
1.0.0  First stable public release
```

Match a public release with its Git tag, for example `v0.1.0`.

### Can the build number be increased automatically?

Yes. The recommended automation is to increase only `CFBundleVersion` for every CI build, using `github.run_number` or another monotonically increasing CI number. This keeps the user-facing version stable while making each uploaded app uniquely identifiable.

The current build script copies the build number from `Resources/Info.plist`, so automatic build-number injection is **not enabled yet**. A future change can add an optional variable such as:

```bash
BRHX_WAKE_PILOT_BUILD_NUMBER="${GITHUB_RUN_NUMBER}" ./build-app.sh
```

The script would write that value only into the generated app bundle's `Info.plist`; it would not modify the committed source plist. This is the preferred behavior for CI releases.
