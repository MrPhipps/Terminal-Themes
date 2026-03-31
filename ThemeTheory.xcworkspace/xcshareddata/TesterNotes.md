# Theme Theory — QA / UAT Tester Notes

## Environment

| Requirement | Minimum |
|---|---|
| macOS | 26.0 |
| iOS | 17.0 |
| Xcode | 26.4 |
| Swift | 6.0 |

Open **`ThemeTheory.xcworkspace`**. Select scheme **ThemeTheory**.

- **macOS native**: destination **My Mac**
- **iOS**: any iOS 17+ simulator or a connected device

> **DEV — first checkout on this branch**
> If you have DerivedData from a previous branch (the project was formerly
> `XcodeColorTheory.xcodeproj`), clear it before opening:
> ```
> rm -rf ~/Library/Developer/Xcode/DerivedData/XcodeColorTheory-*
> ```
> Then open `ThemeTheory.xcworkspace` directly — do not use Xcode recent files.

---

## Automated Tests (⌘U)

Select test plan **All Tests** for full coverage.

| Suite | Count | What it covers |
|---|---|---|
| `ColorConversionsTests` | 12 | OKLCH ↔ sRGB round-trip, WCAG luminance, xcThemeString format |
| `AlbersAnalysisTests` | 18 | Contrast ratio/rating, vibration risk, colour temperature, fatigue |
| `PaletteValidationTests` | 14 | Built-in palette completeness, validation algebraic result, harmony generator |
| `ThemeSerializerTests` | 13 | XML structure, DVT key names, colour format, font format |

All 57 tests must pass on **both** macOS and iOS simulator before merge.

> **DEV — command-line domain tests**
> ```
> cd XcodeColorTheory && swift test
> ```
> The SPM package source directory is `XcodeColorTheory/` (unchanged on disk).

---

## Manual / UAT Scenarios

### 1. Sidebar — Palette Library

- [ ] Both built-in palettes (**Albers Midnight**, **Albers Ochre**) appear on first launch.
- [ ] Selecting a palette updates the editor and preview immediately.
- [ ] Built-in palettes have no Delete option in the context menu.
- [ ] Custom palettes show a Delete option; deleting removes them from the sidebar.

### 2. New Palette Sheet

- [ ] Tap **+** → sheet appears.
- [ ] Leaving Name blank disables the Create button.
- [ ] Entering a name that **already exists** disables the Create button. *(new)*
- [ ] All 6 harmony schemes are available in the picker.
- [ ] Base hue slider (0–360°) moves smoothly; the degree label updates.
- [ ] **Live preview updates in real time** as the hue slider is dragged or the scheme changes.
- [ ] Created palette appears in the sidebar and is auto-selected.

### 3. Palette Editor

- [ ] All 15 colour roles are shown across 4 sections (Canvas, Text, Keywords & Declarations, Literals & Attributes).
- [ ] **macOS**: tapping a swatch opens the system ColorPicker panel.
- [ ] **iOS**: tapping a swatch opens the system ColorPicker sheet.
- [ ] Changing a colour **persists** — navigate away and back; the edited colour is retained.
- [ ] Changing a colour updates the preview pane instantly (no lag, no revert).
- [ ] WCAG contrast badge shows AA / AAA / FAIL / UI for each foreground role.
- [ ] **Save** is disabled for built-in palettes.
- [ ] **Save** is enabled for custom palettes; saving persists across app restarts.

### 4. OKLCH Sliders *(new)*

Each colour role row now has an expand/collapse chevron.

- [ ] Tapping the chevron expands the row to reveal three sliders: **L** (0–1), **C** (0–0.37), **H** (0–360°).
- [ ] Each slider track is **colour-mapped** — the gradient reflects the current colour as the parameter is varied.
- [ ] Dragging any slider updates the swatch, the preview, and the contrast badge in real time.
- [ ] Collapsing the row hides the sliders; the colour change is retained.
- [ ] Adjusting H to a negative offset (via hue rotation) wraps correctly into 0–360° — no black or invalid swatch. *(hue normalisation fix)*
- [ ] Works on both macOS and iOS.

### 5. Harmony Propagation Mode *(new)*

Access via the **waveform icon** (second toolbar button) in the palette editor.

- [ ] Tapping the waveform button toggles propagation mode on/off.
- [ ] **On**: a **Harmony** section appears above the colour roles, containing:
  - A **Scheme** picker listing all 6 harmony schemes.
  - A **Base hue** slider (0–360°) with a degree readout.
  - A **Propagate Now** button.
- [ ] Dragging the Base hue slider re-derives all palette colours from the new hue in real time; the preview updates immediately.
- [ ] Changing the Scheme picker re-derives all palette colours; the preview updates.
- [ ] Tapping **Propagate Now** triggers a manual re-derive without changing the slider.
- [ ] The base hue slider is **seeded from the palette's current keyword hue** when propagation mode is first enabled.
- [ ] Toggling propagation off hides the Harmony section; previously propagated colours are kept.
- [ ] Works on both macOS and iOS.

### 6. Theme Preview

- [ ] The fake Swift code snippet renders using the selected palette colours.
- [ ] Background, keywords, types, strings, comments, doc-comments each show the correct role colour.
- [ ] **Line 7** is highlighted with the `.selection` background colour.
- [ ] A `|` cursor on line 7 is styled with the `.insertionPoint` colour.
- [ ] Live update: editing a colour in the editor is reflected in the preview without navigating away.
- [ ] No clipped text or overlapping tokens at default window size (1100 × 700 on macOS).

### 7. Albers Analysis View

- [ ] Contrast ratio table shows all 15 roles with numeric ratio and badge.
- [ ] Vibration risk matrix shows role pairs with risk > 0.3 highlighted.
- [ ] Fatigue summary flags any role with risk > 0.7.
- [ ] PaletteValidation banner shows: green for `.valid`, amber for `.warnings`, red for `.errors`.

### 8. Export — Font Hierarchy *(new)*

The export sheet now has a **Font Preset** picker instead of a single font selector.

- [ ] Preset picker lists all presets: JetBrains Mono, Fira Code, Cascadia Code, IBM Plex Mono, Victor Mono, SF Mono, Menlo.
- [ ] Below the picker, the resolved font for each category is shown:
  - **Comment** — typically italic or light weight.
  - **Keyword** — typically bold weight.
  - **Identifier** — typically regular weight.
- [ ] Selecting a different preset immediately updates the per-category readout.
- [ ] Exported `.xccolortheme` uses the correct per-category font strings in the XML — verify by opening the file in a text editor and checking `DVTSourceTextSyntaxFonts`.

### 9. Export — macOS

- [ ] **Install into Xcode** writes `<PaletteName>.xccolortheme` to
  `~/Library/Developer/Xcode/UserData/FontAndColorThemes/`.
  Open Xcode → Settings → Themes to verify the theme appears.
- [ ] **Save to Downloads** writes the file to `~/Downloads/`.
- [ ] **Copy XML to Clipboard** shows "Copied!" feedback for ~2 s, then resets.
  Paste into a text editor and verify valid XML plist structure.
- [ ] Open the exported file in a text editor and confirm `DVTSourceTextBlockDimStrength`
  is emitted as `<real>0.3</real>`, **not** `<string>`. *(plist type fix)*
- [ ] All three exports reflect any colour edits made before exporting.
- [ ] All three exports respect the selected font hierarchy.
- [ ] Palette name containing `&`, `<`, or `>` produces valid XML (entities escaped).
- [ ] Palette name containing `/` or `..` does **not** write outside the target directory.

### 10. Export — iOS

- [ ] **Install into Xcode** button is not shown on iOS.
- [ ] **Save to Downloads** is present and functional; file appears in Files app under the app's folder.
- [ ] **Copy XML to Clipboard** is present and functional; paste into Notes to verify.

### 11. Colour Explorer Playground

Open `ColorExplorer.playground` in the workspace navigator. Run the playground
(Shift+⌘+Return). Verify:

- [ ] No compile errors.
- [ ] All `print()` lines produce expected output in the console:
  - Round-trip L delta < 0.001
  - Contrast ratio between violet and navy ≥ 4.5
  - albersFavorite hues array is non-empty
  - XML output begins with `<?xml version="1.0"`
  - Font hierarchy presets list is non-empty

---

## Known Limitations

- Xcode theme installation (`Install into Xcode`) is macOS only.
- Colour picker on iOS uses the system sheet which does not expose OKLCH directly;
  values are converted on the way in via `rgbToOKLCH`.
- iOS **Save to Downloads** writes to the app's sandboxed container, not the
  system Downloads folder; accessible via Files app → On My iPhone → Theme Theory.
- OKLCH slider chroma range is clamped to 0–0.37; colours near the sRGB gamut
  edge at saturated hues may clip slightly on export.

---

## Regression Checklist (before every merge to `main`)

- [ ] `swift test` passes in `XcodeColorTheory/` (57 domain tests)
- [ ] ⌘U passes on **My Mac** destination (57 tests)
- [ ] ⌘U passes on **iPhone simulator** destination (57 tests)
- [ ] No new warnings in the Issue navigator on either platform
- [ ] Build succeeds for **My Mac** and **iPhone 16 Pro** simulator
- [ ] Playground runs without compile errors
- [ ] At least one export path verified manually on macOS; confirm `<real>` plist values
- [ ] OKLCH sliders verified on at least one role, both platforms
- [ ] Harmony propagation verified: base hue change re-derives palette
- [ ] TesterNotes.md updated if any scenario changed
