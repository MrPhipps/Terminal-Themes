# OKLCH Color Picker

A macOS color picker bundle (`OKLCH.colorPicker`) that adds an **OKLCH** tab to the
system color panel (`NSColorPanel`), next to Wheel, Sliders, Palettes, Image and Pencils.
It uses the same `OKLCHSliders` view as the Theme Theory palette editor, and the same
OKLCH ↔ sRGB conversion from the `ThemeTheory` domain package.

## Build

1. Open `ThemeTheory.xcworkspace`.
2. Select the **OKLCHColorPicker** scheme, destination **My Mac**.
3. Build (⌘B). Product: `OKLCH.colorPicker` (Product ▸ Show Build Folder in Finder ▸ `Products/Debug`).

## Install

```sh
mkdir -p ~/Library/ColorPickers
cp -R "<build folder>/Products/Debug/OKLCH.colorPicker" ~/Library/ColorPickers/
```

Quit and relaunch any app that shows the color panel. The panel loads pickers once per
app launch, so an already-running app won't show the new tab.

To uninstall, delete `~/Library/ColorPickers/OKLCH.colorPicker` and relaunch the app.

## Which apps will load it

The bundle loads **into the host app's process**, so the host's code-signing rules apply:

- Apps **without** library validation (most non-sandboxed third-party apps, TextEdit,
  and Theme Theory itself, which is signed by the same team) load it.
- Apps with hardened runtime **and** library validation only load plug-ins signed by
  Apple or by their own team. Those apps silently skip the bundle; the tab won't appear.
  Check one with `codesign -d --entitlements - /Applications/Foo.app` (look for
  `com.apple.security.cs.disable-library-validation`).

## How it works

| Panel → picker | Picker → panel |
| --- | --- |
| `setColor(_:)` whenever the panel's color changes, from any tab or the host app | Sliders call `push(_:)`, which assigns `colorPanel.color`; the panel forwards it to the host app |
| `provideNewView(_:)` when the user picks the OKLCH tab | |

- The panel echoes our own color back through `setColor(_:)`. The `isPushingColor` guard
  ignores that echo, so gamut clamping doesn't move the sliders mid-drag.
- Greys have no hue, so when chroma reaches 0 the previous hue is kept and H doesn't jump.
- Alpha comes from the panel's own opacity slider and is passed through unchanged.
- The target uses Swift 5 language mode because AppKit's actor annotations on
  `NSColorPicker` differ between SDKs. The panel always calls into the picker on the main
  thread, and the SwiftUI hosting view is created inside `MainActor.assumeIsolated`.
