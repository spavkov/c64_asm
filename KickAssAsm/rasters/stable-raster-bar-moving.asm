BasicUpstart2(start)

// Stable raster bar that moves down the screen and wraps to the top:
// - Sets border RED at the current barTop scanline
// - Sets border BLACK 8 lines later
// - Increments barTop each frame; wraps from bottom back to top

// --- Constants (PAL defaults) ---
.const BLACK = $00
.const RED   = $02

// PAL first visible scanline is ~$30. If NTSC, use $20 instead.
.const RASTER_BASE   = $30        // change to $20 for NTSC
.const D011VAL       = $1b        // normal text, y-scroll = 3
.const RASTER_MIN    = RASTER_BASE + (D011VAL & $07) // first character row top
.const RASTER_MAX    = $f7        // last safe top line (so +8 stays <=255)
.const ROW_HEIGHT    = 8

* = $4000 "Stable Raster Demo"

start:
	sei
	lda #$35
	sta $01                     // map: RAM under I/O/KERNAL for safety

	lda #BLACK
	sta $d020                   // border = black
	sta $d021                   // background = black

	lda #D011VAL
	sta $d011                   // set y-scroll and mode (DEN on)

	// Initialize moving bar
	lda #RASTER_MIN
	sta barTop

	// Install pre-IRQ (line before current barTop)
	lda #<irq_pre
	sta $fffe
	lda #>irq_pre
	sta $ffff
	lda barTop
	sec
	sbc #1
	sta $d012

	// Enable raster IRQs and disable/ack CIA interrupts
	lda #$81
	sta $d01a
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d
	lda #$ff
	sta $d019                   // ack any pending VIC IRQ

	cli
	jmp *

// Pre-IRQ: arms the main IRQ at barTop
irq_pre:
	lda #$ff
	sta $d019                   // ACK raster IRQ
	lda barTop
	sta $d012                   // next IRQ at barTop
	lda #<irq_row1
	sta $fffe
	lda #>irq_row1
	sta $ffff
	rti

// Main IRQ #1: left edge of barTop → set border to RED
irq_row1:
	lda #$ff
	sta $d019                   // ACK raster IRQ
	lda #RED
	sta $d020                   // border = red (as early as possible)
	lda barTop
	clc
	adc #ROW_HEIGHT
	sta $d012                   // schedule second edge at barTop+8
	lda #<irq_row2
	sta $fffe
	lda #>irq_row2
	sta $ffff
	rti

// Main IRQ #2: left edge at barTop+8 → set border back to BLACK and advance
irq_row2:
	lda #$ff
	sta $d019                   // ACK raster IRQ
	lda #BLACK
	sta $d020                   // border = black
	// Advance barTop (wrap to RASTER_MIN after RASTER_MAX)
	lda barTop
	clc
	adc #1
	cmp #RASTER_MAX+1
	bcc !storeTop+
	lda #RASTER_MIN
!storeTop:
	sta barTop

	// Re-arm pre-IRQ on barTop-1 for next frame
	sec
	sbc #1
	sta $d012
	lda #<irq_pre
	sta $fffe
	lda #>irq_pre
	sta $ffff
	rti

// --- Variables ---
barTop: .byte 0

