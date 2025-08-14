BasicUpstart2(start)

// Simple smooth horizontal text scroller (KickAssembler)
// - Uses default ROM charset and screen at $0400
// - Scrolls one row left with $d016 fine scroll; every 8 steps shifts chars

.const SCREEN   = $0400
.const COLORRAM = $d800
.const WHITE    = $01
.const SPACE    = $20
.const ROW      = 12                 // row to scroll (0..24)
.const ROW_ADDR = SCREEN + ROW*40
.const COL_ADDR = COLORRAM + ROW*40


start:
	sei
	lda #$35
	sta $01                     // keep IO visible

	// 38-column mode for clean edges; X fine scroll starts at 7 (scroll left)
	lda #$1b
	sta $d011
	lda #($08 | 7)              // bit3=1 (38 cols), xscroll=7
	sta $d016

	// Clear entire screen and set default color
	ldx #0
clearScreen:
	lda #SPACE
	sta SCREEN,x
	sta SCREEN+256,x
	sta SCREEN+512,x
	sta SCREEN+768,x
	lda #WHITE
	sta COLORRAM,x
	sta COLORRAM+256,x
	sta COLORRAM+512,x
	sta COLORRAM+768,x
	inx
	bne clearScreen

	lda #7
	sta xscr
	lda #0
	sta msgIdx

mainLoop:
	// Wait for vblank
v0: lda $d012
	bne v0
v1: lda $d012
	beq v1

	// Fine scroll left: xscr -> xscr-1; when wraps, shift chars and reset to 7
	lda xscr
	beq doShift
	sec
	sbc #1
	sta xscr
updateScroll:
	lda xscr
	ora #$08
	sta $d016
	jmp mainLoop

doShift:
	// shift 39 chars left
	ldx #0
shiftLoop:
	lda ROW_ADDR+1,x
	sta ROW_ADDR+0,x
	inx
	cpx #39
	bcc shiftLoop

	// insert next char at rightmost column (x=39)
	jsr nextChar
	sta ROW_ADDR+39
	lda #WHITE
	sta COL_ADDR+39
	lda #7
	sta xscr
	jmp updateScroll

// nextChar -> A = next screen code (from uppercase ASCII message)
nextChar:
	ldx msgIdx
	lda message,x
	bne nc1
	ldx #0
	stx msgIdx
	lda message
nc1:
	inx
	stx msgIdx
	cmp #SPACE
	beq retSpace
	sec
	sbc #$40                 // 'A'(65) -> 1 screen code
	rts
retSpace:
	lda #SPACE
	rts

// --- Data/vars ---
message:
	.text "    HELLO WORLD FROM C64 SMOOTH SCROLLER DEMO                                "
	.byte 0

xscr:   .byte 0
msgIdx: .byte 0
