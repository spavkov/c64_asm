# CubePlasmaSideEffect

## Overview
Combines a rotating wireframe cube with one face filled by animated plasma.

## How it works
1. Rotate/project cube vertices.
2. Select one face and rasterize it in small blocks.
3. Convert each block center to face UV coordinates.
4. Feed UV + time into sine waves to generate plasma colors.
5. Draw wireframe edges on top.

## How it works in detail
The cube vertices are rotated/projection-mapped exactly like a normal 3D wireframe cube. One selected face (a projected quad) is then filled with animated plasma before wireframe edges are drawn over it.

Face fill algorithm:
1. Compute screen-space bounding box of the selected quad.
2. Step through the box in small blocks.
3. For each block center, test whether it lies inside the projected quad.
4. Convert that screen point into local face UV coordinates using barycentric interpolation.
5. Evaluate two sine-based plasma terms from `(u, v, time)`.
6. Convert scalar result to RGB and draw the block.

Using UV space is important: plasma pattern stays attached to the face as it rotates, instead of sliding in raw screen coordinates. Finally, the shared wireframe renderer draws cube edges on top, giving strong face boundary definition.

## Math in plain language
- UV coordinates are local 0..1 coordinates on the face.
- Two sine waves sampled from U and V make the plasma pattern.
- Barycentric coordinates are used to test point-in-face and derive UV.

## Main knobs
- `speed`: cube rotation speed.
- `plasma`: plasma animation speed.
