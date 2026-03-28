# XcodeColorTheory — QA / UAT Tester Notes

## Environment

| Requirement | Minimum |
|---|---|
| macOS | 14 Sonoma |
| iOS | 17.0 |
| Xcode | 16.0 |
| Swift | 6.0 |

Open `XcodeColorTheory.xcworkspace`. Select scheme **XcodeColorTheory**, run
destination **My Mac** for macOS or any iOS 17+ simulator for iOS.

---

## Automated Tests (Cmd+U)

Select test plan **All Tests** for full coverage. Select **Albers Domain** to
run only colour science unit tests without serialization/validation noise.

| Suite | Count | What it covers |
|---|---|---|
| `ColorConversionsTests` | 12 | OKLCH ↔ sRGB round-trip, WCAG luminance, xcThemeString format |
| `AlbersAnalysisTests` | 18 | Contrast ratio/rating, vibration risk, colour temperature, fatigue |
| `PaletteValidationTests` | 14 | Built-in palette completeness, validation algebraic result, harmony generator |
| `ThemeSerializerTests` | 13 | XML structure, DVT key names, colour format, font format |

All 57 tests must pass on both macOS and iOS simulator before merge.

---

## Manual / UAT Scenarios

### 1. Sidebar — Palette Library

- [ ] Both built-in palettes (**Albers Midnight**, **Albers Ochre**) appear on first launch.
- [ ] Selecting a palette updates the editor and preview immediately.
- [ ] Built-in palettes have no Delete option in the context menu.

### 2. New Palette Sheet

- [ ] Tap **+** → sheet appears.
- [ ] Leaving Name blank disables the Create button.
- [ ] All 6 harmony schemes are available in the picker.
- [ ] Base hue slider (0–360°) moves smoothly; the degree label updates.
- [ ] Created palette appears in the sidebar and is auto-selected.

### 3. Palette Editor

- [ ] All 15 colour roles are shown across 4 sections (Canvas, Text, Keywords & Declarations, Literals & Attributes).
- [ ] Tapping a swatch opens the system ColorPicker.
- [ ] Changing a colour updates the preview pane instantly (no lag).
- [ ] WCAG contrast badge shows AA / AAA / FAIL / UI for each foreground role.
- [ ] **Save** is disabled for built-in palettes.
- [ ] **Save** is enabled for custom palettes; saving persists across app restarts.

### 4. Theme Preview

- [ ] The fake Swift code snippet renders using the selected palette colours.
- [ ] Background, keywords, types, strings, comments each show the correct role colour.
- [ ] Live update: editing a colour in the editor is reflected in the preview without navigating away.
- [ ] No clipped text or overlapping tokens at default window size (1100 × 700).

### 5. Albers Analysis View

- [ ] Contrast ratio table shows all 15 roles with numeric ratio and badge.
- [ ] Vibration risk matrix shows role pairs with risk > 0.3 highlighted.
- [ ] Fatigue summary flags any role with risk > 0.7.
- [ ] PaletteValidation banner shows: green for `.valid`, amber for `.warnings`, red for `.errors`.

### 6. Export — macOS only

- [ ] **Install into Xcode** writes `<PaletteName>.xccolortheme` to
  `~/Library/Developer/Xcode/UserData/FontAndColorThemes/`.
  Open Xcode → Settings → Themes to verify the theme appears.
- [ ] **Save to Downloads** writes the file to `~/Downloads/`.
- [ ] **Copy XML to Clipboard** shows "Copied!" feedback for ~2 s,
  then resets. Paste into a text editor and verify valid XML plist structure.
- [ ] All three exports respect the selected font (JetBrains Mono, Fira Code,
  Cascadia Code, IBM Plex Mono, Victor Mono).
- [ ] Palette name containing `&`, `<`, or `>` produces valid XML (entities escaped).
- [ ] Palette name containing `/` or `..` does **not** write outside the target directory.

### 7. Export — iOS

- [ ] **Install into Xcode** button is not shown on iOS.
- [ ] **Save to Downloads** and **Copy XML** are present and functional.

### 8. Colour Explorer Playground

Open `ColorExplorer.playground` in the workspace navigator. Run the playground
(Shift+Cmd+Return). Verify:

- [ ] No compile errors.
- [ ] All `print()` lines produce expected output in the console:
  - Round-trip L delta < 0.001
  - Contrast ratio between violet and navy ≥ 4.5
  - albersFavorite hues array is non-empty
  - XML output begins with `<?xml version="1.0"`

---

## Known Limitations

- The app is a Swift Package opened via a workspace; there is no
  `Info.plist` or app bundle identifier. It cannot be submitted to the
  App Store in this configuration — that requires an Xcode project wrapper.
- Xcode theme installation is macOS only; `.xccolortheme` files have no
  equivalent on iOS.
- Colour picker on iOS uses the system sheet which does not expose OKLCH
  directly; values are converted on the way in via `rgbToOKLCH`.

---

## Regression Checklist (before every merge to `main`)

- [ ] `swift test` passes locally (or SessionStart hook reports green)
- [ ] No new warnings in the Issue navigator
- [ ] Build succeeds for **My Mac** and **iPhone 16 Pro** simulator
- [ ] Playground runs without errors
- [ ] At least one export path verified manually on macOS
