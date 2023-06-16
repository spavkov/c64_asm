:BasicUpstart2(main)

main:
	// set to 25 line text mode and turn on the screen
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
	rts

	// Character bitmap definitions 2k 
*=$2000

	.byte	$3e, $41, $5D, $51, $5D, $41, $3E, $00
	.byte	$3F, $21, $21, $7F, $61, $61, $61, $00
	.byte	$7E, $42, $42, $7F, $61, $61, $7F, $00
	.byte	$3F, $21, $20, $60, $60, $61, $7F, $00
	.byte	$3F, $21, $21, $61, $61, $61, $7F, $00
	.byte	$3F, $20, $20, $7C, $60, $60, $7F, $00
	.byte	$3F, $20, $20, $7C, $60, $60, $60, $00
	.byte	$3F, $21, $20, $67, $61, $61, $7F, $00
	.byte	$21, $21, $21, $7F, $61, $61, $61, $00
	.byte	$04, $04, $04, $0C, $0C, $0C, $0C, $00
	.byte	$01, $01, $01, $03, $43, $43, $7F, $00
	.byte	$21, $23, $26, $7C, $66, $63, $61, $00
	.byte	$20, $20, $20, $60, $60, $60, $7F, $00
	.byte	$7F, $49, $49, $69, $61, $61, $61, $00
	.byte	$21, $31, $39, $6D, $67, $63, $61, $00
	.byte	$3F, $23, $23, $61, $61, $61, $7F, $00
	.byte	$3F, $21, $21, $7F, $60, $60, $60, $00
	.byte	$3F, $23, $23, $61, $61, $62, $7D, $00
	.byte	$7E, $42, $42, $7F, $61, $61, $61, $00
	.byte	$7F, $41, $40, $7F, $03, $43, $7F, $00
	.byte	$7F, $08, $08, $18, $18, $18, $18, $00
	.byte	$21, $21, $21, $61, $61, $61, $7F, $00
	.byte	$61, $61, $61, $63, $36, $1C, $08, $00
	.byte	$21, $21, $21, $61, $6D, $7F, $73, $00
	.byte	$41, $23, $16, $1C, $34, $62, $41, $00
	.byte	$61, $61, $61, $7F, $01, $01, $7F, $00
	.byte	$7F, $03, $03, $1C, $60, $60, $7F, $00
	.byte	$3C, $30, $30, $30, $30, $30, $3C, $00
	.byte	$0C, $12, $30, $7C, $30, $62, $FC, $00
	.byte	$3C, $0C, $0C, $0C, $0C, $0C, $3C, $00
	.byte	$00, $18, $3C, $7E, $18, $18, $18, $18
	.byte	$00, $10, $30, $7F, $7F, $30, $10, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$08, $08, $08, $18, $18, $00, $18, $00
	.byte	$63, $63, $63, $00, $00, $00, $00, $00
	.byte	$36, $7F, $36, $36, $36, $7F, $36, $00
	.byte	$08, $7F, $68, $7F, $0B, $7F, $08, $00
	.byte	$61, $61, $02, $1C, $20, $43, $43, $00
	.byte	$3C, $66, $3C, $38, $67, $66, $3F, $00
	.byte	$0C, $0C, $0C, $00, $00, $00, $00, $00
	.byte	$0C, $18, $30, $30, $30, $18, $0C, $00
	.byte	$30, $18, $0C, $0C, $0C, $18, $30, $00
	.byte	$08, $2A, $1C, $7F, $1C, $2A, $08, $00
	.byte	$08, $08, $08, $7F, $08, $08, $08, $00
	.byte	$00, $00, $00, $00, $00, $18, $18, $38
	.byte	$00, $00, $00, $7F, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $18, $18, $00
	.byte	$00, $03, $06, $0C, $18, $30, $60, $00
	.byte	$7F, $7F, $63, $63, $63, $7F, $7F, $00
	.byte	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $00
	.byte	$7F, $7F, $03, $7F, $60, $7F, $7F, $00
	.byte	$7F, $7F, $03, $0F, $03, $7F, $7F, $00
	.byte	$63, $63, $63, $7F, $03, $03, $03, $00
	.byte	$7F, $7F, $60, $7F, $03, $7F, $7F, $00
	.byte	$7F, $7F, $60, $7F, $63, $7F, $7F, $00
	.byte	$7F, $7F, $03, $03, $03, $03, $03, $00
	.byte	$7F, $7F, $63, $7F, $63, $7F, $7F, $00
	.byte	$7F, $7F, $63, $7F, $03, $7F, $7F, $00
	.byte	$00, $00, $18, $00, $00, $18, $00, $00
	.byte	$00, $00, $18, $00, $00, $18, $18, $38
	.byte	$0E, $18, $30, $60, $30, $18, $0E, $00
	.byte	$00, $7F, $7F, $00, $7F, $7F, $00, $00
	.byte	$70, $18, $0C, $06, $0C, $18, $70, $00
	.byte	$7F, $63, $03, $1F, $00, $18, $18, $00
	.byte	$00, $00, $00, $FF, $FF, $00, $00, $00
	.byte	$00, $00, $7F, $41, $7F, $41, $41, $00
	.byte	$00, $00, $7E, $42, $7F, $41, $7F, $00
	.byte	$00, $00, $7F, $40, $40, $40, $7F, $00
	.byte	$00, $00, $7E, $41, $41, $41, $7E, $00
	.byte	$00, $00, $7F, $40, $78, $40, $7F, $00
	.byte	$00, $00, $7F, $40, $78, $40, $40, $00
	.byte	$00, $00, $7F, $40, $4F, $41, $7F, $00
	.byte	$00, $00, $41, $41, $7F, $41, $41, $00
	.byte	$00, $00, $08, $08, $08, $08, $08, $00
	.byte	$00, $00, $01, $01, $01, $41, $7F, $00
	.byte	$00, $00, $41, $42, $7C, $42, $41, $00
	.byte	$00, $00, $40, $40, $40, $40, $7F, $00
	.byte	$00, $00, $41, $63, $55, $49, $41, $00
	.byte	$00, $00, $41, $61, $5D, $43, $41, $00
	.byte	$00, $00, $7F, $41, $41, $41, $7F, $00
	.byte	$00, $00, $7F, $41, $7F, $40, $40, $00
	.byte	$00, $00, $7F, $41, $45, $43, $7F, $00
	.byte	$00, $00, $7F, $41, $7F, $42, $43, $00
	.byte	$00, $00, $7F, $40, $7F, $01, $7F, $00
	.byte	$00, $00, $7F, $08, $08, $08, $08, $00
	.byte	$00, $00, $41, $41, $41, $41, $7F, $00
	.byte	$00, $00, $41, $41, $22, $14, $08, $00
	.byte	$00, $00, $41, $49, $55, $63, $41, $00
	.byte	$00, $00, $41, $22, $1C, $22, $41, $00
	.byte	$00, $00, $41, $41, $7F, $01, $7F, $00
	.byte	$00, $00, $7F, $02, $1C, $20, $7F, $00
	.byte	$18, $18, $18, $FF, $FF, $18, $18, $18
	.byte	$C0, $C0, $30, $30, $C0, $C0, $30, $30
	.byte	$18, $18, $18, $18, $18, $18, $18, $18
	.byte	$00, $00, $03, $3E, $76, $36, $36, $00
	.byte	$FF, $7F, $3F, $1F, $0F, $07, $03, $01
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
	.byte	$00, $00, $00, $00, $FF, $FF, $FF, $FF
	.byte	$FF, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $FF
	.byte	$C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
	.byte	$CC, $CC, $33, $33, $CC, $CC, $33, $33
	.byte	$03, $03, $03, $03, $03, $03, $03, $03
	.byte	$00, $00, $00, $00, $CC, $CC, $33, $33
	.byte	$FF, $FE, $FC, $F8, $F0, $E0, $C0, $80
	.byte	$03, $03, $03, $03, $03, $03, $03, $03
	.byte	$18, $18, $18, $1F, $1F, $18, $18, $18
	.byte	$00, $00, $00, $00, $0F, $0F, $0F, $0F
	.byte	$18, $18, $18, $1F, $1F, $00, $00, $00
	.byte	$00, $00, $00, $F8, $F8, $18, $18, $18
	.byte	$00, $00, $00, $00, $00, $00, $FF, $FF
	.byte	$00, $00, $00, $1F, $1F, $18, $18, $18
	.byte	$18, $18, $18, $FF, $FF, $00, $00, $00
	.byte	$00, $00, $00, $FF, $FF, $18, $18, $18
	.byte	$18, $18, $18, $F8, $F8, $18, $18, $18
	.byte	$C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
	.byte	$E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0
	.byte	$07, $07, $07, $07, $07, $07, $07, $07
	.byte	$FF, $FF, $00, $00, $00, $00, $00, $00
	.byte	$FF, $FF, $FF, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $FF, $FF, $FF
	.byte	$03, $03, $03, $03, $03, $03, $FF, $FF
	.byte	$00, $00, $00, $00, $F0, $F0, $F0, $F0
	.byte	$0F, $0F, $0F, $0F, $00, $00, $00, $00
	.byte	$18, $18, $18, $F8, $F8, $00, $00, $00
	.byte	$F0, $F0, $F0, $F0, $00, $00, $00, $00
	.byte	$F0, $F0, $F0, $F0, $0F, $0F, $0F, $0F
	.byte	$C1, $BE, $A2, $AE, $A2, $BE, $C1, $FF
	.byte	$C0, $DE, $DE, $80, $9E, $9E, $9E, $FF
	.byte	$81, $BD, $BD, $80, $9E, $9E, $80, $FF
	.byte	$C0, $DE, $DF, $9F, $9F, $9E, $80, $FF
	.byte	$C0, $DE, $DE, $9E, $9E, $9E, $80, $FF
	.byte	$C0, $DF, $DF, $83, $9F, $9F, $80, $FF
	.byte	$C0, $DF, $DF, $83, $9F, $9F, $9F, $FF
	.byte	$C0, $DE, $DF, $98, $9E, $9E, $80, $FF
	.byte	$DE, $DE, $DE, $80, $9E, $9E, $9E, $FF
	.byte	$FB, $FB, $FB, $F3, $F3, $F3, $F3, $FF
	.byte	$FE, $FE, $FE, $FC, $BC, $BC, $80, $FF
	.byte	$DE, $DC, $D9, $83, $99, $9C, $9E, $FF
	.byte	$DF, $DF, $DF, $9F, $9F, $9F, $80, $FF
	.byte	$80, $B6, $B6, $96, $9E, $9E, $9E, $FF
	.byte	$DE, $CE, $C6, $92, $98, $9C, $9E, $FF
	.byte	$C0, $DC, $DC, $9E, $9E, $9E, $80, $FF
	.byte	$C0, $DE, $DE, $80, $9F, $9F, $9F, $FF
	.byte	$C0, $DC, $DC, $9E, $9E, $9D, $82, $FF
	.byte	$81, $BD, $BD, $80, $9E, $9E, $9E, $FF
	.byte	$80, $BE, $BF, $80, $FC, $BC, $80, $FF
	.byte	$80, $F7, $F7, $E7, $E7, $E7, $E7, $FF
	.byte	$DE, $DE, $DE, $9E, $9E, $9E, $80, $FF
	.byte	$9E, $9E, $9E, $9C, $C9, $E3, $F7, $FF
	.byte	$DE, $DE, $DE, $9E, $92, $80, $8C, $FF
	.byte	$BE, $DC, $E9, $E3, $CB, $9D, $BE, $FF
	.byte	$9E, $9E, $9E, $80, $FE, $FE, $80, $FF
	.byte	$80, $FC, $FC, $E3, $9F, $9F, $80, $FF
	.byte	$C3, $CF, $CF, $CF, $CF, $CF, $C3, $FF
	.byte	$F3, $ED, $CF, $83, $CF, $9D, $03, $FF
	.byte	$C3, $F3, $F3, $F3, $F3, $F3, $C3, $FF
	.byte	$FF, $E7, $C3, $81, $E7, $E7, $E7, $E7
	.byte	$FF, $EF, $CF, $80, $80, $CF, $EF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$F7, $F7, $F7, $E7, $E7, $FF, $E7, $FF
	.byte	$9C, $9C, $9C, $FF, $FF, $FF, $FF, $FF
	.byte	$C9, $80, $C9, $C9, $C9, $80, $C9, $FF
	.byte	$F7, $80, $97, $80, $F4, $80, $F7, $FF
	.byte	$9E, $9E, $FD, $E3, $DF, $BC, $BC, $FF
	.byte	$C3, $99, $C3, $C7, $98, $99, $C0, $FF
	.byte	$F3, $F3, $F3, $FF, $FF, $FF, $FF, $FF
	.byte	$F3, $E7, $CF, $CF, $CF, $E7, $F3, $FF
	.byte	$CF, $E7, $F3, $F3, $F3, $E7, $CF, $FF
	.byte	$F7, $D5, $E3, $80, $E3, $D5, $F7, $FF
	.byte	$F7, $F7, $F7, $80, $F7, $F7, $F7, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $E7, $E7, $C7
	.byte	$FF, $FF, $FF, $80, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $E7, $E7, $FF
	.byte	$FF, $FC, $F9, $F3, $E7, $CF, $9F, $FF
	.byte	$80, $80, $9C, $9C, $9C, $80, $80, $FF
	.byte	$F3, $F3, $F3, $F3, $F3, $F3, $F3, $FF
	.byte	$80, $80, $FC, $80, $9F, $80, $80, $FF
	.byte	$80, $80, $FC, $F0, $FC, $80, $80, $FF
	.byte	$9C, $9C, $9C, $80, $FC, $FC, $FC, $FF
	.byte	$80, $80, $9F, $80, $FC, $80, $80, $FF
	.byte	$80, $80, $9F, $80, $9C, $80, $80, $FF
	.byte	$80, $80, $FC, $FC, $FC, $FC, $FC, $FF
	.byte	$80, $80, $9C, $80, $9C, $80, $80, $FF
	.byte	$80, $80, $9C, $80, $FC, $80, $80, $FF
	.byte	$FF, $FF, $E7, $FF, $FF, $E7, $FF, $FF
	.byte	$FF, $FF, $E7, $FF, $FF, $E7, $E7, $C7
	.byte	$F1, $E7, $CF, $9F, $CF, $E7, $F1, $FF
	.byte	$FF, $80, $80, $FF, $80, $80, $FF, $FF
	.byte	$8F, $E7, $F3, $F9, $F3, $E7, $8F, $FF
	.byte	$80, $9C, $FC, $E0, $FF, $E7, $E7, $FF
	.byte	$FF, $FF, $FF, $00, $00, $FF, $FF, $FF
	.byte	$FF, $FF, $80, $BE, $80, $BE, $BE, $FF
	.byte	$FF, $FF, $81, $BD, $80, $BE, $80, $FF
	.byte	$FF, $FF, $80, $BF, $BF, $BF, $80, $FF
	.byte	$FF, $FF, $81, $BE, $BE, $BE, $81, $FF
	.byte	$FF, $FF, $80, $BF, $87, $BF, $80, $FF
	.byte	$FF, $FF, $80, $BF, $87, $BF, $BF, $FF
	.byte	$FF, $FF, $80, $BF, $B0, $BE, $80, $FF
	.byte	$FF, $FF, $BE, $BE, $80, $BE, $BE, $FF
	.byte	$FF, $FF, $F7, $F7, $F7, $F7, $F7, $FF
	.byte	$FF, $FF, $FE, $FE, $FE, $BE, $80, $FF
	.byte	$FF, $FF, $BE, $BD, $83, $BD, $BE, $FF
	.byte	$FF, $FF, $BF, $BF, $BF, $BF, $80, $FF
	.byte	$FF, $FF, $BE, $9C, $AA, $B6, $BE, $FF
	.byte	$FF, $FF, $BE, $9E, $A2, $BC, $BE, $FF
	.byte	$FF, $FF, $80, $BE, $BE, $BE, $80, $FF
	.byte	$FF, $FF, $80, $BE, $80, $BF, $BF, $FF
	.byte	$FF, $FF, $80, $BE, $BA, $BC, $80, $FF
	.byte	$FF, $FF, $80, $BE, $80, $BD, $BC, $FF
	.byte	$FF, $FF, $80, $BF, $80, $FE, $80, $FF
	.byte	$FF, $FF, $80, $F7, $F7, $F7, $F7, $FF
	.byte	$FF, $FF, $BE, $BE, $BE, $BE, $80, $FF
	.byte	$FF, $FF, $BE, $BE, $DD, $EB, $F7, $FF
	.byte	$FF, $FF, $BE, $B6, $AA, $9C, $BE, $FF
	.byte	$FF, $FF, $BE, $DD, $E3, $DD, $BE, $FF
	.byte	$FF, $FF, $BE, $BE, $80, $FE, $80, $FF
	.byte	$FF, $FF, $80, $FD, $E3, $DF, $80, $FF
	.byte	$E7, $E7, $E7, $00, $00, $E7, $E7, $E7
	.byte	$3F, $3F, $CF, $CF, $3F, $3F, $CF, $CF
	.byte	$E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7
	.byte	$FF, $FF, $FC, $C1, $89, $C9, $C9, $FF
	.byte	$00, $80, $C0, $E0, $F0, $F8, $FC, $FE
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
	.byte	$FF, $FF, $FF, $FF, $00, $00, $00, $00
	.byte	$00, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $00
	.byte	$3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F
	.byte	$33, $33, $CC, $CC, $33, $33, $CC, $CC
	.byte	$FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC
	.byte	$FF, $FF, $FF, $FF, $33, $33, $CC, $CC
	.byte	$00, $01, $03, $07, $0F, $1F, $3F, $7F
	.byte	$FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC
	.byte	$E7, $E7, $E7, $E0, $E0, $E7, $E7, $E7
	.byte	$FF, $FF, $FF, $FF, $F0, $F0, $F0, $F0
	.byte	$E7, $E7, $E7, $E0, $E0, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $07, $07, $E7, $E7, $E7
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $00, $00
	.byte	$FF, $FF, $FF, $E0, $E0, $E7, $E7, $E7
	.byte	$E7, $E7, $E7, $00, $00, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $00, $00, $E7, $E7, $E7
	.byte	$E7, $E7, $E7, $07, $07, $E7, $E7, $E7
	.byte	$3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F
	.byte	$1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F
	.byte	$F8, $F8, $F8, $F8, $F8, $F8, $F8, $F8
	.byte	$00, $00, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$00, $00, $00, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $00, $00, $00
	.byte	$FC, $FC, $FC, $FC, $FC, $FC, $00, $00
	.byte	$FF, $FF, $FF, $FF, $0F, $0F, $0F, $0F
	.byte	$F0, $F0, $F0, $F0, $FF, $FF, $FF, $FF
	.byte	$E7, $E7, $E7, $07, $07, $FF, $FF, $FF
	.byte	$0F, $0F, $0F, $0F, $FF, $FF, $FF, $FF
	.byte	$0F, $0F, $0F, $0F, $F0, $F0, $F0, $FF