# GitHub Release Guide

Pushing a version tag that starts with `v` runs the [release workflow](../.github/workflows/release.yml). It creates a Developer ID-signed, notarized, and stapled universal app before publishing the matching GitHub Release.

## Create a Release

```bash
git tag -a v0.1.0 -m "Wake Pilot 0.1.0"
git push origin v0.1.0
```

The workflow performs these steps:

1. Runs unit tests with strict Swift concurrency checks.
2. Builds a universal app bundle for Apple Silicon and Intel Macs.
3. Imports the Developer ID certificate into a temporary keychain and signs the app with hardened runtime and a secure timestamp.
4. Sends a ZIP to the Apple notary service, then staples and validates the notarization ticket.
5. Creates the final ZIP and SHA-256 checksum after stapling.
6. Creates or updates the matching GitHub Release.

For tag `v0.1.0`, the release assets are:

```text
WakePilot-v0.1.0-macos-universal.zip
WakePilot-v0.1.0-macos-universal.zip.sha256
```

Users can download the ZIP from the repository's **Releases** page. In a public repository, the latest asset can also be linked through:

```text
https://github.com/<owner>/<repository>/releases/latest/download/WakePilot-v0.1.0-macos-universal.zip
```

## Required Setup

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

The workflow reads the Developer ID Application identity directly from the imported `.p12`; no additional GitHub variable is required.

On macOS, prepare the two Base64 values without committing the source files:

```bash
base64 -i "Developer ID Application.p12" | pbcopy
base64 -i "AuthKey_ABC123XYZ.p8" | pbcopy
```

The workflow deletes its temporary signing keychain after the release job completes. Do not modify the app after notarization; any change invalidates the signature and requires a new notarization submission.

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
WAKE_PILOT_BUILD_NUMBER="${GITHUB_RUN_NUMBER}" ./build-app.sh
```

The script would write that value only into the generated app bundle's `Info.plist`; it would not modify the committed source plist. This is the preferred behavior for CI releases.
