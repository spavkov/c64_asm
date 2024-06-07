// http://www.0xc64.com/2013/11/24/1x1-smooth-text-scroller/
// github: https://github.com/0xc64/c64/blob/master/raster/textscroller.asm

BasicUpstart2(start)

start:

			lda #01 			// black sceen & background
			sta $d020
			lda #00
			sta $d021

plotcolour:	ldx #$40				// init colour map
			lda #01
plotcolourLoop:			
			sta $dbc0, x
			dex
			bpl plotcolourLoop

			sei					// set up interrupt
			lda #$7f
			sta $dc0d			// turn off the CIA interrupts
			sta $dd0d
			and $d011			// clear high bit of raster line
			sta $d011		

			ldy #00				// trigger on first scan line
			sty $d012

			lda #<noscroll		// load interrupt address
			ldx #>noscroll
			sta $0314
			stx $0315

			lda #$01 			// enable raster interrupts
			sta $d01a
			cli
			rts					// back to BASIC

noscroll:	lda $d016			// default to no scroll on start of screen
			and #%11111000   	// mask register to maintain higher bits - leave first bits 4-8 as is and switch of bits 1-3
			sta $d016
			ldy #242			// trigger scroll on last character row
			sty $d012
			lda #<scroll		// load interrupt address
			ldx #>scroll
			sta $0314
			stx $0315
			inc $d019			// acknowledge interrupt
			jmp $ea31

scroll:		lda $d016			// grab scroll register
			and #%11111000      // mask lower 3 bits
			adc offset			// apply scroll
			sta $d016

			dec smooth			// smooth scroll
			bne continue

			dec offset			// update scroll
			bpl resetsmooth
			lda #07				// reset scroll offset
			sta offset

shiftrow:	ldx #00 			// shift characters to the left
			lda $07c1, x
			sta $07c0, x
			inx
			cpx #39
			bne shiftrow+2

			ldx nextchar		// insert next character
			lda message, x
			sta $07e7			
			inx
			lda message, x
			cmp #$ff			// loop message
			bne resetsmooth-3
			ldx #00
			stx nextchar

resetsmooth:
        	ldx #01				// set smoothing
			stx smooth			

			ldx offset			// update colour map
			lda colours, x
			sta	$dbc0
			lda colours+8, x
			sta $dbc1
			lda colours+16, x
			sta	$dbe6
			lda colours+24, x
			sta $dbe7

continue:	ldy #00				// trigger on first scan line
			sty $d012
			lda #<noscroll		// load interrupt address
			ldx #>noscroll
			sta $0314
			stx $0315
			inc $d019			// acknowledge interrupt
			jmp $ea31

offset:		.byte 07 			// start at 7 for left scroll
smooth:		.byte 01
nextchar:	.byte 00
message:		
            .text "simple scroll.... "
            .byte 255

colours:	.byte 01, 00, 00, 00, 06, 06, 06, 06
			.byte 14, 14, 14, 14, 03, 03, 03, 03
			.byte 03, 03, 03, 03, 14, 14, 14, 14
			.byte 06, 06, 06, 06, 00, 00, 00, 01