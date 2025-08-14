BasicUpstart2(start)

// Simplest Snake (WASD), KickAssembler, text screen at $0400
// - Use GETIN ($FFE4) for keyboard (non-blocking)
// - Snake grows on food, wraps at edges; end on self-collision

.const SCREEN   = $0400
.const COLORRAM = $d800
.const GREEN    = $05
.const RED      = $02
.const YELLOW   = $07
.const SPACE    = $20
.const SNAKECHR = $4f         // 'O' screen code for uppercase (15), but PETSCII write not used
.const FOODCHR  = $51         // 'Q' screen code (17)

.const WIDTH    = 40
.const HEIGHT   = 25
.const MAXLEN   = 128         // ring buffer size (power of two)
.const MASK     = MAXLEN-1

// ZP pointers
.const PTR      = $fb         // PTR, PTR+1
.const CPTR     = $fd         // CPTR, CPTR+1

* = $080d "Snake"

start:
	// Clear screen and set default color
	ldx #0
clrLoop:
	lda #SPACE
	sta SCREEN,x
	sta SCREEN+256,x
	sta SCREEN+512,x
	sta SCREEN+768,x
	lda #YELLOW
	sta COLORRAM,x
	sta COLORRAM+256,x
	sta COLORRAM+512,x
	sta COLORRAM+768,x
	inx
	bne clrLoop

	// Build line address tables
	ldx #0
makelines:
	lda #<SCREEN
	sta lineLo,x
	lda #>SCREEN
	sta lineHi,x
	lda #<COLORRAM
	sta colLo,x
	lda #>COLORRAM
	sta colHi,x
	// add 40 to each base per row
	lda #<SCREEN
	clc
	adc mul40lo,x
	sta lineLo,x
	lda #>SCREEN
	adc mul40hi,x
	sta lineHi,x
	lda #<COLORRAM
	clc
	adc mul40lo,x
	sta colLo,x
	lda #>COLORRAM
	adc mul40hi,x
	sta colHi,x
	inx
	cpx #HEIGHT
	bcc makelines

	// Init snake in center
	lda #20
	sta headX
	lda #12
	sta headY
	lda #1              // dx=1, dy=0
	sta dirX
	lda #0
	sta dirY
	lda #4
	sta length
	lda #0
	sta headIdx
	// Seed RNG
	lda #$a5
	sta seed

	// Fill initial body to the left of head
	ldx #0
initBody:
	lda headX
	sec
	sbc #3
	clc
	adc xToAdd,x        // 0,1,2,3
	sta posX,x
	lda headY
	sta posY,x
	inx
	cpx length
	bcc initBody
	lda length
	sec
	sbc #1
	sta headIdx         // head at last inserted index
	// Place first food
	jsr placeFood

	// Enable IRQs for KERNAL keyboard to work
	cli

mainLoop:
	// Wait for one frame (raster 0 cross)
w0: lda $d012
	bne w0
w1: lda $d012
	beq w1

	// Read key (GETIN). A=0 if none.
	jsr $ffe4
	beq noKey
	cmp #'w'
	bne key_not_w
	jmp setUp
key_not_w:
	cmp #'W'
	bne key_not_W
	jmp setUp
key_not_W:
	cmp #'s'
	bne key_not_s
	jmp setDown
key_not_s:
	cmp #'S'
	bne key_not_S
	jmp setDown
key_not_S:
	cmp #'a'
	bne key_not_a
	jmp setLeft
key_not_a:
	cmp #'A'
	bne key_not_A
	jmp setLeft
key_not_A:
	cmp #'d'
	bne key_not_d
	jmp setRight
key_not_d:
	cmp #'D'
	bne noKey
	jmp setRight
noKey:

	// Move every tick (1 per frame here; adjust by skipping frames if needed)
	jsr stepSnake
	bcc doGameOver       // C=0 -> collision
	jmp mainLoop

doGameOver:
	jmp gameOver

// Direction setters (prevent reversing directly)
setUp:
	lda dirY
	bne mainLoop         // already vertical
	lda #-1
	sta dirY
	lda #0
	sta dirX
	jmp mainLoop
setDown:
	lda dirY
	bne mainLoop
	lda #1
	sta dirY
	lda #0
	sta dirX
	jmp mainLoop
setLeft:
	lda dirX
	bne mainLoop
	lda #-1
	sta dirX
	lda #0
	sta dirY
	jmp mainLoop
setRight:
	lda dirX
	bne mainLoop
	lda #1
	sta dirX
	lda #0
	sta dirY
	jmp mainLoop

// stepSnake: advances snake, draws head, erases tail if needed
// Returns C=1 ok, C=0 collision
stepSnake:
	// compute new head = wrap(head + dir)
	lda headX
	clc
	adc dirX
	tay                     // Y=newX candidate (signed)
	bpl newx_nonneg         // if >=0 ok
	lda #WIDTH-1
	tay
newx_nonneg:
	cpy #WIDTH
	bcc newx_done
	ldy #0
newx_done:
	sty newX

	lda headY
	clc
	adc dirY
	tay
	bpl newy_nonneg
	lda #HEIGHT-1
	tay
newy_nonneg:
	cpy #HEIGHT
	bcc newy_done
	ldy #0
newy_done:
	sty newY

	// Self collision check: compare against length-1 body segments
	ldx #0
	lda length
	beq noBody
	dex                     // X=$ff -> will start at 0 in loop body
selfLoop:
	inx
	cpx length
	bcs doneCheck
	// idx = (headIdx - X) & MASK for older segments
	txa                     // A = X
	eor #$ff                // A = -X - 1
	clc
	adc headIdx             // A = headIdx - X - 1
	adc #1                  // A = headIdx - X
	and #MASK
	tay
	lda posX,y
	cmp newX
	bne selfLoop
	lda posY,y
	cmp newY
	bne selfLoop
	clc                     // collision
	rts
doneCheck:
noBody:

	// Did we eat food?
	lda newX
	cmp foodX
	bne noEat
	lda newY
	cmp foodY
	bne noEat
	// grow by 1 (up to MAX)
	lda length
	cmp #MAXLEN
	bcs len_nogrow
	clc
	adc #1
	sta length
len_nogrow:
	jsr placeFood
	jmp placeDraw           // continue to draw
noEat:
	// erase tail
	lda headIdx
	sec
	sbc length
	and #MASK
	tax
	lda posX,x
	sta tmpX
	lda posY,x
	sta tmpY
	lda #SPACE
	jsr plotChar

placeDraw:
	// write new head into ring
	lda headIdx
	clc
	adc #1
	and #MASK
	sta headIdx
	tax
	lda newX
	sta posX,x
	lda newY
	sta posY,x
	lda newX
	sta headX
	lda newY
	sta headY
	// draw head
	lda #'O'
	jsr plotCharGreen
	sec
	rts

gameOver:
	// Flash border and stop
	lda #2
	sta $d020
	lda #0
	sta $d020
	jmp gameOver

// plotChar: A=char, uses tmpX/tmpY
plotChar:
	sta tmpC
	ldy tmpY
	lda lineLo,y
	sta PTR
	lda lineHi,y
	sta PTR+1
	ldy tmpX
	lda tmpC
	sta (PTR),y
	rts

// plotCharGreen: A=char on GREEN color
plotCharGreen:
	sta tmpC
	ldy tmpY
	lda lineLo,y
	sta PTR
	lda lineHi,y
	sta PTR+1
	ldy tmpX
	lda tmpC
	sta (PTR),y
	lda colLo,y
	sta CPTR
	lda colHi,y
	sta CPTR+1
	ldy tmpX
	lda #GREEN
	sta (CPTR),y
	rts

// placeFood: picks a pseudo-random empty cell, draws FOOD
placeFood:
	jsr nextRand
	lda seed
	and #$1f                // 0..31
	clc
	adc #4                  // avoid extreme edges
	sta foodX
	jsr nextRand
	lda seed
	and #$0f
	clc
	adc #4
	sta foodY
	// Ensure not on snake (simple check; if collides, just move next frame)
	lda #'Q'
	lda foodX
	sta tmpX
	lda foodY
	sta tmpY
	lda #'Q'
	jsr plotFood
	rts

plotFood:
	sta tmpC
	ldy tmpY
	lda lineLo,y
	sta PTR
	lda lineHi,y
	sta PTR+1
	ldy tmpX
	lda tmpC
	sta (PTR),y
	lda colLo,y
	sta CPTR
	lda colHi,y
	sta CPTR+1
	ldy tmpX
	lda #RED
	sta (CPTR),y
	rts

// x-add table 0..3
xToAdd:
	.byte 0,1,2,3

// Multiply row by 40 via tables
mul40lo:
	.for (var i=0;i<HEIGHT;i++) { .byte <(i*40) }
mul40hi:
	.for (var i=0;i<HEIGHT;i++) { .byte >(i*40) }

// Screen line address tables
lineLo: .fill HEIGHT, 0
lineHi: .fill HEIGHT, 0
colLo:  .fill HEIGHT, 0
colHi:  .fill HEIGHT, 0

// RNG: Xorshift-like
nextRand:
	lda seed
	asl
	bcc rand_done
	eor #$1d
rand_done:
	sta seed
	rts

// --- Vars ---
headX:   .byte 0
headY:   .byte 0
dirX:    .byte 0
dirY:    .byte 0
length:  .byte 0
headIdx: .byte 0
newX:    .byte 0
newY:    .byte 0
tmpX:    .byte 0
tmpY:    .byte 0
tmpC:    .byte 0
foodX:   .byte 0
foodY:   .byte 0
seed:    .byte 0

// Ring buffers
posX: .fill MAXLEN, 0
posY: .fill MAXLEN, 0
