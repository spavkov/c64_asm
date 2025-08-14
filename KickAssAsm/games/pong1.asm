BasicUpstart2(start)

// Minimal two-player Pong-like game (KickAssembler)
// - Left paddle: W (up), S (down)
// - Right paddle: I (up), K (down)
// - Sprites: 0=left paddle, 1=right paddle, 2=ball
// - Simple collisions and screen bounces

.const BLACK = $00
.const WHITE = $01
.const RED   = $02
.const CYAN  = $03

// CIA1 keyboard matrix scanning
// Keys (row,col): W=(1,1) S=(1,5) I=(4,1) K=(4,5)
.const ROW_W = 1
.const COL_W = 1
.const ROW_S = 1
.const COL_S = 5
.const ROW_I = 4
.const COL_I = 1
.const ROW_K = 4
.const COL_K = 5

.const SPR0_X = 30        // left paddle X
.const SPR1_X = 284       // right paddle X (needs MSB in $D010)
.const BALL_START_X = 160
.const BALL_START_Y = 120
.const PADDLE_SPEED = 3
.const BALL_SPEED   = 2
.const TOP_LIMIT    = 40   // clamp paddles inside visible area
.const BOT_LIMIT    = 230

* = $080d "Pong"

start:
	sei
	lda #$35
	sta $01                   // RAM under I/O/KERNAL

	// VIC bank left at default (bank 0: $0000-$3FFF)

	// Disable KERNAL/CIA IRQ side-effects
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d

	// Screen colors
	lda #BLACK
	sta $d020
	sta $d021

	// Set single-color sprites
	lda #$00
	sta $d01c                 // sprite multicolor off

	// Sprite pointers computed from sprite labels (must be 64-byte aligned)
	lda #<(paddleSprite/$40)
	sta $07f8                 // sprite 0
	lda #<(rightPaddleSprite/$40)
	sta $07f9                 // sprite 1
	lda #<(ballSprite/$40)
	sta $07fa                 // sprite 2

	// Sprite colors
	lda #WHITE
	sta $d027                 // spr0 color
	lda #WHITE
	sta $d028                 // spr1 color
	lda #CYAN
	sta $d029                 // ball color

	// Enable sprites 0,1,2
	lda #%00000111
	sta $d015

	// Initial positions
	lda #<SPR0_X
	sta $d000                 // spr0 X
	lda #100
	sta $d001                 // spr0 Y

	lda #<SPR1_X
	sta $d002                 // spr1 X low
	lda #100
	sta $d003                 // spr1 Y
	lda $d010
	ora #%00000010            // spr1 X MSB
	sta $d010

	lda #<BALL_START_X
	sta $d004                 // ball X
	lda #BALL_START_Y
	sta $d005                 // ball Y
	lda $d010
	and #%11111011            // ball X MSB = 0
	sta $d010

	// Init variables
	lda #100
	sta leftY
	sta rightY
	lda #<BALL_START_X
	sta ballX
	lda #BALL_START_Y
	sta ballY
	lda #BALL_SPEED
	sta ballDX
	sta ballDY

	// Setup CIA for keyboard scan: Port A out, Port B in
	lda #$ff
	sta $dc02                 // DDRA = all outputs
	lda #$00
	sta $dc03                 // DDRB = all inputs

mainLoop:
	// Wait for start of frame (raster line 0)
wait0: lda $d012
	bne wait0
wait1: lda $d012
	beq wait1

	// Scan keyboard: W/S for left, I/K for right
	jsr readKeys
	// Update paddles
	lda key_up_left
	beq ml1
	jsr paddleLeftUp
ml1:
	lda key_down_left
	beq ml2
	jsr paddleLeftDown
ml2:
	lda key_up_right
	beq ml3
	jsr paddleRightUp
ml3:
	lda key_down_right
	beq ml4
	jsr paddleRightDown
ml4:
	// Update ball
	jsr updateBall

	// Draw sprites at positions
	jsr drawSprites

	jmp mainLoop

// --- Routines ---

// readKeys: sets key flags for W,S,I,K
readKeys:
	// Clear flags
	lda #0
	sta key_up_left
	sta key_down_left
	sta key_up_right
	sta key_down_right

	// Check column COL_W (and COL_I)
	lda #($ff ^ (1<<COL_W))
	sta $dc00
	lda $dc01
	// W = row 1 (bit1 == 0)
	bitMask(ROW_W)
	bne rk1
	lda #1
	sta key_up_left
rk1:
	// I = row 4 (bit4 == 0)
	lda $dc01
	bitMask(ROW_I)
	bne rk2
	lda #1
	sta key_up_right
rk2:
	// Check column COL_S (and COL_K)
	lda #($ff ^ (1<<COL_S))
	sta $dc00
	lda $dc01
	// S = row1
	bitMask(ROW_S)
	bne rk3
	lda #1
	sta key_down_left
rk3:
	// K = row4
	lda $dc01
	bitMask(ROW_K)
	bne rk4
	lda #1
	sta key_down_right
rk4:
	rts

// Helper macro: set Z if row bit is 0 (pressed). Here we just keep value and branch on nonzero.
.macro bitMask(row) {
	// A currently holds $dc01
	and #(1<<row)
}

paddleLeftUp:
	lda leftY
	sec
	sbc #PADDLE_SPEED
	bcs plup1
	lda #0

plup1:
	cmp #TOP_LIMIT
	bcs plup2
	lda #TOP_LIMIT

plup2:
	sta leftY
	rts

paddleLeftDown:
	lda leftY
	clc
	adc #PADDLE_SPEED
	cmp #BOT_LIMIT
	bcc pld1
	lda #BOT_LIMIT

pld1:
	sta leftY
	rts

paddleRightUp:
	lda rightY
	sec
	sbc #PADDLE_SPEED
	bcs pru1
	lda #0

pru1:
	cmp #TOP_LIMIT
	bcs pru2
	lda #TOP_LIMIT

pru2:
	sta rightY
	rts

paddleRightDown:
	lda rightY
	clc
	adc #PADDLE_SPEED
	cmp #BOT_LIMIT
	bcc prd1
	lda #BOT_LIMIT

prd1:
	sta rightY
	rts

updateBall:
	// X
	lda ballX
	clc
	adc ballDX
	sta ballX
	// Y
	lda ballY
	clc
	adc ballDY
	sta ballY

	// Bounce top/bottom
	lda ballY
	cmp #TOP_LIMIT
	bcs ub1
	jsr invertDY
	lda #TOP_LIMIT
	sta ballY
ub1:
	lda ballY
	cmp #BOT_LIMIT
	bcc ub2
	jsr invertDY
	lda #BOT_LIMIT
	sta ballY
ub2:
	// Paddle collisions (simple AABB thresholds)
	// Left paddle: if ballX <= SPR0_X+10 and Y overlaps paddle
	lda ballX
	cmp #(SPR0_X+10)
	bcs chkRight
	jsr yOverlapLeft
	beq chkRight
	jsr invertDX
chkRight:
	// Right paddle: if ballX >= SPR1_X-10
	lda ballX
	cmp #(SPR1_X-10)
	bcc doneCol
	jsr yOverlapRight
	beq doneCol
	jsr invertDX
doneCol:
	rts

invertDX:
	lda ballDX
	eor #$ff
	clc
	adc #1
	sta ballDX
	rts

invertDY:
	lda ballDY
	eor #$ff
	clc
	adc #1
	sta ballDY
	rts

// Returns Z=1 if no overlap; Z=0 if overlap (A set to 1)
yOverlapLeft:
	lda ballY
	sec
	sbc leftY
	cmp #21
	bcs noLeft
	lda #1
	rts
noLeft:
	lda #0
	rts

yOverlapRight:
	lda ballY
	sec
	sbc rightY
	cmp #21
	bcs noRight
	lda #1
	rts
noRight:
	lda #0
	rts

drawSprites:
	// left paddle
	lda #<SPR0_X
	sta $d000
	lda leftY
	sta $d001
	// right paddle
	lda #<SPR1_X
	sta $d002
	lda rightY
	sta $d003
	// ensure MSBs
	lda $d010
	ora #%00000010
	and #%11111011           // ball msb 0
	sta $d010
	// ball
	lda ballX
	sta $d004
	lda ballY
	sta $d005
	rts

// --- Data --- (inline sprites, 64-byte aligned)

.align $40

// Paddle sprite: thin vertical bar in the middle
paddleSprite:
	.for (var r=0; r<21; r++) {
		.byte %00000000, %00011000, %00000000
	}
	.fill (64 - 63), 0

// Right paddle sprite (reuse same data)
rightPaddleSprite:
	.for (var r=0; r<21; r++) {
		.byte %00000000, %00011000, %00000000
	}
	.fill (64 - 63), 0

// Ball sprite: small 6x6 block centered
ballSprite:
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.fill (64 - 63), 0
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00011100, %00000000
	.byte %00000000, %00111110, %00000000
	.byte %00000000, %00111110, %00000000
	.byte %00000000, %00011100, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000
	.byte %00000000, %00000000, %00000000

// Sprite pointers are set at runtime in start()

// --- Variables ---
// Variables follow in the same contiguous block
leftY:           .byte 0
rightY:          .byte 0
ballX:           .byte 0
ballY:           .byte 0
ballDX:          .byte 0
ballDY:          .byte 0
key_up_left:     .byte 0
key_down_left:   .byte 0
key_up_right:    .byte 0
key_down_right:  .byte 0

