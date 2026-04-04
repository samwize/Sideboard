![Sideboard](/Resources/hero-banner.jpg)

A macOS menu bar app that syncs your clipboard with the iOS Simulator. Fixes the broken pasteboard sync in Xcode 26.4.

Maybe more, in future releases.

## Install

Download the latest DMG from [Releases](https://github.com/samwize/Sideboard/releases), open it, and drag Sideboard to Applications.

Every release is open source, [built by GitHub Actions](https://github.com/samwize/Sideboard/actions) from the tagged commit, signed and notarized by Apple. Verify with `shasum -a 256 ~/Downloads/Sideboard.dmg` and compare against the SHA on the [release page](https://github.com/samwize/Sideboard/releases).

Or build from source: `make install`

## How it works

Sideboard polls `NSPasteboard.general.changeCount` every 1 second. When you copy something on your Mac, it syncs to the booted Simulator via `xcrun simctl pbcopy`. It also syncs the other direction: copies made inside the Simulator appear on your Mac clipboard.

The menu bar icon shows `clipboard.fill` when a Simulator is booted and syncing, `clipboard` otherwise.

## Requirements

- macOS 26+
- Xcode command line tools (`xcrun simctl` must be available)

## Releasing

Push a version tag and GitHub Actions handles the rest: build, sign, notarize, DMG, and release.

```bash
git tag v1.1
git push --tags
```

Or release manually:

```bash
make release
```

### CI setup

Add these GitHub repo secrets:

| Secret | Description |
|---|---|
| `DEVELOPER_ID_CERT_P12` | Base64-encoded .p12 of the Developer ID Application certificate |
| `DEVELOPER_ID_CERT_PASSWORD` | Password for the .p12 (if empty, use a single space) |
| `APPLE_ID` | Apple ID email |
| `APPLE_TEAM_ID` | Apple Developer team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | Apple account App-Specific Passwords |

### Local setup

```bash
xcrun notarytool store-credentials "sideboard-notary" \
  --apple-id YOUR_APPLE_ID \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

## License

[MIT](LICENSE)
