# MeatballsEffect

## Overview
Draws metaballs (blob shapes) that merge when close.

## How it works
1. Animate several ball centers.
2. For each sampled block, sum ball influence values.
3. Compare summed field to a threshold.
4. Draw only blocks above threshold.

## How it works in detail
Each metaball is treated as a source of influence in a scalar field. At a sampled point `(x, y)`, the effect computes squared distance to each ball center:
- `d2 = dx*dx + dy*dy + 1`

Then it adds each contribution as:
- `field += (R*R) / d2`

This inverse-distance behavior means nearby samples get much larger values than distant samples. Because all ball contributions are summed, their fields blend naturally: when two balls approach, the sum between them rises and a bridge appears.

Thresholding turns the continuous field into visible shape:
- if `field < threshold`, skip drawing
- else map `(field - threshold)` to a color ramp and draw a block

That means geometry is implicit (not explicit polygons). The blob boundary is the isocontour where field equals threshold. Drawing is done block-by-block to keep runtime low while preserving the classic metaball look.

## Math in plain language
- Each ball influence is roughly `radius^2 / distance^2`.
- Near a ball => stronger contribution.
- Summed contributions create merged blob areas.

## Main knobs
- `speed`: motion speed.
- `threshold`: blob size and merge sensitivity.
