# AsciiDonutEffect

## Overview
Renders a rotating 3D ASCII torus (donut) with depth buffering, shading, character sets, and color modes.

## Reference / inspiration
- https://www.asciiart.eu/animations/ascii-spinning-donut

## How it works
1. Sample a torus surface using two angles (`theta`, `phi`).
2. Rotate sampled 3D points around X and Y.
3. Project points to a 2D ASCII grid with perspective.
4. Keep the nearest point per grid cell (z-buffer).
5. Compute light intensity from rotated normals and a configurable light direction.
6. Map intensity to a glyph and color.

## How it works in detail
The torus is parameterized by two radii:
- major radius: donut body size (`size`)
- minor radius: tube thickness (`thickness`)

For each `(theta, phi)` pair, the effect computes:
- 3D point on the torus
- surface normal at that point

Both are rotated by current X/Y angles, then projected:
- larger `1/depth` means point is closer and appears larger
- only the closest sample per text cell is kept

Lighting:
- Build a light vector from `light angle` (azimuth) and `light height` (elevation).
- Brightness is `max(dot(normal, lightDir), 0)`.
- Brightness chooses both glyph density and final color.

Extra controls:
- `auto rotate`: toggles continuous motion.
- `wobble`: adds a small sinusoidal perturbation to make motion less rigid.
- `characters`: swaps glyph palette style.
- `color`: swaps color mode (`none`, `fire`, `cool`, `rainbow`, `matrix`, `sunset`).

## Main knobs
- `auto rotate`, `wobble`
- `rotation x`, `rotation y`
- `size`, `thickness`
- `light angle`, `light height`
- `characters`, `color`
- `font size`
