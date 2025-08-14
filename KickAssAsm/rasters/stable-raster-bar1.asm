BasicUpstart2(start)

// Minimal stable raster: set border RED on first character row,
// then set border BLACK on second character row.

// --- Constants (PAL defaults) ---
.const BLACK = $00
.const RED   = $02

// PAL first visible scanline is ~$30. If NTSC, use $20 instead.
.const RASTER_BASE   = $30        // change to $20 for NTSC
.const D011VAL       = $1b        // normal text, y-scroll = 3
.const RASTER_ROW1   = RASTER_BASE + (D011VAL & $07) // first character row top
.const RASTER_ROW2   = RASTER_ROW1 + 8               // next character row top
.const RASTER_PRE    = RASTER_ROW1 - 1               // pre-IRQ one line before

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

	// Install pre-IRQ (line before first row)
	lda #<irq_pre
	sta $fffe
	lda #>irq_pre
	sta $ffff
	lda #RASTER_PRE
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

// Pre-IRQ: arms the main IRQ at the exact first character row
irq_pre:
	lda #$ff
	sta $d019                   // ACK raster IRQ
	lda #RASTER_ROW1
	sta $d012                   // next IRQ at first row
	lda #<irq_row1
	sta $fffe
	lda #>irq_row1
	sta $ffff
	rti

// Main IRQ #1: left edge of first character row → set border to RED
irq_row1:
	lda #$ff
	sta $d019                   // ACK raster IRQ
	lda #RED
	sta $d020                   // border = red (as early as possible)
	lda #RASTER_ROW2
	sta $d012                   // schedule second row
	lda #<irq_row2
	sta $fffe
	lda #>irq_row2
	sta $ffff
	rti

// Main IRQ #2: left edge of second character row → set border back to BLACK
irq_row2:
	lda #$ff
	sta $d019                   // ACK raster IRQ
	lda #BLACK
	sta $d020                   // border = black
	lda #RASTER_PRE
	sta $d012                   // re-arm pre-IRQ for next frame
	lda #<irq_pre
	sta $fffe
	lda #>irq_pre
	sta $ffff
	rti

