# RotozoomEffect

## Overview
Displays a checkerboard-like pattern that rotates and zooms over time.

## How it works
1. Normalize pixel coordinates around screen center.
2. Apply 2D rotation matrix.
3. Apply animated zoom scale.
4. Convert transformed coordinates to checker tiles.
5. Add pulse shading.

## How it works in detail
Each sampled screen block is transformed from screen coordinates into effect-space coordinates centered around `(0,0)`. The effect then applies:
1. Rotation using 2D rotation matrix.
2. Uniform scaling with animated zoom value.

Transformed coordinates are quantized to tile indices; parity (even/odd) of tile coordinates determines checker color region. A time-varying pulse function adds local brightness modulation so the pattern is not flat.

Because rotation and zoom are applied in transformed space before tile lookup, the checker texture appears to spin and breathe. Rendering uses block fills for speed, preserving a stylized retro look while keeping motion smooth.

## Math in plain language
- Rotation matrix:
  - `x' = x*cos(a) - y*sin(a)`
  - `y' = x*sin(a) + y*cos(a)`
- Checker toggles by even/odd tile indices.

## Main knobs
- `speed`: animation speed.
- `zoom`: zoom modulation amount.
