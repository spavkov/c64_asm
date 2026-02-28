*=$0801
BasicUpstart2(start)

*=$1000

.const BORDER        = $d020
.const RASTER        = $d012
.const VIC_IRQ_FLAG  = $d019
.const VIC_IRQ_MASK  = $d01a
.const IRQ_VEC_LO    = $0314
.const IRQ_VEC_HI    = $0315
.const CIA1_ICR      = $dc0d
.const CIA2_ICR      = $dd0d

start:
    sei

    lda #$7f
    sta CIA1_ICR
    sta CIA2_ICR
    lda CIA1_ICR
    lda CIA2_ICR

    lda #<irq
    sta IRQ_VEC_LO
    lda #>irq
    sta IRQ_VEC_HI

    lda #$00
    sta RASTER
    lda #%00000001
    sta VIC_IRQ_MASK
    lda #$01
    sta VIC_IRQ_FLAG

    cli

main:
    jmp main

irq:
    inc BORDER
    lda #$01
    sta VIC_IRQ_FLAG
    jmp $ea31
