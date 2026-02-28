# SineScrollerEffect

## Overview
Scrolls text horizontally while letters move up/down along a sine wave.

## How it works
1. Compute scroll offset from time.
2. Repeat text copies for seamless wrap.
3. For each character, compute y offset with sine.
4. Modulate color with another sine wave.

## How it works in detail
The text is treated as a repeating strip with total pixel length:
- `total = textLength * glyphAdvance`

Horizontal offset is `scroll = (time * speed) % total`, which wraps seamlessly. Multiple copies of the strip are drawn so the viewport always has valid glyphs entering/exiting.

For each character index `i`:
- `x` comes from strip position minus scroll
- `y` comes from sine wave: `baseY + sin(time * wf + i * phaseOffset) * amplitude`

Including `i` in phase means neighboring letters are at different wave positions, producing the classic wavy string instead of whole-line bobbing.

Color shimmer is another sine using time + index, so hue/brightness varies across letters and over time. Each glyph is then drawn through the bitmap font routine at computed `(x, y)`.

## Math in plain language
- Sine gives smooth oscillation.
- Character index is part of phase, so letters are offset from each other.
- Separate sine for color creates shimmer.

## Main knobs
- `speed`: horizontal scroll speed.
- `amplitude`: vertical wave size.
