# StarfieldEffect

## Overview
Simulates stars moving toward the camera in 3D space.

## How it works
1. Spawn stars with random x/y and positive z depth.
2. Decrease z each frame (move toward camera).
3. Project with perspective: `screen = center + (x/z, y/z) * fov`.
4. Respawn stars that pass camera or leave screen.

## How it works in detail
Each star stores 3D position `(x, y, z)`. Update decreases `z` each frame, which means stars move toward the camera. When `z` becomes too small (star passed camera), the star is respawned at a far random depth.

Projection to screen uses perspective:
- `screenX = centerX + (x / z) * fov`
- `screenY = centerY + (y / z) * fov`

As `z` gets smaller, `(x/z, y/z)` grows, so stars appear to accelerate outward from the center. This naturally creates the classic hyperspace motion effect without explicit velocity in screen space.

Stars that project off-screen are respawned to maintain visual density. Spawn positions are chosen inside the current camera frustum at the selected depth, so recycled stars are likely to appear on-screen instead of repeatedly respawning out of view. Recycled stars are also biased toward far depth so the field keeps a steady stream of incoming stars instead of collapsing to only a few visible ones.

Frustum-based spawn:
- `halfX = z * (width/2) / fov`
- `halfY = z * (height/2) / fov`
- `x in [-halfX, +halfX]`, `y in [-halfY, +halfY]`

Brightness is mapped inversely from depth so close stars are brighter and distant stars are dimmer, reinforcing depth cues.

## Math in plain language
- Small z means near camera.
- Perspective divide makes near stars move faster on screen.
- Brightness increases as z decreases.

## Main knobs
- `speed`: movement speed.
- `fov`: projection scale.
