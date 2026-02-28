# TexturedCubeEffect

## Overview
Renders a rotating 3D cube and maps a texture image onto visible faces.

## How it works
1. Rotate all cube vertices in 3D.
2. Project to 2D with perspective.
3. Cull backfaces using face normals.
4. Sort visible faces by depth.
5. Fill each face by sampling texture via UV coordinates.

## How it works in detail
The frame starts by rotating all 8 cube vertices in 3D and projecting them into screen space with perspective division. This yields 2D corner points for every face.

Visible-face selection uses backface culling:
1. Build two edge vectors on a face.
2. Compute face normal via cross product.
3. Compare normal direction with camera-to-face-center vector (dot product).
4. Skip faces pointing away from camera.

Remaining faces are depth-sorted so farther faces are drawn first.

For each visible quad face:
1. Compute its screen-space bounding box.
2. Iterate sample blocks inside that box.
3. For each block center, test if point is inside the quad by splitting quad into 2 triangles.
4. Use barycentric coordinates to interpolate UV coordinates.
5. Convert UV to texture pixel indices and sample RGB.
6. Draw block with sampled color.

This is effectively a software rasterizer for textured quads, using block sampling instead of per-pixel fill for performance. Outline lines are then drawn around the face to improve edge readability.

## Math in plain language
- Rotation: sine/cosine around X/Y/Z axes.
- Projection: divide by depth so far points are smaller.
- UV mapping: convert screen sample points to local face coordinates.
- Barycentric coordinates: robust inside-triangle test and interpolation.

## Main knobs
- `speed`: rotation speed.
- `density`: sampling quality/performance.
- `zoom`: cube size.
