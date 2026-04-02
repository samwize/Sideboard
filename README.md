# SideBoard

**Always at your side.**

A developer clipboard companion. Currently a lightweight script that fixes the broken Xcode 26.4 Mac-to-Simulator pasteboard sync.

## Quick Start

```bash
swift ~/Workspace/Sideboard/sideboard.swift
```

That's it. The script will:

1. Watch your Mac clipboard for changes (every 1 second)
2. Print each change with a timestamp (truncated to 100 chars)
3. Auto-sync to any booted iOS Simulator

Copy something on your Mac, and it'll appear in the Simulator's pasteboard. Cmd+V in the Simulator just works.

## Stop

Press `Ctrl+C`.

## Requirements

- macOS with Xcode command line tools installed (`xcrun simctl` must be available)
- A booted iOS Simulator (if no simulator is running, the sync silently skips)

## What it looks like

```
SideBoard - Always at your side
Watching clipboard for changes (polling every 1s)...
Syncing to booted iOS Simulator when changes detected.
Press Ctrl+C to stop.

[14:32:01] {"user": "test", "token": "abc123"}
[14:32:15] https://example.com/deep-link?id=42
[14:33:02] func viewDidLoad() {\n    super.viewDidLoad()\n    let manager = ClipboardManager()\n    manager...
```
