// sourcecrap [c]2005 HMVDVA/HeMa!
// do what you like with this. print it out and wipe your ass with it :-/
// https://codebase64.org/doku.php?id=base:micropong

.label joystick1		= $dc01
.label joystick2		= $dc00

.label up1			= 254
.label down1		= 253
.label fire1		= 239

.label up2			= 126
.label down2		= 125
.label fire2		= 111

.label gamespeed		= 8

:BasicUpstart2(main)
main:

			sei

			lda #$31
			sta $1
			ldx #0
copyromchar:			
			lda $d000,x
			sta $2000,x
			lda $d100,x
			sta $2100,x
			lda $d200,x
			sta $2200,x
			lda $d300,x
			sta $2300,x
			lda $d400,x
			sta $2400,x
			lda $d500,x
			sta $2500,x
			lda $d600,x
			sta $2600,x
			lda $d700,x
			sta $2700,x
			inx
			bne copyromchar
			
			lda #$37
			sta $1
			
			lda #$0b
			sta $0286
			jsr $e544

			lda #0
			sta $d020
			sta $d021
			sta joystick1pos
			sta joystick2pos
			
			lda #4
			sta ballx
			lda #1
			sta bally
			
			lda #$1b
			sta $d011
			lda #$18
			sta $d018
			
						
			ldy #0
setupchar:			
			lda #0
			sta $2000,y
			iny		
			cpy #8
			bne setupchar
				
			
			lda #160
			ldx #0
clearscreen:			
			sta $0400,x
			sta $0500,x
			sta $0600,x
			sta $0700,x
			inx
			bne clearscreen
			
	//		jsr paddle1control
	//		jsr paddle2control

			lda #15
			sta $d814+(12*40)

			lda #<$2000
			ldy #>$2000
			sta $f0
			sty $f1
			
			lda #$23
			sta $0414+(12*40)
introloop:	

			lda #$fb
poll0:			
			cmp $d012
			bne poll0

			lda joystick1
			cmp #fire1
			beq dogame
			lda joystick2
			cmp #fire2
			beq dogame
			
			lda speedcounter
			beq scrollit
			dec speedcounter
			jmp introloop
scrollit:	
			lda #10
			sta speedcounter			
			clc
			ldx #0
scroll:			
			//clc
			rol $2000+($24*8),x
			rol $2000+($23*8),x
			inx
			cpx #8
			bne scroll
			
			lda scrollcnt
			beq newscrchar
			dec scrollcnt
			jmp introloop
newscrchar:
			lda #7
			sta scrollcnt			
		
stext:
			lda scrolltext
			beq wraptext
			asl
			asl
			asl
			sta copychar+1
			
			ldx #0
copychar:
			lda $2000,x
			sta $2000+($24*8),x
			inx
			cpx #8
			bne copychar
			
			inc stext+1
			jmp introloop			
			
wraptext:
			lda #<scrolltext
			ldy #>scrolltext
			sta stext+1
			sty stext+2
			jmp stext
			
dogame:			
			lda #0
			sta $0414+(12*40)

gameloop:


			lda #$fb
poll1:			
			cmp $d012
			bne poll1
		
			jsr clearchar
			jsr collisiondetect
		
			jsr paddle1control
			jsr paddle2control
			jsr ballmovement
			
			jmp gameloop
			
collisiondetect:
			lda ballx
			beq checkpaddle1
			cmp #7
			beq checkpaddle2
			rts
checkpaddle1:
			lda bally
			sec
			sbc joystick1pos
			cmp #3
			bcs paddle1miss
			
			jmp newdirection
paddle1miss:
			lda #3
			sta ballx
			sta bally
			jmp newdirection
checkpaddle2:
			lda bally
			sec
			sbc joystick2pos
			cmp #3
			bcs paddle2miss
			
			rts		
paddle2miss:
			lda #3
			sta ballx
			sta bally				
			
newdirection:
			jsr randomgenerator
			and #1
			sta $f2
			jsr randomgenerator
			and #1
			sec
			sbc $f2
			beq newdirection
			cmp #2
			beq newdirection
			sta directx
		//	sta $d020
tryyagain:			
			jsr randomgenerator
			and #1
			sta $f2
			jsr randomgenerator
			and #1
			sec
			sbc $f2
	//		beq tryyagain
			sta directy
//			sta $d021
			rts
			
paddle1control:
			lda joystick1
			cmp #up1
			beq joy1up
			cmp #down1
			beq joy1down
			jmp paddle1update
joy1up:
			lda joystick1pos
			beq paddle1update
			dec joystick1pos
			jmp paddle1update
			
joy1down:		
			lda joystick1pos
			cmp #5
			beq paddle1update
			inc joystick1pos
paddle1update:			
			ldy joystick1pos
			lda ($f0),y
			ora #%10000000
			sta ($f0),y
			iny		
			lda ($f0),y
			ora #%10000000
			sta ($f0),y
			iny
			lda ($f0),y
			ora #%10000000
			sta ($f0),y
			
nojoy1change:			
			rts
			
paddle2control:
			lda joystick2
			cmp #up2
			beq joy2up
			cmp #down2
			beq joy2down
			jmp paddle2update
joy2up:
			lda joystick2pos
			beq paddle2update
			dec joystick2pos
			jmp paddle2update
			
joy2down:		
			lda joystick2pos
			cmp #5
			beq paddle2update
			inc joystick2pos
paddle2update:			

			ldy joystick2pos
			lda ($f0),y
			ora #%00000001
			sta ($f0),y
			iny		
			lda ($f0),y
			ora #%00000001
			sta ($f0),y
			iny
			lda ($f0),y
			ora #%00000001
			sta ($f0),y
nojoy2change:			
			rts
			
ballmovement:
			inc speedcounter
			lda speedcounter
			cmp #gamespeed
			bne plotball
			lda #0
			sta speedcounter
forceupdate:			
			lda ballx
			beq chdirtoright
			cmp #7			
			beq chdirtoleft
updateballx:
			clc
			adc directx
			sta ballx
			
			lda bally
			beq chdirdown
			cmp #7
			beq chdirup
updatebally:			
			clc
			adc directy
			sta bally
			
			jmp plotball
			
chdirtoright:
			ldx #1
			stx directx
			jmp updateballx
			
chdirtoleft:
			
			ldx #255
			stx directx
			jmp updateballx

chdirdown:
			ldx #1
			stx directy
			jmp updatebally
			
chdirup:
			
			ldx #255
			stx directy
			jmp updatebally
			
plotball:			
			ldx ballx
			lda balldata,x
			ldy bally
			ora ($f0),y	
			sta ($f0),y
noballmovement:
			rts
			
clearchar:
			lda #0
			tay
clearchar0:			
			sta ($f0),y
			iny
			cpy #8
			bne clearchar0
			rts
			
randomgenerator:
			lda $DC04
			eor $DC05
			eor $DD04
			adc $DD05
			eor $DD06
			eor $DD07
			rts
			
			
scrolltext:	
.text "welcome to micropong  this is the most horrible untested ungamerfriendly bloody crap pong game you ever played   press fire for your worst gamer nightmare     "
.byte 0
			
balldata:		.byte %10000000
			.byte %01000000
			.byte %00100000
			.byte %00010000
			.byte %00001000
			.byte %00000100
			.byte %00000010
			.byte %00000001
			
speedcounter:	.byte 0
joystick1pos:	.byte 0
joystick2pos:	.byte 0
ballx:		.byte 0
bally: 		.byte 0
directx:		.byte 1
directy:		.byte 1
scrollcnt:		.byte 0