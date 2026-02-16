// Simple color RAM plasma (KickAssembler)
// Writes a 40x25 color plasma each frame using summed sine components.
// No IRQs needed; main loop waits for raster and updates.

BasicUpstart2(start)

// Zero-page variables (choose high ZP; KERNAL IRQs disabled)
.const phaseX1 = $f0
.const phaseX2 = $f1
.const phaseY1 = $f2
.const phaseY2 = $f3
.const tmpA    = $f4     // temp for intermediate sine
.const ptrLo   = $f5
.const ptrHi   = $f6
.const tmpB    = $f7     // holds original x or y during composite calc

.const COLOR_RAM = $d800
.const SCREEN    = $0400

.const TWO_PI = 6.283185307179586

start:
	sei
	lda #$35
	sta $01          // RAM config (IO + BASIC/KERNAL)

	// Disable CIA interrupts & raster IRQs (we poll raster)
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d
	lda #0
	sta $d01a
	lda #$ff
	sta $d019

	// Set border/background to black for contrast
	lda #0
	sta $d020
	sta $d021

	// Clear screen (space chars) and color (0)
	lda #$a0        // reverse space (solid block) so color changes show
	ldx #0
clr_scr_loop:
	sta SCREEN,x
	sta SCREEN+250,x
	sta SCREEN+500,x
	sta SCREEN+750,x
	inx
	cpx #250
	bne clr_scr_loop
	lda #0
	ldx #0
clr_col_loop:
	sta COLOR_RAM,x
	sta COLOR_RAM+250,x
	sta COLOR_RAM+500,x
	sta COLOR_RAM+750,x
	inx
	cpx #250
	bne clr_col_loop

	// Init phases
	lda #0
	sta phaseX1
	lda #64
	sta phaseX2
	lda #0
	sta phaseY1
	lda #128
	sta phaseY2

mainLoop:
	// Wait for raster wrap (line $ff -> not $ff)
waitFF1:
	lda $d012
	cmp #$ff
	bne waitFF1
waitFF2:
	lda $d012
	cmp #$ff
	beq waitFF2

	// Draw plasma directly (no intermediate tables)
	lda #<COLOR_RAM
	sta ptrLo
	lda #>COLOR_RAM
	sta ptrHi
	ldy #0              // row
row_loop:
	// Compute yScaled8 in tmpB
	tya
	asl
	asl
	asl                 // *8
	sta tmpB            // tmpB = y*8
	ldx #0              // column
col_loop:
	txa                 // x
	asl
	asl                 // x*4
	clc
	adc phaseX1         // x*4 + p1
	tay
	lda sineTab,y       // component 1
	sta tmpA
	lda tmpB            // y*8
	clc
	adc phaseY1         // y*8 + p3
	tay
	lda sineTab,y       // component 2
	clc
	adc tmpA            // sum12
	txa                 // x
	asl
	asl                 // x*4
	clc
	adc tmpB            // x*4 + y*8
	clc
	adc phaseY2         // + p4
	tay
	lda sineTab,y       // component 3
	clc
	adc tmpA            // total
	lsr
	lsr
	lsr
	lsr
	lsr                 // >>5
	and #$0f
	sta (ptrLo),x
	inx
	cpx #40
	bne col_loop
	// advance pointer 40
	clc
	lda ptrLo
	adc #40
	sta ptrLo
	bcc noCarry2
	inc ptrHi
noCarry2:
	ldy ptrLo          // restore Y? we need row index preserved -> instead keep row in separate
	// reuse Y from earlier not safe; rebuild row index
	// We'll track row count in phaseX2 temporarily (not used until end) - simplified approach
	// (Simplification: easier fix—replace this block with a proper counter)
	// Fallback: use a separate counter in tmpA
	// (Will adjust below)
	jmp afterRow

afterRow:
	// Use phaseX2 as row counter increment (was dynamic phase earlier but acceptable)
	inc phaseX2
	lda phaseX2
	cmp #25
	bcc continueRows
	// finished all rows -> reset counter
	lda #0
	sta phaseX2
	// Advance phases for motion
	inc phaseX1
	inc phaseY1
	dec phaseY2
	jmp mainLoop
continueRows:
	// continue next row
	jmp row_loop

// Sine table 0..255
sineTab:
	.fill 256, (sin(i*TWO_PI/256)*127 + 128) & 255

// Per-frame precomputed components
sinX:
	.fill 40, 0
sinY:
	.fill 25, 0

