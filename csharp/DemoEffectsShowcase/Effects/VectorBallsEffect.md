# VectorBallsEffect

## Overview
Places many small balls on a 3D sphere, rotates them, and projects to 2D.

## How it works
1. Build points using latitude/longitude loops.
2. Rotate every point around X, Y, and Z.
3. Project using perspective divide (`x/depth`, `y/depth`).
4. Sort by depth and draw far-to-near.

## How it works in detail
Initialization builds a sphere point cloud using latitude/longitude sampling. For each latitude angle `a` and longitude angle `b`:
- `x = cos(b) * cos(a)`
- `y = sin(a)`
- `z = sin(b) * cos(a)`

Per frame, each point is rotated around X, then Y, then Z. Rotation is done with standard 3D axis formulas using `sin`/`cos`, producing a new 3D position in camera space. Projection then maps 3D to 2D:
- `screenX = cx + (x / depth) * scale`
- `screenY = cy + (y / depth) * scale`

where `depth` depends on `z`. Larger depth shrinks projected offset, creating perspective.

The renderer stores `(screenPos, z)` for all points, sorts by `z` (far to near), then draws circles. This painter-style order ensures nearer balls visually sit on top of farther ones. Radius and brightness are both derived from depth so near balls look larger and brighter, improving depth readability.

## Math in plain language
- Rotations use sine/cosine circle math.
- Perspective makes distant points appear smaller.
- Depth sort avoids near points being hidden by far points.

## Main knobs
- `speed`: rotation speed.
- `scale`: ball size multiplier.
