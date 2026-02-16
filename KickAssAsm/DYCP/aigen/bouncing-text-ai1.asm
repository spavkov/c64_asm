// Bouncing text banner (simple DYCP-like vertical sine) - KickAssembler
// No illegal opcodes; updates once per frame by polling raster.
// Each character gets a phase offset so the banner forms a smooth wave.

BasicUpstart2(start)

.const SCREEN   = $0400
.const COLORRAM = $d800
.const MSG      = message
.const MSGLEN   = messageEnd - message

.const BASE_ROW = 11          // central row (0-24)
.const AMP      = 6           // vertical amplitude (rows)
.const START_COL = (40 - MSGLEN)/2

// Zero page variables
.const phase    = $fb
.const tmp      = $fc
.const tmp2     = $fd
.const ptrLo    = $fe
.const ptrHi    = $ff

.const PI = 3.141592653589793

start:
	sei
	lda #$35
	sta $01

	// Border / background
	lda #0
	sta $d020
	lda #$06
	sta $d021

	// Fill screen with spaces
	lda #$20
	ldx #0
clearLoop:
	sta SCREEN,x
	sta SCREEN+250,x
	sta SCREEN+500,x
	sta SCREEN+750,x
	inx
	cpx #250
	bne clearLoop

	// Init color RAM (light blue)
	lda #$0e
	ldx #0
clrColorLoop:
	sta COLORRAM,x
	sta COLORRAM+250,x
	sta COLORRAM+500,x
	sta COLORRAM+750,x
	inx
	cpx #250
	bne clrColorLoop

	lda #0
	sta phase

mainLoop:
	// Wait for raster wrap to avoid tearing
waitFF1:
	lda $d012
	cmp #$ff
	bne waitFF1
waitFF2:
	lda $d012
	cmp #$ff
	beq waitFF2

	// Clear full screen (simple, not optimal but fine for demo)
	jsr clearScreen

	// Draw bouncing text
	ldx #0
drawChars:
	lda phase
	clc
	adc charPhaseStep,x
	tay
	lda sineTab,y        // 0..2*AMP
	clc
	adc #(BASE_ROW - AMP)
	tay                  // Y=row
	lda rowLo,y
	sta ptrLo
	lda rowHi,y
	sta ptrHi            // ptr -> screen row

	txa                  // X -> A
	clc
	adc #START_COL       // column = START_COL + X
	tay                  // Y=column
	lda message,x
	sta (ptrLo),y

	// Derive color pointer from screen pointer
	sec
	lda ptrLo
	sbc #<SCREEN
	sta tmp
	lda ptrHi
	sbc #>SCREEN
	sta tmp2             // tmp: offset from screen base
	clc
	lda #<COLORRAM
	adc tmp
	sta ptrLo
	lda #>COLORRAM
	adc tmp2
	sta ptrHi
	lda colorTab,x
	sta (ptrLo),y

	inx
	cpx #MSGLEN
	bne drawChars

	inc phase
	jmp mainLoop

// Clear screen subroutine
clearScreen:
	lda #$20
	ldx #0
clLoop2:
	sta SCREEN,x
	sta SCREEN+250,x
	sta SCREEN+500,x
	sta SCREEN+750,x
	inx
	cpx #250
	bne clLoop2
	rts

// Phase offset per character (linear step)
charPhaseStep:
	.fill MSGLEN, i*8

// Sine table scaled to (AMP*2)+1 values (0..12 for AMP=6)
sineTab:
	.fill 256, ( (sin(i*2*PI/256)*AMP) + AMP ) & 255

// Color per character
colorTab:
	.fill MSGLEN, ($01 + (i & $0f)) & $0f

// Message (use uppercase PETSCII)
message:
	.text "BOUNCY TEXT DEMO!"
messageEnd:

// Row address lookup tables for $0400 screen
rowLo:
	.fill 25, <(SCREEN + i*40)
rowHi:
	.fill 25, >(SCREEN + i*40)

// (Removed bannerArea; using full screen clear each frame)

