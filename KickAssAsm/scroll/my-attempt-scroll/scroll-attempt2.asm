:BasicUpstart2(start)
start:

sei

mainLoop:
 lda #$00  // wait for line #00, making sure we
waitforraster1:
 cmp $d012 // don't catch it twice in one frame
 beq waitforraster1
 waitforraster2:
 cmp $d012
 bne waitforraster2

lda #00
sta $d021

lda $d016                                    // d016 is VIC-II control register.
and #%11110111                               // un-set bit 3 to enable 38 column mode
sta $d016 

lda $d016			// grab scroll register
and #%11111000      // mask lower 3 bits
adc offset			// apply scroll
sta $d016

dec offset			// update scroll
bpl next

lda #07				// reset scroll offset
sta offset 
 
 ldx #$00  // move columns 1..38 one byte left
 charLoop:
 lda $0401,x
 sta $0400,x
 inx
 cpx #$27
 bne charLoop
 lda dummyData // some dummy data to column 38
 sta $0426
 inc dummyData

next:
 lda #$70  // wait for line #59, making sure we
waitforraster3:
 cmp $d012 // don't catch it twice in one frame
 beq waitforraster3
 waitforraster4:
 cmp $d012 
 bne waitforraster4

lda #01
sta $d021

lda $d016                                     // d016 is VIC-II control register.
ora #%00001000                                   // set bit 3 to enable 40 column mode
sta $d016 

jmp start

dummyData: .byte 00
delay: .byte 10
delayInitialValue: .byte 10

offset:		.byte 07 			// start at 7 for left scroll