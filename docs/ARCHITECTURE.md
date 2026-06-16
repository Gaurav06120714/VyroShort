# VyroShort — Architecture

VyroShort is a native SwiftUI macOS app using an **MVVM + feature-module** structure.
It runs as a menu-bar (`LSUIElement`) accessory app and only switches to a regular Dock
app while an editor or OCR window is open.

## Layers

```
┌──────────────────────────────────────────────────────────┐
│ App        VyroShortApp · AppDelegate · AppCoordinator     │
│            MenuBarContent                                   │
├──────────────────────────────────────────────────────────┤
│ Features   Capture · Editor · OCR · Stack · Clipboard      │
│            Sharing · Settings · Shortcuts                   │
├──────────────────────────────────────────────────────────┤
│ Platform   ScreenCaptureKit · Vision · SwiftData ·         │
│            CoreImage · AppKit (panels, hotkeys, pasteboard) │
├──────────────────────────────────────────────────────────┤
│ Design     UI/Theme (DesignTokens, GlassBackground) +      │
│            shared components                                │
└──────────────────────────────────────────────────────────┘
```

## Key types

| Type | Responsibility |
|------|----------------|
| `AppCoordinator` | `@MainActor` hub owning all modules; routes capture/stack/OCR intents. |
| `ScreenCaptureManager` | ScreenCaptureKit wrapper (`SCScreenshotManager`) for full/region/window. |
| `RegionSelectionOverlay` | Borderless dimmed overlay; returns a global rect or window-pick point. |
| `CaptureController` | Capture flow orchestration + delayed capture + permission hinting. |
| `ScreenshotStack` | `ObservableObject` over SwiftData; add/rename/favorite/delete/search, 100-cap. |
| `CaptureStorage` | On-disk PNG + thumbnail storage; owns the `ModelContainer`. |
| `AnnotationEngine` | Base image + `[Annotation]` + undo/redo/crop; flattens via `ImageRenderer`. |
| `CanvasContent` / `CanvasView` | Pure renderer (also used for export) + interactive drawing surface. |
| `OCRManager` | Vision recognition + URL/email/phone detection. |
| `ClipboardHistory` | Last 50 copied captures. |
| `HotKeyManager` | Carbon global hotkeys (⌘⇧2/3/4). |

## Data flow — a capture

```
hotkey / menu
   → AppCoordinator.captureRegion()
   → CaptureController.region()
   → RegionSelectionOverlay (user selects rect)
   → ScreenCaptureManager.captureRegion(rect)   [ScreenCaptureKit]
   → AppCoordinator.ingest(image)
        ├─ ClipboardManager.copy (→ ClipboardHistory)
        ├─ ScreenshotStack.add (→ CaptureStorage + SwiftData)
        └─ EditorWindowController.present
```

## Rendering & export
Annotations are stored in **image-pixel space**. `CanvasContent` is a single SwiftUI
renderer used both on screen (scaled to fit) and for export (`ImageRenderer` at scale 1),
guaranteeing the exported PNG matches what the user sees. Blur uses a pre-computed
`CIGaussianBlur` copy of the base image clipped to blur rects. Crop is non-destructive —
stored as a rect and applied only at flatten time.

## Concurrency
Swift 6 strict concurrency. UI/coordination types are `@MainActor`. The Carbon hotkey
C callback hops back to the main actor via `MainActor.assumeIsolated`. OCR runs on Vision's
own queue and resumes through a continuation.

## Persistence
- **SwiftData** (`ScreenshotItem`, `Tag`) at
  `~/Library/Application Support/VyroShort/VyroShort.store`.
- Full-res PNGs in `…/Captures`, thumbnails in `…/Thumbnails`.

## Permissions & entitlements
App sandbox is **disabled** in development to allow full-display capture; Screen Recording
(TCC) is requested at first capture. Global hotkeys need no extra entitlement.

## Project generation
The Xcode project is generated from `project.yml` with XcodeGen and is git-ignored —
run `xcodegen generate` after pulling or adding files.
