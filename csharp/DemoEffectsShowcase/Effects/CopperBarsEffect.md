# CopperBarsEffect

## Overview
Draws animated horizontal color bars inspired by old-school copper effects.

## How it works
1. For each row, combine several sine waves into one intensity.
2. Map intensity into RGB copper-like colors.
3. Draw full-width line.
4. Add a moving glow band.

## How it works in detail
For each screen row, the effect computes a combined wave value from several sine functions with different frequencies and speeds. This layered signal avoids repetitive banding and creates richer motion.

Row intensity is normalized and mapped to copper-like RGB values. The row is drawn as a full-width horizontal line, so the full frame is built scanline by scanline.

After base bars, a moving highlight band is rendered:
1. Compute center row with another sine.
2. Draw several neighboring rows around that center.
3. Attenuate brightness by distance from center row.

This produces a dynamic bright streak traveling over the bars, emulating classic raster/copper glow behavior.

## Math in plain language
- Multiple sine layers add complexity.
- Glow line position also uses sine for smooth movement.

## Main knobs
- `speed`: animation speed.
- `glow`: glow brightness.
