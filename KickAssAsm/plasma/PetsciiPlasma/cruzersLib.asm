
.const t = true
.const f = false

.const BEQ = BEQ_REL
.const BNE = BNE_REL
.const BCS = BCS_REL
.const BCC = BCC_REL
.const BPL = BPL_REL
.const BMI = BMI_REL
.const BVS = BVS_REL
.const BVC = BVC_REL
.const JSR = JSR_ABS
.const JMP = JMP_ABS

.const LDA_IZY = LDA_IZPY
.const STA_IZY = STA_IZPY
.const ADC_IZY = ADC_IZPY
.const SBC_IZY = SBC_IZPY
.const ORA_IZY = ORA_IZPY
.const AND_IZY = AND_IZPY
.const EOR_IZY = EOR_IZPY
.const CMP_IZY = CMP_IZPY
.const LAX_IZY = LAX_IZPY

.const LDA_ABX = LDA_ABSX
.const STA_ABX = STA_ABSX
.const ADC_ABX = ADC_ABSX
.const SBC_ABX = SBC_ABSX
.const ORA_ABX = ORA_ABSX
.const AND_ABX = AND_ABSX
.const EOR_ABX = EOR_ABSX
.const CMP_ABX = CMP_ABSX
.const INC_ABX = INC_ABSX
.const DEC_ABX = DEC_ABSX
.const LDY_ABX = LDY_ABSX

.const LDA_ABY = LDA_ABSY
.const STA_ABY = STA_ABSY
.const ADC_ABY = ADC_ABSY
.const SBC_ABY = SBC_ABSY
.const ORA_ABY = ORA_ABSY
.const AND_ABY = AND_ABSY
.const EOR_ABY = EOR_ABSY
.const CMP_ABY = CMP_ABSY
.const LDX_ABY = LDX_ABSY



.const KOALA_P00 = "Bitmap=$001c, ScreenRam=$1f5c, ColorRam=$2344, BackgroundColor = $272c"


// 8 bit

.pseudocommand mb arg1:arg2 {
	lda arg1
	sta arg2
}

.pseudocommand mbx arg1:arg2 {
	ldx arg1
	stx arg2
}

.pseudocommand mby arg1:arg2 {
	ldy arg1
	sty arg2
}




.function reverse(str) {
	.var reverse = ""
	.for (var i=str.size()-1; i>=0; i--) {
		.eval reverse = reverse + str.charAt(i)
	}
	.return reverse
}

.var hexDigits = "0123456789abcdef"
.var charToColor = Hashtable()
.for (var i=0; i<16; i++) {
	.eval charToColor.put(hexDigits.charAt(i), i)
}
	.eval charToColor.put(' ', 0)

.function toByte(c0,c1) {
	.return charToColor.get(c0) * 16 + charToColor.get(c1)
}

.function toBytes(str) {
	.var bytes = List()
	.for (var i=0; i<str.size()-1; i++) {
		.if (str.charAt(i) != ' ' && str.charAt(i+1) != ' ') {
			.eval bytes.add(toByte(str.charAt(i+0), str.charAt(i+1)))
		}
	}
	.return bytes
}

.macro dumpBytes(str) {
	.var l = toBytes(str)
	:dump(l)
}

.function toColorNybbles(str) {
	.var list = List()
	.for (var i=0; i<str.size(); i=i+2) {
		.var chr0 = str.charAt(i)
		.var color0 = charToColor.get(chr0)
		.var color1 = 0
		.if (str.size() > i+1) {
			.var chr1 = str.charAt(i+1)
			.eval color1 = charToColor.get(chr1)
		}
		.var byte = color0 << 4 | color1
		.eval list.add(byte)
	}
	.return list
}

.function toColorBytes(str) {
	.var list = List()
	.for (var i=0; i<str.size(); i++) {
		.var chr = str.charAt(i)
		.var color = charToColor.get(chr)
		.eval list.add(color)
	}
	.return list
}

.macro dumpColorNybbles(str) {
	.var colz = toColorNybbles(str)
	.fill colz.size(), colz.get(i)
}

.macro dumpNybs(str) {
	:dumpColorNybbles(str)
}
.macro dumpNybsBackw(str) {
	.eval str = reverse(str)
	:dumpNybs(str)
}

.macro dumpColorBytes(str, startWithSize) {
	.if (startWithSize) {
		.by str.size()
	}
	.var colz = toColorBytes(str)
	.fill colz.size(), colz.get(i)
}

.macro colorBytes(str) {
	:dumpColorBytes(str, f)
}

.macro colorBytesLo(str) {
	.var colz = toColorBytes(str)
	.fill colz.size(), colz.get(i)
}
.macro colorBytesHi(str) {
	.var colz = toColorBytes(str)
	.fill colz.size(), colz.get(i) << 4
}

.macro dump(list) {
	.fill list.size(), list.get(i)
}

.macro dumpLo(list) {
	.fill list.size(), <list.get(i)
}
.macro dumpHi(list) {
	.fill list.size(), >list.get(i)
}
.macro dumpWo(list) {
	.for (var i=0; i<list.size(); i++) {
		.wo list.get(i)
	}
}
.macro dump2Dlist(list) {
	.for (var y=0; y<list.size(); y++) {
		.var xList = list.get(y)
		.fill xList.size(), xList.get(i)
	}
}



.function getBitNo(num) {
	.if (num <= 0) .error "getBitNo: "+num
	.var cnt = 0
	.for (var b=1; t ;b=b<<1) {
		.if ([num & b] != 0) {
			.if ([num & b] == num) {
				.return cnt
			} else {
				.error "getBitNo: "+num
			}
		}
		.eval cnt++
	}
}

.macro shiftLeft(num) {
	.for (var i=0; i<num; i++) {
		asl
	}
}

.macro mul(num) {
	:shiftLeft(getBitNo(num))
}

// 16 bit

.pseudocommand mw src:tar {
	
	//todo: doesn't work: with (zp,x)
	
	//.print "mw: " + tar.getType()	

	lda src
	sta tar

	.var yInced = false
	
	.if (src.getType() == 6) {
		iny
		lda src
		.eval yInced = true
	} else {
		lda _16bit_nextArgument(src)
	}

	.if (tar.getType() == 6) {
		.if (!yInced) iny
		sta tar
	} else {
		sta _16bit_nextArgument(tar)
	}
}


.macro mw2(src,tar) {
	lda src.lo
	sta tar+0
	lda src.hi
	sta tar+1
}


.pseudocommand lxy src {	
	ldx src
	ldy _16bit_nextArgument(src)
}

.pseudocommand sxy tar {	
	stx tar
	sty _16bit_nextArgument(tar)
}


.pseudocommand sw tar {	
	sta tar
	sta _16bit_nextArgument(tar)
}


//add byte
.pseudocommand ab src:tar {
	clc
	lda src
	adc tar
	sta tar
}


.pseudocommand aw adr:val {
	lda adr
	clc
	adc val
	sta adr
	lda _16bit_nextArgument(adr)
	adc _16bit_nextArgument(val)
	sta _16bit_nextArgument(adr)
}


.pseudocommand iw arg {{
	inc arg
	bne !+
	inc _16bit_nextArgument(arg)
!:
}}

.pseudocommand dw arg {
	lda arg
	bne !+
	dec _16bit_nextArgument(arg)
!:
	dec arg
}



// --------- TODO these cause weird bugs sometimes - disabled --------------

/*
	.pseudocommand bpl tar {{
		.var dist = abs(tar.getValue() - *)
		bmi !+
		jmp tar
	!:
	}}
	
	.pseudocommand bmi tar {{
		.var dist = abs(tar.getValue() - *)
		bpl !+
		jmp tar
	!:
	}}
	
	.pseudocommand bne tar {{
		//.var dist = abs(tar.getValue() - *)
	
		beq !+
		jmp tar
	!:
	}}
	
	.pseudocommand bne2 tar {{
		//.var dist = abs(tar.getValue() - *)
	
		beq !+
		jmp tar
	!:
	}}
	
	.pseudocommand beq tar {{
		.var dist = abs(tar.getValue() - *)
	
		bne !+
		jmp tar
	!:
	}}

*/

/*
.pseudocommand loop what : add : to : tar {
	lda what
	clc
	adc add
	sta what
	cmp to
	:bne tar
}
*/

/*
.pseudocommand addWord arg1 : arg2 : tar {
	.if (tar.getType()==AT_NONE) .eval tar=arg1
	lda arg1
	adc arg2
	sta tar
	lda _16bit_nextArgument(arg1)
	adc _16bit_nextArgument(arg2)
	sta _16bit_nextArgument(tar)
}
.pseudocommand subWord arg1 : arg2 : tar {
	.if (tar.getType()==AT_NONE) .eval arg3=arg1
	lda arg1
	sbc arg2
	sta tar
	lda _16bit_nextArgument(arg1)
	sbc _16bit_nextArgument(arg2)
	sta _16bit_nextArgument(tar)
}
*/

.pseudocommand vicOn {
	:mb #$35 : $01
	cli
}

.pseudocommand vicOff {
	sei
	:mb #$34 : $01
}


.macro basic(adr) {
	.pc = $0801 "basic"
	:BasicUpstart(adr)
}
//-----------------------------------------------------------------------------
// Functions
//-----------------------------------------------------------------------------

.function _16bit_nextArgument(arg) {
	.if (arg.getType()==AT_IMMEDIATE) .return CmdArgument(arg.getType(),>arg.getValue())
	.return CmdArgument(arg.getType(),arg.getValue()+1)
}

.function int(n) {
	.var str = "" + floor(n)
//	.eval str = str.substring(0, str.size()-2)
	.return str
}

.function hex(n) {
	.return toHexString(n)
}

.function hex(n, digits) {
	.var str = toHexString(n)
	.if (str.charAt(0) == 'N') .return "NaN"
	.if (n >= 0) {
		.for ( ;str.size() < digits; str="0"+str){}
	} else {
	//	.print "before: $" + str
		.eval str = str.substring(str.size()-digits, str.size())
	//	.print "after:  $" + str
	}
	.return str
}

.function bin(n) {
	.return toBinaryString(n)
}

.function bin(n, digits) {
	.var str = toBinaryString(n)
	.if (n >= 0) {
		.for ( ;str.size() < digits; str="0"+str){}
	} else {
		.eval str = str.substring(str.size()-digits, str.size())
	}
	.return str
}



// gets a random int which is >=min and <=max...
//
.function rnd(min, max) {
	.var range = max - min + 1
	.return floor(random() * range) + min
}

// gets a random int which is >=min and <=max, and not 0...
//
.function rndNot0(min, max) {
	.var result = rnd(min, max)
	.if (result == 0) {
		.eval result = rndNot0(min, max)
	}
	.return result
}

// gets a List with length len containing random ints which are >=min and <=max...
//
.function rndList(len, min, max) {
	.var result = List()
	.for (var i=0; i<len; i++) {
		.eval result.add(rnd(min,max))
	}
	.return result
}


.function intListToString(intList) {
	.var result = ""
	.for (var i=0; i<intList.size(); i++) {
		.eval result = result + toIntString(intList.get(i))
		.if (i<intList.size()-1) .eval result = result + ","
	}
	.return result
}
	


.macro musicTest(initAdr, initValue, playAdr, zpFill) {
	// e.g. :musicTest(music.init, $00, music.play, $00)

	.var rasterLine = $73
	
	jsr $e544
	sei
	:mb #$35: $01
	
	lda #zpFill
	ldx #$02
!:	sta $00,x
	inx
	bne !-
	
!:	sta $100,x
	inx
	bne !-
	
	ldx #$08
!:	:mb label,x: $041c,x
	dex
	bpl !-

	
	ldx #$ff
	txs
	
	lda #initValue
	ldx #$00
	ldy #$00
	jsr initAdr
loop:
	lda #rasterLine
!:	cmp $d012
	bne !-

	inc $d020
	jsr playAdr
	
	lda $d012
	inc $d020
	sec
	sbc #rasterLine
	cmp maxRt
	bcc !+
	sta maxRt
!:
	lda maxRt
	asl
	tax
	//:mw hexNumbers,x : $0425
	
	
	//:mw #$0400 : !s++1
	//:mw #$d800 : !c++1
	ldx #$00
!yLoop:	ldy #$00
!xLoop:	
	lda $00,x
	pha
	cmp #$20
	bne !s+
	lda #$00
!s:	sta $0400,y
	pla
	cmp #zpFill
	beq !+
	cpx #$02
	bcc !+
	lda #$07
!c:	sta $d800,y
!:	inx
	iny
	cpy #$10
	bne !xLoop-
	lda !s-+1
	clc
	adc #$28
	sta !s-+1
	sta !c-+1
	lda !s-+2
	adc #$0
	sta !s-+2
	and #$03
	ora #$d8
	sta !c-+2
	cpx #$00
	bne !yLoop-
	
	inc $d020

	
	ldx #$00
!:	lda $100,x
	sta $06d0,x
	inx
	bne !-
	
	:mb #0 : $d020
	jmp loop

maxRt:	.by 0
label:	.text "max rt: $"
hexNumbers:
	.text "000102030405060708090a0b0c0d0e0f"
	.text "101112131415161718191a1b1c1d1e1f"
	.text "202122232425262728292a2b2c2d2e2f"
	.text "303132333435363738393a3b3c3d3e3f"
	.text "404142434445464748494a4b4c4d4e4f"
	.text "505152535455565758595a5b5c5d5e5f"
	.text "606162636465666768696a6b6c6d6e6f"
	.text "707172737475767778797a7b7c7d7e7f"
}



.macro printList(prefix, list) {
	.var out = prefix
	.for (var i=0; i<list.size(); i++) {
		.eval out = out + toIntString(list.get(i))
		.if (i < list.size()-1) .eval out = out + ","
	}
	.print out
}

.macro dumpAndPrint(prefix, list, suffix) {
	dump(list)
	printHexList(prefix, list, suffix)
}

.macro printHexList(prefix, list, suffix) {
	.var max = 0
	.for (var i=0; i<list.size(); i++) .eval max = max(max, list.get(i))
	.var digits = 2
	.if (max >= $100) .eval digits = 4
	.var out = prefix
	.for (var i=0; i<list.size(); i++) {
		.eval out = out + "$" + hex(list.get(i), digits)
		.if (i < list.size()-1) .eval out = out + ","
	}
	.print out + suffix
}

.macro printStringList(prefix, list) {
	.var out = prefix
	.for (var i=0; i<list.size(); i++) {
		.eval out = out + list.get(i)
		.if (i < list.size()-1) .eval out = out + ","
	}
	.print out
}


.function listToHexString(list) {
	.var str = ""
	.for (var i=0; i<list.size(); i++) {
		.eval str += hex(list.get(i), 2)
		.if (i < list.size()-1) .eval str += " "
	}
	.return str
}

.function list(size,value) {
	.var list = List()
	.for (var i=0; i<size; i++) {
		.eval list.add(value)
	}
	.return list
}
.function list(size) {
	.return list(size,0)
}

.function list2D(size0, size1) {
	.var list = List()
	.for (var i=0; i<size0; i++) {
		.eval list.add(list(size1))
	}
	.return list
}

.function list3D(size0, size1, size2) {
	.var list = List()
	.for (var i=0; i<size0; i++) {
		.eval list.add(list2D(size1,size2))
	}
	.return list
}

.function list2hash(list) {
	.var hash = Hashtable()
	.for (var i=0; i<list.size(); i++) {
		.eval hash.put(list.get(i), t)
	}
	.return hash
}


.function Map() {
	.return Hashtable()
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// functions for dynamic allocation of zp vars
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
.struct zpScope {map, vars}
.var zpScopes = Hashtable()

.function newZpScope(chr) {
	.var zpMap = list($100)
	.var zpVars = Hashtable()
	.eval zpMap.set(0,1)
	.eval zpMap.set(1,1)
	.var scope = zpScope(zpMap, zpVars)
	.eval zpScopes.put(chr, scope)
	.return scope
}

.function getZpScope(chr) {
	.if (zpScopes.containsKey(chr)) {
		.return zpScopes.get(chr)
	} else {
		.return newZpScope(chr)
	}
}

.function getZpScopes(str) {
	.var scopes = List()
	.for (var i=0; i<str.size(); i++) {
		.var chr = str.charAt(i)
		.if (chr != ' ') {
			.eval scopes.add(getZpScope(chr))
		}
	}
	.return scopes
}

.function printZpStats(chr) {
	.var scope = getZpScope(chr)
	.var map = scope.map
	.var cnt = 0
	.for (var i=0; i<$100; i++) {
		.eval cnt += map.get(i)
	}
	.print "#used ZP bytes for scope '" + chr + "' = $" + hex(cnt,2) + "/$100"
}

.function allocZpsAbsolute(scopeStr, adrs) {
	.var scopes = getZpScopes(scopeStr)
	.for (var s=0; s<scopes.size(); s++) {
		.var scope = scopes.get(s)
		.for (var a=0; a<adrs.size(); a++) {
			.if (scope.map.get(adrs.get(a)) == 0) {
				.eval scope.map.set(adrs.get(a), 1)
			} else {
				.error "zp address already used: $" + hex(adrs.get(a), 2)
			}
		}
		//.eval scope.vars.put(adr, size)
	}
	.return adrs.size() == 0 ? -1 : adrs.get(0)
}

.function allocZpAbsolute(scopeStr, adr) {
	.return allocZpAbsolute(scopeStr, adr, 1)
}

.function allocZpAbsolute(scopeStr, adr, size) {
	.var scopes = getZpScopes(scopeStr)
	.for (var s=0; s<scopes.size(); s++) {
		.var scope = scopes.get(s)
		.for (var a=0; a<size; a++) {
			.if (scope.map.get(adr + a) == 0) {
				.eval scope.map.set(adr + a, 1)
			} else {
				.error "zp address already used: $" + hex(adr+a, 2)
			}
		}
		.eval scope.vars.put(adr, size)
	}
	.return adr
}

/*
	.function allocZp(scopeStr, start, size) {
		.for (var i=0; i<size; i++) {
			.eval zpMap.set(start+i, 1)
		}
		.eval zpVars.put(start, size)
		.return start
	}
*/

.function allocZp(scopeStr) {
	.return allocZp(scopeStr, 1)
}

.function allocZp(scopeStr, size) {
	.var scopes = getZpScopes(scopeStr)
	.var cnt = 0
	.var adr = -1
	.for (var a=0; a<$100 && adr==-1; a++) {
		.var adrUsed = f
		.for (var s=0; s<scopes.size(); s++) {
			.var scope = scopes.get(s)
			.if (scope.map.get(a) != 0) {
				.eval adrUsed = t
			}
		}
		.if (!adrUsed) {
			.eval cnt++
			.if (cnt == size) {
				.eval adr = a - [size - 1]
				.eval allocZpAbsolute(scopeStr, adr, size)
			}
		} else {
			.eval cnt = 0
		}
	}
	.if (adr == -1) {
		.error "no space for zp block of size: " + size
	} else {
		//.print "allocZp: $"+hex(adr,2)
		.return adr
	}
}

.function freeZp(scopeStr, adr) {
	.var scopes = getZpScopes(scopeStr)
	.for (var s=0; s<scopes.size(); s++) {
		.var scope = scopes.get(s)
		.if (!scope.vars.containsKey(adr)) {
			.error "can't free zp var at: $" + adr + " since it's not allocated"
	
		}
		.var size = scope.vars.get(adr)
//		.print "freeing zp-var of size: " + size
		.for (var i=0; i<size; i++) {
			.eval scope.map.set(adr + i, 0)
		}
		.eval scope.vars.remove(adr)
	}
}


.struct LocalZpScope{scope, list}

.function allocLocalZp(localScope, num) {
	.var allocatedAdr = allocZp(localScope.scope, num)
	.eval localScope.list.add(allocatedAdr)
	.return allocatedAdr
}

.function freeLocalZp(localScope) {
	.for (var i=0; i<localScope.list.size(); i++) {
		.eval freeZp(localScope.scope, localScope.list.get(i))
	}
}