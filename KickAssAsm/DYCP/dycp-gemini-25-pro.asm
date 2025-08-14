// KickAssembler source file for a stable raster interrupt on the C64

.const RASTER_LINE = $64  // target raster line (100)

BasicUpstart2(init)


init:
    sei                         // disable interrupts

    lda #$7f
    sta $dc0d                   // disable CIA1 timers
    sta $dd0d                   // disable CIA2 timers
    lda $dc0d                   // acknowledge any pending CIA interrupts
    lda $dd0d

    lda #$01
    sta $d01a                   // enable raster IRQs

    lda #<irq1
    sta $0314                   // set IRQ vector low byte
    lda #>irq1
    sta $0315                   // set IRQ vector high byte

    lda $d011
    and #%01111111
    sta $d011                   // clear high bit of raster line
    lda #RASTER_LINE
    sta $d012                   // set raster line

    lda #$1b
    sta $d011                   // set screen mode
    lda #$06
    sta $d020                   // border color
    sta $d021                   // background color

    cli                         // enable interrupts
    jmp *

// ----- First IRQ: prepare stable sync -----
irq1:
    pha
    txa 
    pha
    tya
    pha

    lda #RASTER_LINE - 1
    sta $d012                   // set raster one line before
    lda $d011
    and #%01111111
    sta $d011

    lda #<irq2
    sta $0314
    lda #>irq2
    sta $0315

    lda #$01
    sta $d019                   // acknowledge raster IRQ

    pla 
    tay
    pla
    tax
    pla
    rti

// ----- Second IRQ: stabilized timing -----
irq2:
    pha
    txa 
    pha
    tya
    pha

waitLine:
    lda $d011
    bpl waitLine               // wait for bit 7 set (start of next line)

    ldx #8                      // fine-tune alignment
delay:
    dex
    bne delay

    // --- Your stable raster effect code here ---
    inc $d020                   // flicker border color for testing

    // --- Reset raster IRQ for next frame ---
    lda #RASTER_LINE
    sta $d012
    lda $d011
    and #%01111111
    ora #(RASTER_LINE >> 1) & $80
    sta $d011

    lda #<irq1
    sta $0314
    lda #>irq1
    sta $0315

    lda #$01
    sta $d019                   // acknowledge raster IRQ

    pla
    tay
    pla
    tax
    pla
    rti
