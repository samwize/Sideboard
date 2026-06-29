![Sideboard](/Resources/hero-banner.jpg)

A macOS menu bar clipboard manager. It keeps a history of what you copy, lets you stash entries for later, and cleans copied text with configurable replacement rules — stripping tracking parameters from URLs, straightening smart quotes, trimming whitespace, and anything else you set up.

> Sideboard started life as a workaround for the [broken pasteboard sync in Xcode 26.4](https://samwize.com/2026/03/30/xcode-simulator-paste-broken-workaround/). Xcode has since fixed that bug, so the Simulator sync was removed; Sideboard is now a focused clipboard manager.

## Install

Download the latest DMG from [Releases](https://github.com/samwize/Sideboard/releases), open it, and drag Sideboard to Applications.

Every release is open source, [built by GitHub Actions](https://github.com/samwize/Sideboard/actions) from the tagged commit, signed and notarized by Apple. Verify with `shasum -a 256 ~/Downloads/Sideboard.dmg` and compare against the SHA on the [release page](https://github.com/samwize/Sideboard/releases).

Or build from source with `make install`

## How it works

Sideboard polls the Mac pasteboard **every 1 second** and keeps a history of what you copy. Replacement rules run on each copy — for example stripping `utm_*`, `fbclid`, and `gclid` tracking parameters from URLs — and you can add, edit, or duplicate your own rules in Settings. When a rule changes the copied text, both the original and the cleaned version are kept in history.

## Requirements

- macOS 26+

## Release Workflow

In GitHub Actions > Release (one-click) > Run workflow > Set the version number.

Or trigger the same workflow from the CLI:

```bash
gh workflow run .github/workflows/release-dispatch.yml -f version=1.2.4
```

This will push a version tag and GitHub Actions handles the rest: build, sign, notarize, DMG, and release.

Or release manually with `make release`.

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
