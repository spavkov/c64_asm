
.label fadestep = $ff

:BasicUpstart2(start)

start:

  				lda #$02						// vic bank 1 ($4000-$7fff)
				sta $dd00 						//

   				lda #$00
   				sta $d020			            // border color

   				lda background+1
   				sta $d021         				// background color
   				lda background+2
   				sta $d022           			// multi color 1 background
   				lda background+3
   				sta $d023         				// multi color 2 background

   	  			jsr init_koala					// init koala picture routine

wait_space:
				lda $dc01						// load spacebar register
				cmp #$ef						// is space pressed?
				bne wait_space

				jsr fadeout

				// Remain into the darkness
      			jmp *

//============================================================
init_koala:
                lda #$78
				ldx #$d8
				ldy #$3b
  				sta $d018
				stx $d016
				sty $d011

	  			ldy #$00
koala:
				lda $7f40,y
				sta $5c00,y
				lda $8040,y
				sta $5d00,y
				lda $8140,y
				sta $5e00,y
				lda $8240,y
				sta $5f00,y
				lda $8328,y
				sta $d800,y
				lda $8428,y
				sta $d900,y
				lda $8528,y
                sta $da00,y
				lda $8628,y
                sta $db00,y
        		iny
                bne koala
                rts

//============================================================
fadeout:			lda #$fa
				cmp $d012
				bne *-3
				jsr fadeuntildone
				jmp fadeout

//============================================================
fadeuntildone:
				lda fadedelay
				cmp #3
				beq fadeok
				inc fadedelay
			    rts
fadeok:			lda #0
				sta fadedelay
				ldx fadepointer
				lda fade_out_mem,x
				sta $02
				lda fade_out_charmem,x
				sta $03
				jsr fadeoutram
				inx
				cpx #length-fade_out_mem
				beq finishedfade
				inc fadepointer
				rts
finishedfade:	ldx #$00
				stx fadepointer
				jmp *
fadeoutram:
				ldy #$00
dofadeout:		lda $02

				sta $d800,y
				sta $d900,y
				sta $da00,y
				sta $dae8,y
				lda $03

				sta $5c00,y
				sta $5d00,y
				sta $5e00,y
				sta $5ee8,y
				iny
				bne dofadeout
				rts


//============================================================

fadedelay: .byte $00
fadepointer: .byte $00
background: .byte $00,$00,$00


fade_out_mem:
.byte $01,$01,$07,$0f,$0a,$08,$02,$09,$0b,$00,$00,$00,$00
length:

fade_out_charmem:
.byte $11,$11,$11,$77,$f3,$a5,$84,$26,$92,$b0,$00,$00,$00


* = $6000			
.var picture = LoadBinary("oldlogo.kla", BF_KOALA)
								// address to load the koala picture data
//.binary "pvm.kla",2