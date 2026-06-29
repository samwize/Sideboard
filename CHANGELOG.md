# Changelog

All notable changes to Sideboard are documented here. This project adheres to [Semantic Versioning](https://semver.org).

## [1.4.0] - 2026-06-29

### Removed
- iOS Simulator clipboard sync (#32). Xcode fixed the underlying pasteboard bug, so the workaround is no longer needed; Sideboard is now a focused clipboard manager. The clipboard polling, history, and replacement rules continue to work via a standalone monitor.

## [1.3.0] - 2026-06-28

### Added
- Clipboard replacement rules: copied text is cleaned automatically by configurable rules, managed in Settings.
- "Tracking params" rule (enabled by default) strips `utm_*`, `fbclid`, `gclid`, and other tracking parameters from copied URLs.
- Bundled rules you can toggle on: share-token stripping, Amazon link shortening, straight quotes, invisible-character and non-breaking-space cleanup, and whitespace trimming.
- Create your own rules (tracking-parameter or find/replace with optional regex), and duplicate any rule to tweak a variant.
- When a rule fires, both the original and the cleaned text are kept in history; the cleaned entry is marked with an icon listing which rules applied.
- Editing rules re-applies them to the most recently copied item.

## [1.2.5] - 2026-04-15

### Fixed
- Copy unstashed entries back to the pasteboard (#30).
- Prevent a crash when clearing history (#28).

## [1.2.4] - 2026-04-11

### Added
- Persistent Sideboard window (#25).
- Stash tab for keeping clipboard items (#23).

## [1.2.3] - 2026-04-06

### Added
- Sync clipboard across all booted simulators (#21).

### Fixed
- Preserve Unicode clipboard text through `simctl` sync (#18).

## [1.2.2] - 2026-04-04

### Fixed
- Use `sed` instead of `agvtool` for CI version bumps (#17).
