BasicUpstart2(start)

// Stable raster bar that moves down the screen and wraps to the top:
// - Uses double pre-IRQs (one line before each edge) + line-change wait
//   to eliminate horizontal tearing / jitter.
// - Sets border RED at the current barTop scanline
// - Sets border BLACK ROW_HEIGHT lines later
// - Increments barTop each frame; wraps from bottom back to top

// --- Constants (PAL defaults) ---
.const BLACK = $00
.const RED   = $02

// PAL first visible scanline is ~$30. If NTSC, use $20 instead.
.const RASTER_BASE   = $30        // change to $20 for NTSC
.const D011VAL       = $1b        // normal text, y-scroll = 3
.const RASTER_MIN    = RASTER_BASE + (D011VAL & $07) // first character row top
.const RASTER_MAX    = $e0        // last safe top line (so +8 stays <=255)
.const ROW_HEIGHT    = 16

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

		// Install unified pre-edge IRQ (line before first ON edge)
		lda #<irq_edge_pre
		sta $fffe
		lda #>irq_edge_pre
		sta $ffff
		lda #0
		sta edgeState              // 0 = next edge is ON, 1 = OFF
		lda barTop
		sec
		sbc #1
		sta $d012                  // pre line for first ON edge

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

// Unified pre-edge IRQ: fires the line BEFORE the target (either ON or OFF edge).
// It waits until the target line arrives (stable) then toggles the color and schedules
// the next pre-edge IRQ.
irq_edge_pre:
	lda #$ff
	sta $d019                   // ACK raster IRQ

	// Decide which edge: edgeState 0 = ON, 1 = OFF
	lda edgeState
	beq !doOnCalc+
	// OFF edge target = barTop + ROW_HEIGHT
	lda barTop
	clc
	adc #ROW_HEIGHT
	bne !haveTarget+            // always taken
!doOnCalc:
	lda barTop                  // ON edge target = barTop
!haveTarget:
	sta currentTarget

	// Wait for target line
wait:
	lda currentTarget
	cmp $d012
	bne wait

	// We are a few fixed cycles into the target line – toggle color.
	lda edgeState
	bne !doOff+
	// ON edge: set bar color
	lda #RED
	sta $d020
	sta $d021
	lda #1
	sta edgeState               // next edge = OFF
	jmp !schedule+
!doOff:
	lda #BLACK
	sta $d020
	sta $d021
	// Advance barTop
	lda barTop
	clc
	adc #1
	cmp #RASTER_MAX+1
	bcc !store+
	lda #RASTER_MIN
!store:
	sta barTop
	lda #0
	sta edgeState               // next edge = ON
!schedule:
	// Compute next pre-edge line = (nextEdgeTarget) -1
	lda edgeState
	beq !nextOn+
	// next OFF target = barTop + ROW_HEIGHT
	lda barTop
	clc
	adc #ROW_HEIGHT
	bne !sub1+                  // always
!nextOn:
	lda barTop
!sub1:
	sec
	sbc #1
	sta $d012                   // pre line for next edge
	// Keep vector pointing here
	lda #<irq_edge_pre
	sta $fffe
	lda #>irq_edge_pre
	sta $ffff
	rti

// --- Variables ---
barTop: .byte 0
edgeState: .byte 0
currentTarget: .byte 0

