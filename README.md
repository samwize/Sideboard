![Sideboard](/Resources/hero-banner.jpg)

A macOS menu bar app that syncs your clipboard with the iOS Simulator. Fixes the broken pasteboard sync in Xcode 26.4.

Maybe more, in future releases.

## Install

Download the latest DMG from [Releases](https://github.com/samwize/Sideboard/releases), open it, and drag Sideboard to Applications.

Or build from source:

```bash
make install
```

## How it works

Sideboard polls `NSPasteboard.general.changeCount` every 1 second. When you copy something on your Mac, it syncs to the booted Simulator via `xcrun simctl pbcopy`. It also syncs the other direction: copies made inside the Simulator appear on your Mac clipboard.

The menu bar icon shows `clipboard.fill` when a Simulator is booted and syncing, `clipboard` otherwise.

## Requirements

- macOS 26+
- Xcode command line tools (`xcrun simctl` must be available)

## Releasing

Every release must be signed and notarized by Apple. The Makefile automates this.

```bash
make release
```

This runs the full pipeline: build, sign (Developer ID), notarize (Apple), staple, create DMG, and upload to GitHub Releases with auto-generated notes.

Individual steps if needed:

| Command | What it does |
|---|---|
| `make build` | Compile release binary |
| `make sign` | Code sign with Developer ID |
| `make notarize` | Submit to Apple, wait for approval, staple ticket |
| `make dmg` | Create DMG (includes sign + notarize) |
| `make release` | All of the above + GitHub release |

Before your first release, set up notarization credentials:

```bash
xcrun notarytool store-credentials "sideboard-notary" \
  --apple-id YOUR_APPLE_ID \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

The app-specific password is generated at [appleid.apple.com](https://appleid.apple.com) > Sign-In and Security > App-Specific Passwords.

## License

[MIT](LICENSE)
