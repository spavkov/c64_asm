# FireEffect

## Overview
Classic palette fire simulation on a coarse heat grid.

## How it works
1. Bottom row gets random hot values (fire source).
2. Upper cells average heat from row below.
3. Apply random cooling/decay.
4. Map heat (0..255) to fire palette colors.

## How it works in detail
The simulation runs on a coarse 2D heat grid, not directly at full screen resolution. This keeps updates cheap and naturally gives chunky retro pixels when scaled up.

Update stage:
1. Bottom row is refueled each frame with random high heat values.
2. For each cell above bottom, read three cells from row below (left, center, right).
3. Average those three values.
4. Subtract random decay scaled by cooling.
5. Clamp at zero.

This creates upward propagation because each row depends on the row beneath it. Lateral spread comes from mixing left/right neighbors. Random decay produces turbulent flicker.

Render stage:
- Convert each heat value (0..255) to palette color bands (dark red -> red/yellow -> white-hot).
- Draw each heat cell as a screen rectangle of size `_cell`.

So the perceived fire shape is emergent from repeated local averaging + random cooling, not hardcoded flame sprites.

## Math in plain language
- Averaging neighbors smooths flames.
- Random decay creates flicker.
- Heat naturally appears to rise because each row reads from below.

## Main knobs
- `intensity`: source heat strength.
- `cooling`: decay strength.
