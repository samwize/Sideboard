# Sideboard

![Sideboard App Icon](/Resources/AppIcon.png)

A macOS menu bar app that syncs your clipboard with the iOS Simulator. Fixes the broken pasteboard sync in Xcode 26.4.

Maybe more, in future releases.

_Always at your side._

## Install

```bash
make install
```

This builds a release binary, bundles it into `Sideboard.app`, and copies it to `~/Applications/`.

## Run (without installing)

```bash
make run
```

## Uninstall

```bash
make uninstall
```

## How it works

Sideboard polls `NSPasteboard.general.changeCount` every 1 second. When you copy something on your Mac, it syncs to the booted Simulator via `xcrun simctl pbcopy`. It also syncs the other direction: copies made inside the Simulator appear on your Mac clipboard.

The menu bar icon shows `clipboard.fill` when a Simulator is booted and syncing, `clipboard` otherwise.

## Requirements

- macOS 26+
- Xcode command line tools (`xcrun simctl` must be available)
