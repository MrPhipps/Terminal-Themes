# A Friendly Guide to Color Spaces for Artists Who Code

Welcome! If you're an artist who also writes code (or a developer who loves color), this guide is for you. We're going to explore the fascinating world of color spaces—the mathematical "maps" we use to describe and manipulate colors.

You've probably heard of RGB, HSV, maybe even OKLCH. But why are there so many? And which one should you use when building a color tool, a theme generator, or an Albers‑style interaction experiment?

I'll walk you through the most important color spaces, explain what they're good for, how they work (with as little scary math as possible), and where they came from—including some cool SIGGRAPH history. By the end, you'll feel confident choosing the right tool for the job and maybe even appreciate the beauty of color science.

---

## What's a Color Space, Anyway?

Think of a color space as a coordinate system for colors. Just like you can describe a point on a map with latitude and longitude, you can describe a color by a set of numbers. Different coordinate systems emphasize different aspects.

- **RGB** describes colors by amounts of red, green, and blue light—great for screens, but not how our eyes see relationships.
- **HSL/HSV** (hue, saturation, lightness/value) is more intuitive: pick a hue, adjust saturation and lightness. But it's not "perceptually uniform"—a change of 10 in lightness might look tiny in one part of the space and huge in another.

When you're doing serious color work—like generating harmonious palettes, measuring contrast, or predicting how a color appears on different backgrounds—you need a color space that matches human perception. That's where the spaces below shine.

---

## 1. RGB and Linear RGB – The Screen's Native Language

RGB is what your monitor speaks. Red, green, and blue phosphors (or LEDs) mix to create all the colors you see. The values you usually work with (0–255 or 0–1) are gamma‑encoded—they've been adjusted to look correct on a typical screen.

**Linear RGB** is the "raw" light intensity before gamma correction. It's important for physics‑based calculations like light mixing, contrast, and color blending. Many color spaces (like CIELAB and OKLCH) start from linear RGB.

- **Artist's take:** If you're just picking colors, stick with sRGB. But when you compute something like "how bright is this color?" you should convert to linear RGB first.
- **Math intuition:** Gamma encoding is like a curved ruler—equal steps near the dark end produce bigger perceived jumps than near the bright end. Linear RGB uses a straight ruler.

---

## 2. CIELAB (Lab\*) – The Perceptual Standard

CIELAB (pronounced "see‑lab") was designed by the International Commission on Illumination (CIE) in 1976 to approximate human color vision. It has three axes:

- **L\***: lightness (0 = black, 100 = white)
- **a\***: green–red (negative = green, positive = red)
- **b\***: blue–yellow (negative = blue, positive = yellow)

**Why it matters:** Distances in CIELAB roughly correspond to how different we perceive two colors to be. This is incredibly useful for measuring "color difference" (ΔE).

### Artist's Use

- **Color difference:** When you want to know if two colors are too similar (e.g., text and background), compute ΔE (CIEDE2000). A ΔE less than 2 is usually imperceptible.
- **Adjusting colors:** Move along the L\* axis to make colors lighter/darker consistently.
- **Gamut mapping:** When converting colors between devices, CIELAB helps keep them looking similar.

### Where It Came From

CIELAB evolved from earlier work in the 1940s–60s by Adams, Nickerson, and others. It was the first widely adopted perceptually uniform space. Today it's used everywhere: from printing to computer graphics.

### Pitfalls

- **White point dependence:** CIELAB is defined relative to a reference white (e.g., D65 for sRGB). If you mix illuminants, colors will shift.
- **Out‑of‑gamut:** When converting back to RGB, you might get values outside the screen's gamut. You'll need to "clip" them (or use more sophisticated gamut mapping).

---

## 3. CIEDE2000 – The Color Difference Formula

CIEDE2000 (ΔE00) is a formula that takes two CIELAB colors and returns a single number representing how different they look. It's like a "perceptual distance" ruler.

- **History:** The CIE released ΔE94 in 1994, then refined it to ΔE00 in 2000 to fix quirks (especially in the blue region).
- **Math intuition:** It weighs lightness, chroma, and hue differences, and adds a special correction for blue hues (because our eyes are extra sensitive there).

### Artist's Use

- **Quality control:** Ensure your generated palette has enough distinction between adjacent roles (e.g., keyword vs. function).
- **Vibration risk:** Instead of a heuristic, you can use ΔE00: if two colors have low ΔE but different hues, they'll "vibrate" when adjacent.
- **Thresholds:** ΔE < 2.0: hard to see difference; ΔE > 10: very distinct.

### Pitfalls

- **Computational cost:** It's a bit heavy. Use it sparingly (e.g., on user request, not on every frame).
- **Not a complete description:** Two colors with the same ΔE can still appear differently if one is lighter and the other is more saturated. Use alongside other metrics.

---

## 4. CAM16 – Color Appearance Model

CAM16 is a color appearance model. While CIELAB tells you how a color *measures*, CAM16 tries to predict how it *looks* under specific viewing conditions—like on a screen in a bright room, or against a dark background.

It accounts for:

- **Simultaneous contrast** (a color looks different depending on its background)
- **Chromatic adaptation** (your eyes adjust to the whitest point)
- **Surround** (whether you're in a dark, dim, or average environment)

### Artist's Use

- Simulate how a color actually appears in your theme. For example, a saturated blue on a dark background might look lighter than its measured value. CAM16 can give you the "perceived" lightness.
- Albers' simultaneous contrast – exactly what CAM16 models.

### Where It Came From

The first CIE color appearance model was CIECAM97s (1997). CIECAM02 (2002) became the standard. CAM16 (2016) fixed mathematical issues and simplified some steps. It's used in high‑end imaging, ICC profiles, and research.

### Pitfalls

- **Complexity:** There's a lot of math under the hood. For many apps, a simple heuristic (like the current 15% lightness shift) may be enough. But if you want to be scientifically accurate, CAM16 is the way.
- **Parameter selection:** You need to set the surround, adapting luminance, and background. For a code editor, average surround, adapting luminance ≈ 100 cd/m², and the actual theme background are good choices.

---

## 5. IPT (ICtCp) – Hue‑Linear Color Space

IPT (or ICtCp) is a color space designed for **hue linearity** – moving a color's hue by the same angle anywhere in the space results in the same perceived hue shift. It also has a lightness axis (I) that's very close to perceived intensity.

- **History:** IPT was introduced by Ebner and Fairchild in 1998. The version you see today, ICtCp, was standardized in ITU‑R BT.2100 for HDR video. It's used in Dolby Vision and HDR10+.
- **Math intuition:** It starts from linear RGB, goes through a cone‑response space (LMS), applies a power function (like a "softening" curve), then a matrix to get I, Ct, Cp.

### Artist's Use

- **Hue rotations:** If you want to shift all the colors in a palette by 30°, doing it in IPT will keep them looking consistent. In RGB, hue rotations can cause weird saturation changes.
- **Chroma adjustments:** Changing Ct and Cp values tends to feel more natural than in RGB.

### Pitfalls

- **Version mix‑up:** Make sure you use the ICtCp version from BT.2100, not the original IPT (which had different constants).
- **Gamut issues:** When you convert back to RGB, values can go out of gamut. You'll need to clip or use a gamut mapping algorithm.

---

## 6. J<sub>z</sub>a<sub>z</sub>b<sub>z</sub> – HDR and Wide Gamut

J<sub>z</sub>a<sub>z</sub>b<sub>z</sub> (pronounced "jay‑zay‑bee-zee") is a relatively new color space (2017) from a SIGGRAPH Asia paper. It's designed for high dynamic range (HDR) and wide color gamut. It's like a modern, more uniform version of CIELAB, but works across a huge range of luminances (from 0 to 10,000 cd/m²).

- **History:** Developed by Safdar, Luo, and Li. It's derived from CAM16 but simplified to three dimensions, making it easier to use while retaining good perceptual uniformity.
- **Math intuition:** It uses a non‑linear compression similar to CAM16, but with a simpler opponent‑color transform.

### Artist's Use

- **HDR themes:** If you ever work with HDR displays (e.g., a pure white at 1000 nits), J<sub>z</sub>a<sub>z</sub>b<sub>z</sub> will give you more accurate lightness perception than CIELAB.
- **Advanced contrast metrics:** Use differences in J<sub>z</sub> as a high‑quality luminance contrast measure.

### Pitfalls

- **Complexity:** Still involved, but simpler than full CAM16.
- **Not yet ubiquitous:** You might not need it unless you're targeting HDR.

---

## 7. OKLCH – The Modern All‑Rounder

> **Already implemented.** OKLCH is the primary color space in Theme Theory. See `OKLCHColor.swift` and `ColorConversions.swift`.

OKLCH (and its Cartesian sibling OKLab) is a recent perceptual space by Björn Ottosson (2020). It's designed to be:

- **Perceptually uniform:** Lightness changes feel even, chroma is bounded, hue is circular.
- **Fast and simple:** Uses only a few linear transforms and a cube root.
- **Great for UI:** Because it's simple, you can update colors in real time.

---

## How to Choose the Right Space for Your Task

| Task | Recommended Space(s) |
|------|----------------------|
| Picking colors, adjusting sliders | **OKLCH** (or HSL for simplicity, but be aware) |
| Generating harmonious palettes (hue rotations) | **OKLCH** or **IPT (ICtCp)** for hue linearity |
| Measuring contrast (WCAG) | Relative luminance from **linear RGB** |
| Measuring perceptual difference | **CIELAB + CIEDE2000** |
| Predicting simultaneous contrast | **CAM16** (or fallback to heuristic) |
| HDR / wide gamut | **J<sub>z</sub>a<sub>z</sub>b<sub>z</sub>** |
| Storing/exporting for screens | **sRGB** (gamma‑encoded) |

---

## A Word on Software Architecture: Functional Core, Imperative Shell

When you're building a tool that manipulates colors, a great pattern is the **functional core, imperative shell**.

- **Functional core:** All the color conversions, difference calculations, harmony generation – these are pure functions. They take input, return output, and never change anything outside. They're easy to test and reason about.
- **Imperative shell:** The UI, file I/O, and networking – things that have side effects. It calls the core functions and displays the results.

This separation lets you experiment with new color spaces without breaking your UI code. It also makes it easier to port your logic to other platforms (like a command‑line tool or a web service).

---

## Bringing It All Together: Albers in Code

Josef Albers taught that color is "the most relative medium in art." To model that relativity, we need tools that respect perception:

- Use **OKLCH** for intuitive adjustments.
- Use **CIELAB/ΔE00** to quantify how different two colors are.
- Use **CAM16** to predict how a color will appear on different backgrounds.

You can start with OKLCH for most operations, then add CAM16 for advanced appearance previews, and use ΔE00 to guide the user toward readable, non‑fatiguing palettes.

---

## Extended Reference: Mathematical Foundations

### CIELAB & CIEDE2000

**Research History**

- **CIE 1976 Lab\*:** Introduced by the International Commission on Illumination (CIE) in 1976. Derived from earlier work by Adams (1942) and Nickerson (1950).
- **ΔE₉₄ (1994):** Added weighting factors for lightness, chroma, and hue.
- **CIEDE2000 (2000):** Developed by CIE TC 1‑47 (Melgosa et al.) to address remaining non‑uniformities, including a blue‑region rotation term. Finalized 2001; remains the industrial standard.

**Mathematical Foundation**

```
X, Y, Z = linearRGB_to_XYZ(R_lin, G_lin, B_lin)
L* = 116 f(Y/Yn) - 16
a* = 500 [f(X/Xn) - f(Y/Yn)]
b* = 200 [f(Y/Yn) - f(Z/Zn)]

f(t) = t^(1/3)              for t > 0.008856
       (7.787 t) + 16/116   otherwise
```

CIEDE2000 (ISO 11664‑6:2014) structure:
1. Chroma and hue adjustments based on a weighting of the a axis.
2. Weighting functions for lightness (S_L), chroma (S_C), and hue (S_H).
3. Rotation term (R_T) for blue hues.

**References**
- CIE Publication 15:2004 – Colorimetry.
- ISO 11664‑4 (CIELAB) and ISO 11664‑6 (CIEDE2000).
- Sharma, G., Wu, W., & Dalal, E. N. (2005). The CIEDE2000 color‑difference formula. *Color Research & Application.*

---

### CAM16

**Research History & SIGGRAPH Presence**

- **CIECAM97s (1997):** First comprehensive CIE color appearance model.
- **CIECAM02 (2002):** Major revision; used in ICC color management.
- **CAM16 (2016):** Li, Luo et al. Fixed mathematical singularities, improved performance. The underlying CAT16 adaptation is used in tone‑mapping pipelines presented at SIGGRAPH.

**Mathematical Foundation**

Inputs: XYZ stimulus, adapting white, adapting luminance L_A (cd/m²), surround parameters (c, N_c, F), background luminance Y_b.

Steps:
1. **Chromatic adaptation (CAT16):** Transform stimulus to adapting white via linear matrix.
2. **Post‑adaptation:** Non‑linear response compression (power function) + opponent‑color dimensions.
3. **Outputs:** J (lightness), C (chroma), h (hue), Q (brightness), M (colorfulness), s (saturation).

**Recommended parameters for a dark‑theme code editor:**
- Surround: average
- Adapting luminance: ≈ 100 cd/m²
- Background luminance: theme background relative luminance

**References**
- CIE 159:2004 – CIECAM02.
- Li, C., et al. (2016). CAM16. *Color Research & Application.*

---

### IPT (ICtCp)

**Research History**

- **IPT (1998):** Ebner & Fairchild. Improved hue linearity over CIELAB.
- **ICtCp:** Standardized in ITU‑R BT.2100 for HDR video (Dolby Vision, HDR10+).

**Mathematical Foundation (ICtCp / BT.2100)**

```
1. Linear RGB → LMS  (Rec. 2020 XYZ matrix)
2. LMS → L'M'S':  L' = L^0.43  (similarly M', S')
3. L'M'S' → ICtCp:

[ I ]   [  0.5    0.5    0.5  ] [ L' ]
[ Ct] = [  1.5   -1.5    0    ] [ M' ]
[ Cp]   [  0.5    0.5   -1.0  ] [ S' ]
```

Power function exponent 0.43 is fixed per spec — do not alter.

**References**
- ITU‑R BT.2100-2 (2018).
- Ebner, F., & Fairchild, M. D. (1998). Development and testing of a color space (IPT). *IS&T 6th Color Imaging Conference.*

---

### J_z a_z b_z

**Research History & SIGGRAPH Paper**

Introduced by Safdar, Luo, and Li at **SIGGRAPH Asia 2017**: *"J_z a_z b_z: A novel colour space for high‑dynamic‑range and wide‑colour‑gamut imaging."* Derived from CAM16, simplified to 3D, better uniformity than CIELAB for HDR (0–10,000 cd/m²). Adopted in HDR image quality metrics (e.g., HDR‑VDP).

**Mathematical Foundation**

1. Chromatic adaptation (CAT16) to D65.
2. Non‑linear compression: `R' = (0.5 * R)^0.42` after matrix multiplication.
3. Opponent‑color transform → J_z, a_z, b_z.

Full matrices and constants in the original SIGGRAPH Asia 2017 paper.

**References**
- Safdar, M., Luo, M. R., & Li, C. (2017). J_z a_z b_z. *SIGGRAPH Asia 2017 Technical Briefs.*

---

### OKLCH / OKLab

**Research Background**

OKLab by Björn Ottosson (2020): fast, perceptually uniform, better hue linearity than CIELAB. Adopted in CSS Color Level 4 as `oklch()`. OKLCH is its cylindrical representation (lightness, chroma, hue).

**Mathematical Foundation**

```swift
// Linear RGB → OKLab
l = 0.4122214708*R + 0.5363325363*G + 0.0514459929*B
m = 0.2119034982*R + 0.6806995451*G + 0.1073969566*B
s = 0.0883024619*R + 0.2817188376*G + 0.6299787005*B

l = cbrt(l); m = cbrt(m); s = cbrt(s)

L = 0.2104542553*l + 0.7936177850*m - 0.0040720468*s
a = 1.9779984951*l - 2.4285922050*m + 0.4505937099*s
b = 0.0259040371*l + 0.7827717662*m - 0.8086757660*s
```

**Already implemented** in `ColorConversions.swift`.

---

## Further Reading

**Books**
- *Color Appearance Models* (3rd ed.) – Mark D. Fairchild
- *Interaction of Color* – Josef Albers

**Standards**
- CIE 15:2004 – Colorimetry
- ISO 11664‑4 (CIELAB), ISO 11664‑6 (CIEDE2000)
- ITU‑R BT.2100 – HDR television

**Papers**
- Sharma et al. (2005) – CIEDE2000 implementation notes
- Li et al. (2016) – CAM16
- Safdar et al. (2017) – J_z a_z b_z (SIGGRAPH Asia)
- Ebner & Fairchild (1998) – IPT
- Ottosson (2020) – OKLab blog post

---

*Document prepared: 2026‑03‑30. Future features: CIELAB+ΔE2000, CAM16 simultaneous contrast, IPT hue rotations, J_z a_z b_z HDR support.*
