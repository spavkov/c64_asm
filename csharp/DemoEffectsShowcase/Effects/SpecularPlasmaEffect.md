# SpecularPlasmaEffect

## Overview
A shader-style plasma that combines wave interference, cosine color palette mapping, and a glossy specular pass.

## How it works
1. Convert each sampled screen block to UV coordinates with aspect correction and time scrolling.
2. Build a plasma scalar from phase oscillators and radial distance.
3. Map plasma scalar to RGB with phase-shifted cosine channels.
4. Estimate local color gradient and apply a warm specular lighting boost.
5. Draw the block.

## How it works in detail
The effect follows the 4rknova plasma formula and adapts it to CPU block rendering:

- UV mapping:
  - `u = 4 * zoom * (x / width) * aspect + time * 0.3`
  - `v = 4 * zoom * (y / height) + time * 0.3`
- Phase oscillators:
  - `phaseV = 0.1 + cos(v + sin(0.148 - t)) + 2.4*t`
  - `phaseH = 0.9 + sin(u + cos(0.628 + t)) - 0.7*t`
- Interference:
  - `radial = length(uv)`
  - `plasma = 7 * cos(radial + phaseH) * sin(phaseV + phaseH)`
- Palette:
  - `rgb = 0.5 + 0.5*cos(plasma + offsets)`
  - Offsets are `(0.2, 0.5, 0.9)` for R/G/B.

Specular approximation:
- The shader version uses `dFdx/dFdy`. On CPU, we approximate this by sampling neighboring UV points and measuring color delta.
- Gradient magnitudes become an approximate surface slope.
- A pseudo-normal is built from `(gradX, gradY, smallZ)`.
- Specular intensity is `pow(max(normal.z, 0), 2)`.
- A warm highlight tint is applied, then an ambient floor keeps dark areas visible.

## Math in plain language
- Sine and cosine waves are smooth up/down curves.
- Mixing waves at different speeds makes a pattern that never feels static.
- The radial term adds circular behavior so the plasma is not only horizontal/vertical.
- Specular simply brightens areas that are locally "flatter" in the generated field.

## Main knobs
- `speed`: animation speed.
- `zoom`: pattern scale.
- `specular`: highlight strength.
- `tint`: final RGB multiplier.

## Reference
- https://www.4rknova.com/blog/2016/11/01/plasma
