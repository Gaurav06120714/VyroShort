# Changelog

All notable changes to VyroShort are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [1.0.0] — 2026-07-03

First production release.

### Capture
- Region (`⌘⇧Q`), Window (`⌘⇧2`), Full Screen (`⌘⇧1`) via ScreenCaptureKit.
- Dimmed crosshair overlay with live pixel dimensions and drag-to-select.
- Delayed capture (3 / 5 / 10 s). Auto-copy to clipboard on every capture.
- VyroShort's own windows are excluded from captures.

### Editor
- Tools: arrow, rectangle, ellipse, line, highlight, text, blur, crop.
- Select tool with drag-to-move; dashed selection highlight.
- Undo / redo (`⌘Z` / `⌘⇧Z`), clear, delete (`⌫`), non-destructive crop.
- Copy (`⌘C`) flattens, copies, and auto-closes the editor.
- Export PNG / JPG / PDF / TIFF and macOS share sheet.

### Organize
- Floating Screenshot Stack (persistent via SwiftData, 100-item cap).
- Rename, favorite, multi-select, delete, search; translucent frosted panel.

### Productivity
- OCR (Apple Vision) with link / email / phone detection.
- Clipboard history (last 50 copies), categorized Settings, global hotkeys.
- Dark / Light / System appearance, glassmorphism design.
- Launch at login (ServiceManagement).

### Engineering
- Swift 6 strict concurrency, MVVM + feature modules, XCTest suite.
- Stable self-signed code-signing identity (permission persists across rebuilds).
- First-launch "Move to Applications" flow; GitHub Actions CI + release pipeline.
