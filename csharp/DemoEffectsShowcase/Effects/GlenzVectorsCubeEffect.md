# GlenzVectorsCubeEffect

## Overview
A wrapper around `WireframeCubeEffect` with slightly slower update timing.

## How it works
1. Forwards initialize/resize to the internal wireframe cube.
2. Updates cube with `delta * 0.9`.
3. Renders the same wireframe cube.

## How it works in detail
This effect is intentionally implemented as a composition wrapper around `WireframeCubeEffect`. It does not currently implement a separate glenz face rasterization path.

Execution flow:
1. Initialize/resize calls are forwarded to the internal wireframe cube.
2. Update is forwarded with a `0.9` multiplier, so angular progression is slightly slower.
3. Render delegates directly to wireframe rendering.

So, visually and mathematically, rotation/projection/line drawing are inherited from `WireframeCubeEffect`. The value of this class today is effect identity, parameter compatibility, and a clean extension point for future transparent-face blending.

## Math in plain language
This effect delegates all 3D math to `WireframeCubeEffect`.

## Notes
`alpha` is kept as a compatibility parameter for future transparency behavior.
