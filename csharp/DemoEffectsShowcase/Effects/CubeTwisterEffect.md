# CubeTwisterEffect

## Overview
Draws a retro scanline twister that resembles rotating cube/ribbon sides.

## How it works
1. For each y-row, compute a phase value.
2. Generate four x-positions from phase-shifted sine waves.
3. Draw horizontal spans between neighboring positions.
4. Shade spans for depth-like contrast.

## How it works in detail
The effect renders horizontal scanlines. For each `y`, it computes a normalized row position `yNorm` and derives a twist phase from time and row. That phase controls where the four virtual ribbon sides appear on that row.

Four x-coordinates are generated with quarter-phase (`pi/2`) offsets:
- `x[i] = center + amplitude * sin(phase + i*pi/2)`

These represent cyclic side boundaries. Neighbor pairs are connected as horizontal spans, but only when ordered left-to-right, acting as a cheap visibility rule.

Shading uses another sine term based on phase and segment index. As phase changes over time, side ordering and shade change, creating a rotating 3D-like ribbon/cube illusion even though geometry is 2D scanline spans.

So the final image is produced by:
1. Compute per-row phase.
2. Compute four side boundaries.
3. Draw visible spans with per-span shading.

## Math in plain language
- Sine waves provide smooth periodic motion.
- 90-degree phase offsets model different visible sides.
- Per-scanline rendering mimics classic raster effects.

## Main knobs
- `speed`: animation speed.
- `spin`: twist amount.
