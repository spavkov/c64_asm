# PlasmaEffect

## Overview
Draws a flowing color field by combining several sine waves.

## How it works
1. For each sampled screen block, compute three sine values from x, y, and time.
2. Average them into one plasma value.
3. Convert that value into RGB with phase-shifted sine functions.
4. Draw the block.

## How it works in detail
For each sampled block center `(x, y)`, the effect evaluates three independent wave fields:
- `v1 = sin(x * fx + t * s1)`
- `v2 = sin(y * fy + t * s2)`
- `v3 = sin((x + y) * fxy + t * s3)`

These three terms represent horizontal, vertical, and diagonal movement components. Averaging them creates a scalar field that changes smoothly over space and time. This field is not drawn directly; it is used as a phase input for color generation.

Color channels are computed from the same scalar field but with phase offsets, so red/green/blue peaks do not align at the same time. That phase separation is what creates color cycling instead of flat grayscale ripples. Finally, one rectangle is drawn per sample block using `FillRect`, so the final image is a coarse mosaic approximation of the continuous field (good performance with retro style).

Render pipeline per block:
1. Compute combined plasma scalar.
2. Convert scalar to RGB with shifted sine phases.
3. Clamp to byte range.
4. Draw one block to the renderer.

## Math in plain language
- `sin(...)` gives smooth -1..+1 values.
- Summing different sine waves creates complex organic motion.
- Offsetting color phases makes gradients and rainbow transitions.

## Main knobs
- `speed`: animation speed.
- `tint`: multiplies RGB output.
