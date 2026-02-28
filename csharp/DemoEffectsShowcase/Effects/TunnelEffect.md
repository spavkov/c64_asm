# TunnelEffect

## Overview
Creates a moving tunnel illusion by remapping screen pixels into polar texture lookups.

## How it works
1. Precompute distance and angle table for every screen location.
2. Use those values as texture coordinates.
3. Shift texture coordinates over time (forward + spin).
4. Convert sampled texture intensity into color.

## How it works in detail
The effect precomputes, for every screen pixel, two lookup values relative to screen center:
- radial distance `d = sqrt(dx^2 + dy^2)`
- angular position `a = atan2(dy, dx)`

These are converted into texture-space indices:
- distance index `u ~ ratio / d`
- angle index `v ~ a`

At runtime, the expensive `sqrt/atan2` work is already done, so rendering is mostly table lookup plus texture sampling. Animated motion is achieved by adding time-based shifts to `u` and `v`:
- forward motion: add to distance coordinate
- spin motion: add to angle coordinate

The sampled intensity from the procedural texture is converted to RGB tint. Because `1/d` grows quickly near the center and slowly near the edges, equal steps in screen space map nonlinearly in texture space, producing the sensation of depth and forward travel inside a tunnel.

## Math in plain language
- `distance = sqrt(dx^2 + dy^2)` from screen center.
- `atan2(dy, dx)` gives angle around center.
- Inverse distance mapping creates depth illusion.

## Main knobs
- `forward`: forward speed.
- `rotation`: spin speed.
- `ratio`: depth scaling.
