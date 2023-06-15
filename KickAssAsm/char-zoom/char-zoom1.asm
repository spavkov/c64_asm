/*

Zoom: routine based on code from Codebase64

Trashed: by PH. :)

Code: for KickAssembler (best there is //) )

.var data = LoadBinary("chars2") //we need to load a charset or use def
.pc =$0801 "Basic Upstart Program"
:BasicUpstart($0810)

*

one: char is 8 .bytes

ex: for char 1 ..is represented by a bit pattern for each of the 8 .bytes
(x is 0)

xxxxxxxx: .byte 0
xxx11xxx: .byte 1 etc
xx111xxx:
xxx11xxx:
xxx11xxx:
xxx11xxx:
xx1111xx:
xxxxxxxx:

char: matrix ie screen mem starts at upper left 0 and is adress $0500 in this tutorial

.label screenmemstart= $0500
__:$500
|
01234567:
01234567: left 0 is screenmemstart + 40 etc
01234567:
01234567:
01234567:
01234567:
01234567:
01234567:

Code: does what?

Read: bit in char write as a filled .byte if 1 and as a space .byte if 0 !
*/
//---------------------------------------------------------
//---------------------------------------------------------

:BasicUpstart2(start)
start:
//.pc = $0810 "Main Program"

// .text screen address
.var screen_pos_lo = $10 //obs pointers
.var screen_pos_hi = $11

.var screen_color_lo = $fa
.var screen_color_hi = $fb

// font address
.var font_addr_lo = $12 //$12
.var font_addr_hi = $13 //$13

//helper variable
.var fontlineoffs = $14

// font position addy,
// add (8*char_id) to select character you want to display

jsr $ff81 // kernal clear screen

lda #$00 // the 8*char pointer
sta font_addr_lo
lda #$20
sta font_addr_hi

loop:
lda #$0 //set /reset screen mem pointer
sta screen_pos_lo
lda #$05
sta screen_pos_hi

lda #$0 //set /reset Screenmem pointer
sta screen_color_lo
lda #$d9 // as screen is $400+100 ie $500 colmem for char is at $d800+$100 ie $d900
sta screen_color_hi

// jmp now8

ldy #30
w8frame:
bit $d011 // Wait for new frame
bpl *-3
bit $d011
bmi *-3
dey:
bne w8frame

now8:

ldy #8
inc font_addr_lo //fontadr lo + 8 ie count to new char
dey
bne *-3

// font-line offset

lda #0
sta fontlineoffs

_begin:
ldy fontlineoffs // y 0-8 scans over a char .byte
lda (font_addr_lo),y // font adress + char .byte

ldy #7

_shift:
lsr // shift one bit and see if it is 1 or 0

tax // save screenmem pointer
bcs bitwas1 // branch on bit set

lda #32 // if bit was 0 write screencode for space at screenmem
sta (screen_pos_lo),y

jmp bitwas0

bitwas1:
lda #160 // if bit was 1 write a filled char at screenmem
sta (screen_pos_lo),y
pha
lda fgc
sta (screen_color_lo),y
pla
bitwas0:

txa //recall screenmem pointer

dey // next screen mem cell
bpl _shift // did we shift every bit already?

lda screen_pos_lo // add 40 (go down one char
clc
adc #40
sta screen_pos_lo // always add 40 to lo
bcc nosethi // on carrry set inc hi and fontlineoffset
inc screen_pos_hi
nosethi:
inc fontlineoffs //on carry clear only inc
//----------
// color stuff
pha
lda screen_color_lo // add 40 for color
clc
adc #40
sta screen_color_lo
bcc nosethicol
inc screen_color_hi
nosethicol:
pla
//-------------
lda fontlineoffs // next .byte in char
cmp #8 // did we put every line of char?
bmi _begin

inc fgc //simple inc on color

jmp loop
rts

fgc: .byte 0 //place for color value


.var data = LoadBinary("lady_tut.64c") //we need to load a charset or use def

.pc= $1ffe // $2000 -load adress
.fill data.getSize(), data.get(i)