# TwisterEffect

## Overview
A classic C64-style chrome twister: a vertical column of stacked horizontal slices whose four phase-shifted edges form a twisting metallic ribbon on a white background. The twist follows a controllable rhythm — it stands still, gradually speeds up, then gradually slows down, and loops forever.

## How it works
1. For each `y`-row, compute a twist phase.
2. Generate four edge x-positions from quarter-phase (`pi/2`) sine waves.
3. Draw the visible faces (where the left edge is left of the right edge).
4. Shade each face with a chrome gradient plus a specular highlight and dark creases.

## How it works in detail
The column is rendered into a fixed 384x288 streaming texture, then scaled to fit the panel (centered, white-filled background).

For each scanline, a phase `a` is built from a nested sine that clusters the bands into "bulges":

- `a = twistAmp * sin(uy * TwistFreq - scroll) + spin`

Four edge positions come from quarter-phase offsets:

- `v[i] = ampX * sin(a + i*pi/2) + sway`

A face between `v[i]` and `v[i+1]` is drawn only when `v[i+1] - v[i] > 0` (a cheap front-facing test). Across each face the surface angle sweeps from one corner to the next, and the grayscale is taken from `cos(angle)` (diffuse) plus `pow(cos(angle), 22)` (specular) — that sweep is what gives the shiny chrome look. The face edges are darkened to form the crease/diamond notches.

### Liveliness
- A **beat-snap** envelope (`exp(-6 * frac(beat))`) makes the band count and sway pop on the beat.
- A **bar** oscillator breathes the column between loose (few fat bulges) and tight (many thin bands).
- A **serpentine sway** offsets each row horizontally so the column bends like a snake (inspired by the Pico-8 `xm` trick).

### Twist-speed rhythm
`RhythmSpeed(t)` returns the rotation speed:
1. `t < Standstill`: speed is 0 — the column stands perfectly still.
2. Then it `smoothstep`-eases from `Min` up to `Max` over `Ramp Up`.
3. Then it eases from `Max` back down to `Min` over `Ramp Down`, and the up/down cycle repeats.

The beat/breathing/sway clocks advance only while twisting, so the standstill is truly frozen and the slow phase pulses lazily.

## Main knobs
- `Standstill (s)`: how long the column stands still at the start.
- `Ramp Up (s)`: time to accelerate from the lazy speed to the fast speed.
- `Ramp Down (s)`: time to decelerate from fast back to lazy.
- `Min Speed`: the lazy floor speed (never fully stops after the initial standstill).
- `Max Speed`: the fast peak speed.
