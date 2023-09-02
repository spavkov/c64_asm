// found here and translated via google translator: https://www.retro-programming.de/programming/nachschlagewerk/interrupts/

.label raster   = $d012  // current raster line
.label intflag  = $d019  // interrupt flag reg
.label frame_color_register    = $d020  // frame color
.label border_color_register   = $d021  // border color


.label irq_vector_low   = $0314  // border color
.label irq_vector_high   = $0315  // border color

BasicUpstart2(start)
start:
    sei
    lda #<myirq1
    sta irq_vector_low
    lda #>myirq1
    sta irq_vector_high
    cli
    rts

myirq1:
    inc frame_color_register