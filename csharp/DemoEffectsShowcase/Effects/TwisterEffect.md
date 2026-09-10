# TwisterEffect

## Overview
A classic C64-style chrome twister: a vertical column of stacked horizontal slices whose four phase-shifted edges form a twisting metallic ribbon on a white background. After an optional initial pause, rotation smoothly speeds up and slows down without reversing.

## How it works
1. For each `y`-row, compute a twist phase.
2. Generate four edge x-positions from quarter-phase (`pi/2`) sine waves.
3. Draw the visible faces (where the left edge is left of the right edge).
4. Shade each face with a chrome gradient plus a specular highlight and dark creases.

## How it works in detail
The column is rendered into a fixed 384x288 streaming texture, then scaled to fit the panel (centered, white-filled background).

For each scanline, a phase `a` combines a stable spatial twist with small traveling waves:

- `flow = spin * 0.72`
- `a = spin + uy * 7 + 0.55 * sin(uy * 2.2 - flow) + 0.12 * sin(uy * 5.4 + flow * 0.55)`

Four edge positions come from quarter-phase offsets:

- `v[i] = ampX * sin(a + i*pi/2) + sway`

A face between `v[i]` and `v[i+1]` is drawn only when `v[i+1] - v[i] > 0` (a cheap front-facing test). Across each face the surface angle sweeps from one corner to the next, and the grayscale is taken from `cos(angle)` (diffuse) plus `pow(cos(angle), 22)` (specular) — that sweep is what gives the shiny chrome look. The face edges are darkened to form the crease/diamond notches.

### Liveliness
Small sine waves vary the width and centerline. The twist density stays stable,
avoiding sudden beat snaps or bursts of tightly packed bands.

### Twist-speed rhythm
Like Meatballs' smooth oscillating positions, the rotation rhythm uses a sinusoid.
Here it modulates **speed**, not position, so the twister never turns backward:

- `averageSpeed = TurnsPerCycle * 2*pi / CycleDuration`
- `speed = averageSpeed * (1 - PulseStrength * cos(2*pi * elapsed / CycleDuration))`

`ForwardSpin(t)` evaluates the integral of that speed. Each update adds only the
current frame's difference, so changing controls cannot rewind the accumulated
rotation. With fixed controls it is continuous between cycles and advances
`TurnsPerCycle` each cycle. With pulse strength
between 0 and 1, speed is always nonnegative. Full strength starts from rest,
accelerates to its peak halfway through the cycle, and eases back to rest.
The deformation follows the rotation phase, so the initial standstill is frozen.

## Main knobs
- `Standstill (s)`: how long the column stands still at the start.
- `Cycle Duration (s)`: duration of one complete speed-up/slow-down cycle.
- `Turns / Cycle`: forward rotations completed in each cycle.
- `Pulse Strength`: 0 gives constant speed; 1 gives the full stop-to-fast-to-stop rhythm.
