//---------------------------------------------------------------------------------------------------------------------
// Plascii Petsma
// Code: Cruzer/CML
// Asm: KickAss 4
// https://csdb.dk/release/?id=159933
//---------------------------------------------------------------------------------------------------------------------
.import source "cruzersLib.asm"
//---------------------------------------------------------------------------------------------------------------------
.var tuneZp =			allocZpsAbsolute("sir", List().add($fa,$fb,$fc,$fd))
.var pnt0 =			allocZp("sir", 2)
.var pnt1 =			allocZp("sir", 2)
.var tmp =			allocZp("sir", 2)
.var cnt =			allocZp("sir", 2)
.var mem =			allocZp(" ir", 1)
.var regs =			allocZp("sir", 3)
.var zp00 =			allocZp("  r", 1)
.var xPos =			allocZp(" i ", 1)
.var yPos =			allocZp(" i ", 1)
.var linePnts =			allocZp("  r", 25)
.var charCnt =			allocZp(" ir", 1)
.var ecmCnt =			allocZp(" ir", 1)
.var colorCnt =			allocZp(" ir", 1)
.var plasmaCnts =		allocZp(" ir", 2)
.var cycleCnt =			allocZp(" ir", 1)
.var currentColorPalette =	allocZp(" ir", 5)
.var plasmaParamPnt =		allocZp(" ir", 2)
.var screenAdr =		allocZp(" ir", 2)
.var durationCnt =		allocZp(" ir", 2)
.var currentPlasmaEffect =	allocZp(" ir", 2)
.var currentPlasmaParams =	allocZp(" ir", 30)

.print "currentPlasmaEffect: $" + hex(currentPlasmaEffect)
//---------------------------------------------------------------------------------------------------------------------
.var plasmaScreen =		$0400 // +3ff
.var basic =			$0801 // 080d
.var main =			$080e // 11ff

.var plasmaSiner =		$3000 // +1ff

.var textScreen =		$3400 // +3ff

.var plasmer =			$3800 //+2fff
.var tune =			$6800 // 6fff
.var sine64 =			$7000 // +1ff
.var sine128 =			$7200 // +1ff
.var sine256 =			$7400 // +1ff
.var plasmaMap =		$7e00 // +8ff - must be here because of shx
.var charPalette =		$7e00 // +7ff
.var colorPalette =		$8600 // +7ff
//---------------------------------------------------------------------------------------------------------------------
.var release = t
.var rastatime = f
.var showAnim = f
.var numRandomEffects = 0
.var effectDuration = $b2
.var numSinePnts = 8
.var textY = 12
.var border = $d020
.var unused = $fff6
.if (!rastatime) .eval border = unused
.var plasmaMapPages = 8
.var plasmaParamLen = plasmaParams.end - plasmaParams
.var numPlasmaParams = (plasmaParamListEnd - plasmaParamList) / plasmaParamLen

.print "plasmaParamLen: " + plasmaParamLen
.print "numPlasmaParams: " + numPlasmaParams
//---------------------------------------------------------------------------------------------------------------------
.eval printZpStats("s")
.eval printZpStats("i")
.eval printZpStats("r")
//---------------------------------------------------------------------------------------------------------------------
.var sid = LoadSid("Untouched.sid") //$0f rasterlines, zp: $fa-ff
//---------------------------------------------------------------------------------------------------------------------
.pc = currentPlasmaParams "currentPlasmaParams" virtual

plasmaParams: {
	sineAddsX:	.by $00,$00,$00,$00,$00,$00,$00,$00
	sineAddsY:	.by $00,$00,$00,$00,$00,$00,$00,$00
	sineStartsY:	.by $00,$00,$00,$00,$00,$00,$00,$00
	sineSpeeds:	.by $00,$00
	plasmaFreqs:	.by $00,$00
	cycleSpeed:	.by $00
	colorPalette:	.by $00
	end:
}
//---------------------------------------------------------------------------------------------------------------------
.macro incBorder() {
	.if (!release) inc border
}
.macro setBorder(color) {
	.if (!release) :mb #color: border
}
//---------------------------------------------------------------------------------------------------------------------
:basic(startupInit)
//---------------------------------------------------------------------------------------------------------------------
.pc = main "main"
//---------------------------------------------------------------------------------------------------------------------
outLoop:
	lda goNextEffect
	beq outLoop

	jsr nextEffect
	jsr initEffect

	:mb #0 : goNextEffect
	jmp outLoop

goNextEffect:	.by 0
//---------------------------------------------------------------------------------------------------------------------
irq0:
{
	sta regs + 0
	stx regs + 1
	sty regs + 2
	:mb 1 : mem
	:mb #$35 : 1
	asl $d019

	inc border
	jsr sid.play

	lda cnt
	and #$01
	beq notDone
	dec durationCnt
	bne notDone
	inc goNextEffect
	:mw #waitIrq : $fffe
	jsr writeText
	lda #$ff
!:	cmp $d012
	bne !-
	:mb #$d6 : $d018
	:mb #$1b : $d011
	:mb #$00 : $d021
	jmp ri
notDone:
	inc border
	ldx cnt
	jsr doPlasma

	inc cnt
}
ri:
	:setBorder($00)
	:mb mem : 1
	lda regs + 0
	ldx regs + 1
	ldy regs + 2
	rti
//---------------------------------------------------------------------------------------------------------------------
waitIrq:
{
	sta regs + 0
	stx regs + 1
	sty regs + 2
	:mb 1 : mem
	:mb #$35 : 1
	asl $d019

	inc border
	jsr sid.play

	lda goNextEffect
	bne notDone
	:mw #irq0 : $fffe
	lda #$ff
!:	cmp $d012
	bne !-
	jsr setEcmColors
	:mb #$14 : $d018
	:mb #$5b : $d011
notDone:
	jmp ri
}
//---------------------------------------------------------------------------------------------------------------------
doPlasma:
{
	lax plasmaCnts + 0
	clc
	adc plasmaParams.sineSpeeds + 0
	sta plasmaCnts + 0

	lda plasmaCnts + 1
	tay
	clc
	adc plasmaParams.sineSpeeds + 1
	sta plasmaCnts + 1

	.if (showAnim) {
		lda cnt
		asl
		.for (var i=0; i<25; i++) {
			sta linePnts + i
		}
	} else {
		jsr plasmaSiner
	}

	lda cycleCnt
	clc
	adc plasmaParams.cycleSpeed
	sta cycleCnt

	inc border
	jmp plasmer
}
//---------------------------------------------------------------------------------------------------------------------
startupInit:
{
//	:musicTest(sid.init, 0, sid.play, $00)
	sei
	:mb #$35: $01

	:mb #$78 : $d011
	:mb #$00 : $d020
	:mb #$14 : $d018

	:mw #tuneSrc : pnt0
	:mw #tune : pnt1
	ldx #$07
	ldy #$00
!:	:mb (pnt0),y : (pnt1),y
	iny
	bne !-
	inc pnt0 + 1
	inc pnt1 + 1
	dex
	bpl !-

	ldx #$02
	lda #$00
!:	sta $00,x
	inx
	bne !-

	jsr makePlasmaSiner
	jsr initSines
	jsr firstPlasmaEffect
	jsr initEffect
	jsr initTextScreen

	lda #0
	jsr sid.init

	:mb #$03: $dd00

	lda #$ff
!:	cmp $d012
	bne !-

	jsr setEcmColors

	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d
	asl $d019
	:mw #irq0 : $fffe
	:mb #$90 : $d012
	:mb #$5b : $d011
	:mb #$01 : $d01a

	cli
	jmp outLoop
}
//---------------------------------------------------------------------------------------------------------------------
initSines:
{
	ldx #$3f
	ldy #$40
mirrorLoop:
	lda sineSrc,x
	sta sine256,x
	sta sine256,y
	eor #$ff
	sta sine256 + $80,x
	sta sine256 + $80,y
	iny
	dex
	bpl mirrorLoop

	ldx #$00
copyLoop:
	lda sine256,x
	sta sine256 + $100,x
	lsr
	sta sine128 + $000,x
	sta sine128 + $100,x
	lsr
	sta sine64 + $000,x
	sta sine64 + $100,x
	inx
	bne copyLoop

	rts
}
//---------------------------------------------------------------------------------------------------------------------
initTextScreen:
{
	:mw #textScreen : pnt0
	lda #$20
	ldy #$00
	ldx #$03
!:	sta (pnt0),y
	iny
	bne !-
	inc pnt0 + 1
	dex
	bpl !-

	rts
}
//---------------------------------------------------------------------------------------------------------------------
clearText:
{
	ldx #$27
	lda #$20
!:	sta textScreen + 40 * textY,x
	dex
	bpl !-
	rts
}
//---------------------------------------------------------------------------------------------------------------------
writeText:
{
	ldy messagePnt
	ldx #$27
!:	lda messages,y
	sta textScreen + 40 * textY,x
	lda #$01
	sta $d800 + 40 * textY,x
	dey
	dex
	bpl !-

	lda messagePnt
	clc
	adc #$28
	bcc !+
	lda #$27
!:	sta messagePnt

	rts

messagePnt:	.by $27

messages:
//	.text "                   ><                   "	
	.text "            Camelot presents            "
	.text "       Pure Plain PETSCII Plasma        "
	.text "       Using only the ROM charset       "
	.text "        No copy/swap shenanigans        "
	.text "Inspired by CSDb topic 126119 in room 12"
	.text "         Code: Cruzer  Tune: MC         "
}
//---------------------------------------------------------------------------------------------------------------------
firstPlasmaEffect:
{
	:mb #$00 : currentPlasmaEffect
	:mw #plasmaParamList : plasmaParamPnt
	rts
}
//---------------------------------------------------------------------------------------------------------------------
nextEffect:
{
	inc currentPlasmaEffect
	lda currentPlasmaEffect
	cmp #numPlasmaParams
	beq firstPlasmaEffect

	lda plasmaParamPnt + 0
	clc
	adc #plasmaParamLen
	sta plasmaParamPnt + 0
	bcc !+
	inc plasmaParamPnt + 1
!:
	rts
}
//---------------------------------------------------------------------------------------------------------------------
initEffect:
{
	jsr fetchPlasmaParams
	jsr makePlasmer
	jsr makePalette
	jsr updatePlasmaSiner

	lda #$00
	sta plasmaCnts + 0
	sta plasmaCnts + 1
	sta cycleCnt

	jsr clearText
	jsr doPlasma
r:	rts
}
//---------------------------------------------------------------------------------------------------------------------
fetchPlasmaParams:
{
	ldy #plasmaParamLen - 1
!:	lda (plasmaParamPnt),y
	sta plasmaParams,y
	dey
	bpl !-

	:mb #effectDuration : durationCnt
	rts
}
//---------------------------------------------------------------------------------------------------------------------
setEcmColors:
{
	ldx #$03
!:	lda currentColorPalette,x
	sta $d021,x
	dex
	bpl !-
	rts
}
//---------------------------------------------------------------------------------------------------------------------
makePalette:
{
	.var charSequenceLen = $24

	lda plasmaParams.colorPalette
	asl
	asl
	adc plasmaParams.colorPalette
	adc #$04
	tax

	ldy #$04
!:	lda colorPalettes,x
	sta currentColorPalette,y
	dex
	dey
	bpl !-

	ldx #$00
	stx charCnt
	stx ecmCnt
	stx colorCnt

charLoop:
	ldy charCnt
	lda charPaletteSrc,y
	clc
	adc ecmCnt
	sta charPalette,x

	lda charPaletteSrc,y
	asl
	eor #$80
	asl
	lda #$00
	adc colorCnt
	tay
	lda currentColorPalette,y
	sta colorPalette,x

	ldy charCnt
	iny
	cpy #charSequenceLen
	bne !+
	inc colorCnt
	lda ecmCnt
	clc
	adc #$40
	sta ecmCnt
	ldy #$00
!:	sty charCnt

	inx
	bpl charLoop

	//fix last chars...
	ldx #3
fixLoop:
	lda charPalette + $7c
	ora #$c0
	sta charPalette + $7c,x
	lda colorPalette + $7b
	sta colorPalette + $7c,x
	dex
	bpl fixLoop

	ldx #$00
	ldy #$ff
mirrorLoop:
	lda charPalette + $0000,x
	sta charPalette + $0000,y
	sta charPalette + $0100,x
	sta charPalette + $0100,y
	lda colorPalette + $0000,x
	sta colorPalette + $0000,y
	sta colorPalette + $0100,x
	sta colorPalette + $0100,y
	dey
	inx
	bpl mirrorLoop

	ldx #$00
displaceLoop:
	lda charPalette + $40,x
	sta charPalette + $200,x
	sta charPalette + $300,x
	lda colorPalette + $40,x
	sta colorPalette + $200,x
	sta colorPalette + $300,x
	lda charPalette + $80,x
	sta charPalette + $400,x
	sta charPalette + $500,x
	lda colorPalette + $80,x
	sta colorPalette + $400,x
	sta colorPalette + $500,x
	lda charPalette + $c0,x
	sta charPalette + $600,x
	sta charPalette + $700,x
	lda colorPalette + $c0,x
	sta colorPalette + $600,x
	sta colorPalette + $700,x
	inx
	bne displaceLoop

	rts
}

charPaletteSrc:
	.var charSequence0 = " ---===+++%%%888###"
	.var charSequence1 = "xxx%%%+++===---  "
	.text charSequence0
	.for (var i=0; i<charSequence1.size(); i++) {
		.by charSequence1.charAt(i) | $40
	}
//---------------------------------------------------------------------------------------------------------------------
.var plasmaSinerLen = makePlasmaSiner.end - makePlasmaSiner.src

makePlasmaSiner:
{
	:mw #plasmaSiner : pnt0

	ldx #24
yLoop:
	ldy #plasmaSinerLen - 1
!:	lda src,y
	sta (pnt0),y
	dey
	bpl !-

	ldy #plasmaSinerLen
	jsr addPnt0

	inc slp + 1

	dex
	bpl yLoop

	jmp addRts

src:
	lda sine256,x
	clc
	adc sine256,y
	ror
	adc cycleCnt
slp:	sta linePnts
end:
}
//---------------------------------------------------------------------------------------------------------------------
updatePlasmaSiner:
{
	.if (showAnim) rts

	:mw #plasmaSiner : pnt0
	lda #$00
	sta plasmaCnts + 0
	sta plasmaCnts + 1

	ldx #24
loop:
	lda plasmaCnts + 0
	ldy #$01
	sta (pnt0),y
	clc
	adc plasmaParams.plasmaFreqs + 0
	sta plasmaCnts + 0

	lda plasmaCnts + 1
	ldy #$05
	sta (pnt0),y
	clc
	adc plasmaParams.plasmaFreqs + 1
	sta plasmaCnts + 1

	lda pnt0 + 0
	clc
	adc #plasmaSinerLen
	sta pnt0 + 0
	bcc !+
	inc pnt0 + 1
!:
	dex
	bpl loop

	rts
}
//---------------------------------------------------------------------------------------------------------------------
makePlasmer:
{
	.var zpScope = LocalZpScope("ir", List())
	.var sinePntsX = 	allocLocalZp(zpScope, numSinePnts)
	.var sineSinePntsX = 	allocLocalZp(zpScope, numSinePnts)
	.var sinePntsY = 	allocLocalZp(zpScope, numSinePnts)
	.var plasmaPos = 	allocLocalZp(zpScope, 1)
	.var plasmaPositions = 	allocLocalZp(zpScope, 40)
	.var xCnt = 		allocLocalZp(zpScope, 1)
	.var yCnt = 		allocLocalZp(zpScope, 1)
	.var charPaletteHi = 	allocLocalZp(zpScope, 1)
	.var colorPaletteHi = 	allocLocalZp(zpScope, 1)
	.var mapCnt = 		pnt1 + 0

	:mw #plasmer : pnt0
	lda #$00
	sta plasmaPos
	sta screenAdr + 0
	sta screenAdr + 1

	ldx #numSinePnts - 1
!:	lda plasmaParams.sineStartsY,x
	sta sinePntsY,x
	dex
	bpl !-

	:mb #24 : yCnt
yLoop:
	ldy #$00
	:mb #LDX_ZP : (pnt0),y
	iny
	
	lda yCnt
	clc
	adc #linePnts
	sta (pnt0),y

	jsr addPnt0Plus

	jsr calcPlasmaLine

	:mb #>charPalette : charPaletteHi
	:mb #>colorPalette : colorPaletteHi

	lda #$00
	sta plasmaPos
	sta mapCnt

mapLoop:
	ldx mapCnt
	lda plasmaMap,x
	bmi next


doChars:
	ldy #$00
	:mb #LDA_ABX : (pnt0),y
	iny
	txa
	and #$3f
	sta (pnt0),y
	iny
	:mb charPaletteHi : (pnt0),y

	jsr addPnt0Plus

	:mb #>plasmaMap : pnt1 + 1
reuseCharLoop:
	ldy #$00
	lax (pnt1),y
	bmi doColors

	:mb #STA_ABS : (pnt0),y
	txa
	iny
	clc
	adc screenAdr + 0
	sta (pnt0),y
	iny
	lda #>plasmaScreen
	adc screenAdr + 1
	sta (pnt0),y

	jsr addPnt0Plus

	inc pnt1 + 1
	.if (release) {
		bne reuseCharLoop
	} else {
		lda pnt1 + 1
		cmp #(>plasmaMap) + plasmaMapPages
		bne reuseCharLoop
		jmp error1
	}


doColors:
	:mb #>plasmaMap : pnt1 + 1

	ldy #$00
	:mb #LDA_ABX : (pnt0),y
	iny
	lda mapCnt
	and #$3f
	sta (pnt0),y
	iny
	:mb colorPaletteHi : (pnt0),y

	jsr addPnt0Plus

reuseColorLoop:

	ldy #$00
	:mb #STA_ABS : (pnt0),y

	lda (pnt1),y
	bmi next

	clc
	adc screenAdr + 0
	iny
	sta (pnt0),y
	iny

	lda screenAdr + 1
	adc #$d8
	sta (pnt0),y

	jsr addPnt0Plus

	inc pnt1 + 1
	bne reuseColorLoop

next:
	inc mapCnt
	beq done

	lda mapCnt
	and #$3f
	bne !+
	inc charPaletteHi
	inc charPaletteHi
	inc colorPaletteHi
	inc colorPaletteHi
!:
	jmp mapLoop
done:

	lda screenAdr + 0
	clc
	adc #$28
	sta screenAdr + 0
	bcc !+
	inc screenAdr + 1
!:
	dec yCnt
	bmi !+
	jmp yLoop
!:
	jmp addRts
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
calcPlasmaLine:
{
	ldx #numSinePnts - 1
	lda #$00
!:	lda sinePntsY,x
	clc
	adc plasmaParams.sineAddsY,x
	sta sinePntsY,x
	sta sinePntsX,x
	dex
	bpl !-

	ldx #39
xLoop:
	stx xPos

	ldy #numSinePnts - 1
!:	lda sinePntsX,y
	clc
	adc plasmaParams.sineAddsX,y
	sta sinePntsX,y
//	tax
//	lda sine256,x
//	sta sineSinePntsX,y
	dey
	bpl !-

	ldx #numSinePnts - 1
	lda #$00
!:	ldy sinePntsX,x
	clc
	adc sine256,y
	dex
	bpl !-

	ldx xPos
	sta plasmaPositions,x

	dex
	bpl xLoop
}

mapPlasmaLine:
{
	//clear map...
	ldy #$00
	lda #$80
!:
	.for (var i=0; i<plasmaMapPages + 1; i++) {
		sta plasmaMap + i * $100,y
	}
	iny
	bne !-

	sty pnt1 + 0
	:mb #>plasmaMap : pnt1 + 1

	ldx #39
xLoop:
	ldy plasmaPositions,x
	lda plasmaMap,y
	bpl findReuseSpot

firstSpotFound:
	shx plasmaMap,y
nextX:
	dex
	bpl xLoop
	rts


findReuseSpot:
	stx xPos
	:mb #(>plasmaMap) + 1 : pnt1 + 1
	ldx #plasmaMapPages - 1
searchLoop:
	lda (pnt1),y
	bmi reuseSpotFound
	inc pnt1 + 1
	dex
	bpl searchLoop
	.if (!release) {
		jmp error1
	}

reuseSpotFound:
	lax xPos
	sta (pnt1),y

	dex
	bpl xLoop
	rts

}
	.eval freeLocalZp(zpScope)
}
//---------------------------------------------------------------------------------------------------------------------
plasmaParamList:

.for (var i=0; i<numRandomEffects; i++) {
	.print "plasmaParams " + i
	.print "{"
	sineAddsX:	dumpAndPrint("sineAddsX:	.by ", rndList(numSinePnts, -3, 3), "")
	sineAddsY:	dumpAndPrint("sineAddsY:	.by ", rndList(numSinePnts, -2, 2), "")
	sineStartsY:	dumpAndPrint("sineStartsY:	.by ", rndList(numSinePnts, 0, $ff), "")
	sineSpeeds:	dumpAndPrint("sineSpeeds:	.by ", rndList(2, -4, 4), "")
	plasmaFreqs:	dumpAndPrint("plasmaFreqs:	.by ", rndList(2, 1, 10), "")
	cycleSpeed:	dumpAndPrint("cycleSpeed:	.by ", rndList(1, -11, -1), "")
	colorPalette:	dumpAndPrint("colorPalette:	.by ", rndList(1, 0, 19), "")
	.print "}"
}

{
	sineAddsX:	.by $fa,$05,$03,$fa,$07,$04,$fe,$fe
	sineAddsY:	.by $fe,$01,$fe,$02,$03,$ff,$02,$02
	sineStartsY:	.by $5e,$e8,$eb,$32,$69,$4f,$0a,$41
	sineSpeeds:	.by $fe,$fc
	plasmaFreqs:	.by $06,$07
	cycleSpeed:	.by $ff
	colorPalette:	.by $01
}
{
	sineAddsX:	.by $04,$05,$fc,$02,$fc,$03,$02,$01
	sineAddsY:	.by $00,$01,$03,$fd,$02,$fd,$fe,$00
	sineStartsY:	.by $51,$a1,$55,$c1,$0d,$5a,$dd,$26
	sineSpeeds:	.by $fe,$fd
	plasmaFreqs:	.by $08,$08
	cycleSpeed:	.by $f8
	colorPalette:	.by $06
}
{
	sineAddsX:	.by $f9,$06,$fe,$fa,$fa,$00,$07,$fb
	sineAddsY:	.by $02,$01,$02,$03,$03,$00,$fd,$00
	sineStartsY:	.by $34,$85,$a6,$11,$89,$2b,$fa,$9c
	sineSpeeds:	.by $fc,$fb
	plasmaFreqs:	.by $09,$08
	cycleSpeed:	.by $fa
	colorPalette:	.by $09
}
{
	sineAddsX:	.by $00,$01,$03,$00,$01,$ff,$04,$fc
	sineAddsY:	.by $01,$ff,$03,$fe,$fe,$03,$02,$02
	sineStartsY:	.by $f3,$02,$0b,$89,$8c,$d3,$23,$aa
	sineSpeeds:	.by $fe,$01
	plasmaFreqs:	.by $07,$07
	cycleSpeed:	.by $08
	colorPalette:	.by $0a
}
{
	sineAddsX:	.by $04,$04,$04,$fc,$fd,$04,$ff,$fc
	sineAddsY:	.by $01,$02,$02,$01,$ff,$00,$ff,$01
	sineStartsY:	.by $3a,$21,$53,$93,$39,$b7,$26,$99
	sineSpeeds:	.by $fd,$fe
	plasmaFreqs:	.by $05,$06
	cycleSpeed:	.by $03
	colorPalette:	.by $04
}
{
	sineAddsX:	.by $fd,$fd,$fd,$02,$04,$00,$fd,$02
	sineAddsY:	.by $03,$02,$fd,$02,$03,$fe,$ff,$ff
	sineStartsY:	.by $bc,$99,$5d,$2f,$e6,$16,$af,$0e
	sineSpeeds:	.by $fd,$ff
	plasmaFreqs:	.by $07,$07
	cycleSpeed:	.by $f5
	colorPalette:	.by $07
}
{
	sineAddsX:	.by $fc,$00,$00,$ff,$04,$04,$00,$01
	sineAddsY:	.by $fd,$03,$00,$02,$00,$03,$02,$03
	sineStartsY:	.by $30,$c7,$07,$60,$36,$2b,$e8,$ec
	sineSpeeds:	.by $ff,$fe
	plasmaFreqs:	.by $09,$03
	cycleSpeed:	.by $f8
	colorPalette:	.by $05
}
{
	sineAddsX:	.by $fd,$fc,$fe,$00,$00,$04,$fe,$01
	sineAddsY:	.by $03,$03,$fe,$02,$00,$03,$fe,$00
	sineStartsY:	.by $21,$d7,$34,$1b,$5d,$eb,$8e,$7d
	sineSpeeds:	.by $fd,$ff
	plasmaFreqs:	.by $0a,$03
	cycleSpeed:	.by $fd
	colorPalette:	.by $03
}
{
	sineAddsX:	.by $fe,$00,$ff,$01,$04,$02,$fe,$fd
	sineAddsY:	.by $02,$01,$fe,$01,$03,$ff,$03,$ff
	sineStartsY:	.by $0b,$0f,$ea,$8c,$e0,$f8,$05,$0e
	sineSpeeds:	.by $fc,$fd
	plasmaFreqs:	.by $07,$06
	cycleSpeed:	.by $f8
	colorPalette:	.by $0c
}
{
	sineAddsX:	.by $33,$04,$34,$fc,$dd,$24,$cf,$7c
	sineAddsY:	.by $c1,$73,$02,$31,$fe,$a0,$ee,$01
	sineStartsY:	.by $3a,$21,$53,$93,$39,$b7,$26,$99
	sineSpeeds:	.by $00,$00
	plasmaFreqs:	.by $04,$01
	cycleSpeed:	.by $fd
	colorPalette:	.by $00
}
{
	sineAddsX:	.by $ff,$00,$01,$ff,$02,$fe,$00,$02
	sineAddsY:	.by $ff,$02,$01,$02,$fe,$01,$00,$00
	sineStartsY:	.by $1d,$bb,$c5,$a3,$ab,$6c,$ed,$a6
	sineSpeeds:	.by $fd,$fe
	plasmaFreqs:	.by $03,$03
	cycleSpeed:	.by $f8
	colorPalette:	.by $08
}
{
	sineAddsX:	.by $02,$03,$fd,$fd,$01,$fc,$fd,$00
	sineAddsY:	.by $01,$03,$fd,$fe,$fe,$03,$00,$00
	sineStartsY:	.by $69,$ac,$3b,$c1,$fe,$21,$37,$84
	sineSpeeds:	.by $fc,$fd
	plasmaFreqs:	.by $06,$05
	cycleSpeed:	.by $fa
	colorPalette:	.by $0b
}

plasmaParamListEnd:
//---------------------------------------------------------------------------------------------------------------------
colorPalettes:
	:colorBytes("0bcf1") //00
	:colorBytes("00055") //01
	:colorBytes("d3e42") //02
	:colorBytes("924b6") //03
	:colorBytes("6b822") //04
	:colorBytes("ace55") //05
	:colorBytes("6b8a7") //06
	:colorBytes("d3c82") //07
	:colorBytes("13e42") //08
	:colorBytes("d5b4a") //09
	:colorBytes("3eb8a") //0a
	:colorBytes("a46e3") //0b
	:colorBytes("a89be") //0c

//	dump(rndList(5,0,15))
//---------------------------------------------------------------------------------------------------------------------
addPnt0Plus:
	iny
addPnt0:
{
	tya
	clc
	adc pnt0 + 0
	sta pnt0 + 0
	bcc !+
	inc pnt0 + 1
!:
	rts
}
//---------------------------------------------------------------------------------------------------------------------
addRts:
	ldy #$00
	:mb #RTS : (pnt0),y
	rts
//---------------------------------------------------------------------------------------------------------------------
error1:
!:	inc $d020
	jmp !-
//---------------------------------------------------------------------------------------------------------------------
.pc = * "sineSrc"
sineSrc:
{
	.var amp = $fe
	.for (var i=0; i<$40; i++) {
		.var sineVal = 2 + amp / 2 + amp * 0.499999 * sin((i + 0.0) / ($100 / 2 / PI))
		.byte sineVal
	}
}
//---------------------------------------------------------------------------------------------------------------------
.pc = * "tuneSrc"
tuneSrc:
	.fill sid.size, sid.getData(i)
//---------------------------------------------------------------------------------------------------------------------
