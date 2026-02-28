# WireframeCubeEffect

## Overview
Draws a rotating 3D cube as connected lines.

## How it works
1. Define 8 cube vertices.
2. Rotate each vertex around X/Y/Z axes.
3. Project rotated 3D points into 2D screen points.
4. Draw 12 edges between projected points.

## How it works in detail
The cube is defined by 8 model-space vertices and a fixed edge list of 12 index pairs. Each frame, every vertex goes through two stages: rotation in 3D and projection to 2D.

Rotation stage:
1. Rotate around X axis (changes Y/Z).
2. Rotate around Y axis (changes X/Z).
3. Rotate around Z axis (changes X/Y).

Each axis rotation uses sine/cosine and produces intermediate coordinates. Sequential axis rotation yields the final 3D orientation.

Projection stage uses perspective divide:
- `screenX = centerX + (x / depth) * scale`
- `screenY = centerY + (y / depth) * scale`

with `depth = cameraOffset + z`. Larger depth shrinks projected displacement, so distant points look closer together.

Draw stage iterates edge pairs and draws lines between their projected endpoints. Because topology is fixed and only vertex positions change, the cube appears as a smoothly rotating wireframe.

## Math in plain language
- Rotation uses sine/cosine.
- Perspective divide by depth makes distant points look smaller.
- Edge list defines which points are connected.

## Main knobs
- `speed`: rotation speed.
- `line`: line width parameter.
- `color`: line color.
