<div align="center">

# VyroShort

**The fastest screenshot workflow on macOS.**
Capture → Annotate → Organize → Copy → Share — in under 3 seconds.

Native SwiftUI · ScreenCaptureKit · Vision OCR · SwiftData

</div>

---

VyroShort is a modern, native macOS screenshot, annotation, OCR and sharing tool for
developers, designers, founders, students, QA testers and power users. It is built to
outpace CleanShot X, Shottr and Snagit on raw workflow speed while introducing a
flagship **Screenshot Stack** for managing recent captures without ever leaving your flow.

## Features

### Capture
- **Region** — `⌘⇧Q` — dimmed freeze overlay, crosshair, live pixel dimensions, drag to select.
- **Window** — `⌘⇧2` — click any on-screen window (shadows preserved).
- **Full Screen** — `⌘⇧1` — display under the cursor, Retina resolution, multi-monitor.

> macOS reserves `⌘⇧3`/`⌘⇧4`/`⌘⇧5` for its own screenshots, so VyroShort uses `⌘⇧Q`/`⌘⇧2`/`⌘⇧1` to stay conflict-free.
- **Delayed capture** — none / 3s / 5s / 10s, set in Settings.
- Every capture is auto-copied to the clipboard and added to the stack.

### Screenshot Stack
- Floating, always-on-top panel in the bottom-left.
- Thumbnail cards, multi-select, favorite, rename, delete, search.
- Persists between launches (SwiftData), capped at 100 items.

### Floating Editor
- Tools: **arrow, rectangle, ellipse, line, highlight, text, blur, crop**.
- Live color palette, adjustable thickness, opacity.
- Undo / redo / clear, non-destructive crop.
- Export **PNG · JPG · PDF · TIFF**, copy, save, or share via the macOS share sheet.

### OCR
- Apple **Vision** text recognition with automatic detection of links, emails and phone numbers.
- One-click copy of all text or any detected item.

### Productivity
- **Clipboard history** — last 50 copies, click to re-copy.
- Categorized **Settings**: General · Capture · Shortcuts · Clipboard · Appearance.
- Dark / Light / System appearance, glassmorphism design.

## Requirements
- macOS 15+
- Xcode 26+ / Swift 6
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & Run
```bash
brew install xcodegen          # once
xcodegen generate              # produces VyroShort.xcodeproj
open VyroShort.xcodeproj        # then ⌘R in Xcode

# …or from the command line:
xcodebuild -project VyroShort.xcodeproj -scheme VyroShort \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project VyroShort.xcodeproj -scheme VyroShort \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```

VyroShort runs as a **menu-bar app** (no Dock icon). On first capture, macOS will ask
for **Screen Recording** permission — grant it in *System Settings → Privacy & Security →
Screen Recording*, then relaunch.

## Architecture
MVVM, feature-modular. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

```
Sources/
  App/        App entry, AppDelegate, AppCoordinator, menu bar
  Capture/    ScreenCaptureKit engine + selection overlay
  Editor/     Annotation model + engine + editor window
  OCR/        Vision recognition + result UI
  Clipboard/  Pasteboard + history
  Stack/      Screenshot stack store + floating panel
  Sharing/    Export + share sheet
  Storage/    SwiftData models + on-disk capture storage
  Settings/   Preferences + AppSettings
  Shortcuts/  Global hotkeys (Carbon)
  UI/         Theme/design tokens + shared views
Tests/        XCTest suite
```

## Roadmap
Scrolling/stitched capture · pixelate / callout / measurement tools · Pin-to-Desktop ·
AI features (screenshot understanding, bug-report generator, smart annotations, OCR
cleanup) · deep Slack/Discord/Notion sharing · tags & advanced search · cloud sync.

## License
Copyright © 2026 Gaurav. All rights reserved.
