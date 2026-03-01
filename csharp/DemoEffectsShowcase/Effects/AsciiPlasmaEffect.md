# AsciiPlasmaEffect

## Overview
ASCII plasma rendered as animated text cells with switchable wave patterns and blend control.

## Important note
This implementation is original and does not copy source code from third-party pages.

## How it works
1. Split the viewport into text cells based on font size.
2. Convert each cell to normalized UV coordinates.
3. Evaluate plasma wave equations for two patterns.
4. Blend the two pattern outputs.
5. Map intensity to a glyph and heat-map color, then draw with `SdlText`.

## How it works in detail
The effect computes a scalar value per text cell from sine/cosine waves:
- Classic
- Vortex
- Interference
- Diamond
- Tunnel
- Ripple
- Metaballs
- Moire
- Checkerboard
- Waves
- Warp
- Kaleidoscope
- Matrix
- Spiral
- Pulse

The `pattern` parameter chooses the base pattern from the list above.  
The `blend` parameter mixes that pattern with the next one:
- `value = lerp(pattern(base), pattern(next), blend)`

The value is clamped to `[-2, 2]`, normalized to `[0, 1]`, and then:
- mapped to an ASCII palette from sparse to dense glyphs,
- mapped to a heat-map gradient color.

This creates smooth flowing plasma motion in text mode while preserving retro ASCII style.

## Math in plain language
- Sine/cosine produce smooth repeating waves.
- Adding different waves creates interference patterns.
- Blending between pattern formulas gives controlled morphing.
- Dense characters represent high intensity; sparse characters represent low intensity.

## Main knobs
- `speed`: animation speed.
- `zoom`: plasma scale.
- `blend`: mix amount between current and next pattern.
- `pattern`: dropdown selector (15 patterns listed above).
- `font size`: ASCII cell size.
