# AsciiFireEffect

## Overview
ASCII fire simulation that uses a heat buffer and maps each heat value to a text glyph plus a fire color.

## How it works
1. Seed random hot spots on the bottom row.
2. Add random cold spots on the bottom row (gaps).
3. Propagate heat upward by averaging neighbors.
4. Convert heat to an ASCII glyph and fire color, then draw it.

## How it works in detail
The effect keeps a 2D heat grid in a 1D array.  
Each frame runs three phases inspired by classic demoscene fire:

1. **Seeding**  
   Bottom row gets random heat values in the hot range. This is the fuel source.

2. **Cooling**  
   Random bottom-row cells are reset to zero. These cold gaps break up the base line and create flame separation.

3. **Propagation**  
   For every cell except bottom row, compute:
   - average of current, right, below, and below-right cells
   - store integer result back to current cell

Integer division naturally drops fractions, so heat slowly disappears as it climbs upward. That gives natural cooling without a separate decay constant.

Rendering:
- Heat `0..255` is mapped to an ordered ASCII palette from sparse glyphs to dense glyphs.
- The same heat value is mapped to a fire gradient (dark red -> orange/yellow -> white).
- Each cell is rendered as one glyph using `SdlText.Draw`.

## Math in plain language
- Averaging neighbor cells smooths the pattern and pushes fire upward.
- Integer truncation removes tiny heat fractions over time.
- More seed spots = stronger/taller flames; more cooling spots = shorter/sparser flames.

## Main knobs
- `speed`: simulation update rate.
- `intensity`: how many hot source spots are seeded.
- `cooling`: how many bottom-row cold gaps are injected.
- `font size`: ASCII cell size.

## Reference
- https://www.4rknova.com/blog/2025/11/01/ascii-fire
