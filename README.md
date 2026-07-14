# BrHx Wake Pilot for macOS

**BrHx Wake Pilot** is a native macOS menu bar app that helps prevent idle system sleep and can optionally send a conservative presence heartbeat after the Mac has been idle. Its short menu bar name is **Wake Pilot**.

Requires macOS 13 or later.

## Features

- Menu bar status and quick on/off control.
- Prevents system idle sleep with an IOKit power assertion.
- Optional display-sleep prevention.
- Optional presence heartbeat that sends one Shift key press only after the configured idle interval.
- Presence intervals of 1, 2, 3, 4, 5, 10, or 15 minutes.
- Optional active-hours schedule, including overnight ranges such as `22:00–06:00`.
- Vietnamese (default), English, and Japanese UI.
- Launch at Login through `SMAppService`.

## Install

Install Xcode Command Line Tools or Xcode first:

```bash
xcode-select --install
```

From the BrHxWakePilot project directory, run:

```bash
chmod +x *.sh
./install.sh
```

The app is installed at:

```text
~/Applications/BrHxWakePilot.app
```

## Configure Wake Pilot

Click the Wake Pilot menu bar icon, then choose **Settings…**.

### Language

Choose the UI language in **Language**:

- Tiếng Việt — default
- English
- 日本語

The selection is saved and takes effect immediately.

### Accessibility permission

**Keep chat status active** requires Accessibility permission. When you enable it, Wake Pilot requests permission automatically. You can also grant it manually:

```text
System Settings
→ Privacy & Security
→ Accessibility
→ BrHx Wake Pilot
```

### Active-hours schedule

By default, Wake Pilot runs continuously while **Enable Wake Pilot** is on. To limit its operation, open **Settings… → Activity schedule**, enable **Only run during scheduled hours**, and set the start and end times.

- Overnight schedules are supported, for example `22:00–06:00`.
- The end time is excluded: `09:00–18:00` stops at exactly `18:00`.
- Equal start and end times mean all-day operation.
- Outside the schedule, Wake Pilot releases its power assertions and stops the presence heartbeat. It does not wake a sleeping Mac at the next start time.

## Build without installing

```bash
./build-app.sh
open dist/BrHxWakePilot.app
```

To build one app bundle for both Apple Silicon and Intel Macs:

```bash
BRHX_WAKE_PILOT_ARCHS="arm64,x86_64" ./build-app.sh
```

## GitHub Releases

Pushing a version tag that starts with `v` runs the release workflow. It tests the project, creates one universal macOS ZIP for Apple Silicon and Intel Macs, generates a SHA-256 checksum, and attaches both files to a GitHub Release.

```bash
git tag -a v1.0.0 -m "BrHx Wake Pilot 1.0.0"
git push origin v1.0.0
```

The uploaded files are named like this:

```text
BrHxWakePilot-v1.0.0-macos-universal.zip
BrHxWakePilot-v1.0.0-macos-universal.zip.sha256
```

For public repositories, users can download the ZIP from the Releases page or through the `releases/latest/download` URL. For private repositories, users must have GitHub access to download release assets.

## Open in Xcode

```bash
open Package.swift
```

## Troubleshooting

### Settings does not open

Install the latest build, quit Wake Pilot, and start it again:

```bash
./install.sh
```

The current app opens its own native Settings window and supports macOS 13 or later.

### Accessibility is enabled in System Settings, but Wake Pilot still says permission is required

Verify that the enabled item is **BrHx Wake Pilot** at `~/Applications/BrHxWakePilot.app`. If the status remains unchanged, reset the stale Accessibility record, then reopen the installed app and grant permission again:

```bash
tccutil reset Accessibility com.bravohex.wakepilot
```

Do this after installing the final build. Ad-hoc signing can make macOS treat a rebuilt app as a different code identity, even when the old Accessibility entry remains visible.

### Presence heartbeat does not keep a chat application online

Wake Pilot only sends a single Shift key press when the configured idle interval is reached. Teams, Slack, and other chat apps can apply their own presence rules, so Online status is not guaranteed. The feature does not bypass the lock screen, MDM, or organization security policies.

### Wake Pilot is inactive when a scheduled window should start

Wake Pilot cannot wake a sleeping Mac. If the Mac slept before the start time, wake it normally; Wake Pilot resumes when the app is running and the current time is inside the schedule.

### Launch at Login is waiting for approval

Open **Settings… → Startup → Open Login Items Settings…** and approve Wake Pilot in macOS System Settings. The app must be installed in `Applications` for this feature to work.

## Upgrade from StayActive

BrHx Wake Pilot uses the Bundle ID `com.bravohex.wakepilot`. On first launch, it copies existing activity settings from `com.bravohex.StayActive` when no new settings exist yet.

Launch at Login cannot be migrated automatically between two main apps with different Bundle IDs. The install script preserves `~/Applications/StayActive.app`; open the old app, disable Launch at Login, then remove the old app.

## Uninstall

First turn off **Open Wake Pilot at login** in Settings, then run:

```bash
./uninstall.sh
```

## Security and distribution

The default build is ad-hoc signed for local use. It does not pass Gatekeeper on another Mac, and rebuilding can change the app code identity. For stable Accessibility permission and safe distribution, sign with a Developer ID Application certificate:

```bash
BRHX_WAKE_PILOT_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
    ./build-app.sh
```

Before distributing the app, notarize and staple it using Apple's standard release process.
