BasicUpstart2(start)

// Simple smooth horizontal text scroller (KickAssembler)
// - Uses default ROM charset and screen at $0400
// - Scrolls one row left with $d016 fine scroll; every 8 steps shifts chars

.const SCREEN   = $0400
.const COLORRAM = $d800
.const WHITE    = $01
.const BLACK    = $00
.const BLUE     = $02
.const SPACE    = $20
.const ROW      = 12                 // row to scroll (0..24)
.const ROW_ADDR = SCREEN + ROW*40
.const COL_ADDR = COLORRAM + ROW*40
.const RASTER_LINE = $30             // raster line for IRQ (PAL). Use $20 for NTSC
.const PRE_LINE = RASTER_LINE - 1    // pre-IRQ one line earlier


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

	// Prefill scroll row with initial message so it shows immediately
	ldx #0
prefill:
	jsr nextChar
	sta ROW_ADDR,x
	lda #WHITE
	sta COL_ADDR,x
	inx
	cpx #40
	bcc prefill
	lda #0
	sta frameTick

	// Install stable raster (double-IRQ): pre-IRQ at PRE_LINE, main IRQ at RASTER_LINE
	lda #<irq_pre
	sta $fffe
	lda #>irq_pre
	sta $ffff
	lda #PRE_LINE
	sta $d012                 // pre-IRQ line
	lda #$1b
	sta $d011                 // ensure high raster bit = 0
	lda #$01
	sta $d01a                 // enable raster IRQ only
	lda #$7f
	sta $dc0d                 // disable CIA IRQs
	sta $dd0d
	lda $dc0d                 // clear any pending
	lda $dd0d
	lda #$ff
	sta $d019                 // ACK any pending VIC IRQs
	cli

mainLoop:
	// Nothing to do here; IRQ performs the scroll update
	jmp mainLoop

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

// Stable raster IRQs
// Pre-IRQ: arm main IRQ at exact target line
irq_pre:
	pha
	txa
	pha
	tya
	pha

	lda #$ff
	sta $d019            // ACK any VIC IRQ flags (raster bit included)

	lda #BLUE
	sta $d020

	// Arm main IRQ at target line
	lda #RASTER_LINE
	sta $d012
	lda #<irq_main
	sta $fffe
	lda #>irq_main
	sta $ffff

	pla
	tay
	pla
	tax
	pla
	rti

// Main IRQ: perform scroll step at stable timing, then re-arm pre-IRQ
irq_main:
	pha
	txa
	pha
	tya
	pha

	lda #$ff
	sta $d019            // ACK any VIC IRQ flags (raster bit included)

	lda #BLACK
	sta $d020          // set border color (as early as possible)

	// Fine scroll step in IRQ for stable timing (left edge)
	lda xscr
	bne irq_dec
	// wrap: shift row and reset xscr to 7
	jsr shiftRow
	lda #7
	sta xscr
	bne irq_update       // always
irq_dec:
	sec
	sbc #1
	sta xscr
irq_update:
	lda xscr
	ora #$08
	sta $d016

	// Re-arm pre-IRQ for next frame
	lda #PRE_LINE
	sta $d012
	lda #<irq_pre
	sta $fffe
	lda #>irq_pre
	sta $ffff

	pla
	tay
	pla
	tax
	pla
	rti

// Shift row left by 1 and insert next char on the right
shiftRow:
	ldx #0
sr_loop:
	lda ROW_ADDR+1,x
	sta ROW_ADDR+0,x
	inx
	cpx #39
	bcc sr_loop
	jsr nextChar
	sta ROW_ADDR+39
	lda #WHITE
	sta COL_ADDR+39
	rts

// --- Data/vars ---
message:
	.text "                                            HELLO WORLD FROM C64 SMOOTH SCROLLER DEMO                                "
	.byte 0

xscr:   .byte 0
msgIdx: .byte 0
frameTick: .byte 0
