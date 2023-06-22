:BasicUpstart2(main)

.var chardata=$04 

.function sinus(i, amplitude, center, noOfSteps) {
	.return round(center+amplitude*sin(toRadians(i*360/noOfSteps)))	
}

main:
	// set to 80x25 line text mode and turn on the screen
	lda #$1B
	sta $d011

	// disable SHIFT-Commodore
	lda #$80
	sta $0291

	// set screen memory ($0400) and charset bitmap offset ($2000)
	lda #$18
	sta $d018

	// set border color
	lda #$06
	sta $d020

	// set background color
	lda #$06
	sta $d021

	// set text color
	lda #$0E
	sta $0286

	// clear screen
	lda #$4f
	ldx #$0
clearloop:	
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $0700,x
	inx
	bne clearloop


	lda #$4f
	sta chardata
	ldy #$0
loop1:
	lda chardata
	sta $0400,x
	inc chardata
	inx
	cpx #$0f
	bne loop1

	ldx #$0
	ldy #$0

looprow:
	lda sinus,y
	ldx sinus,y



	jmp *

.var charset = LoadBinary("charset-with-gradients.bin", BF_C64FILE)

*=$2000;  .fill charset.getSize(), charset.get(i)

sinus:		.fill $100, round($a0+$40*sin(toRadians(i*360/$100)))	 	// <- The fill functions takes two argument. 
																		// The number of bytes to fill and an expression to execute for each
																		// byte. 'i' is the byte number 

			.fill $100, sinus(i, $40, $a0, $100)			//<- Its easier to use a function when you use the expression many times	
