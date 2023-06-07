//--------------------------------------------------------------------
//This routine sets or erases a point on the hires screen based
//on coordinates and drawmode determined before-hand. you can change
//"screen" to wherever your hires screen is located.
//plotPoint works by first determining which 8x8 cell the point is
//located in and uses tables to figure that out.
//The in-cell offset is determined by just isolating the lowest 3 bits
//of each point [0-7]. The pixel masking uses tables, too.
//
// code org from http://www.lemon64.com/forum/viewtopic.php?p=599398&sid=5a9ef1a2915107a94d80c0a39f68fff0
//
// Pierre Hallsten added
//
// code at lemon64 doesnt work so i (PH) fixed it :)
// just added a clc and < > at tables
/*
if you wanna loop a line drawing by for ex inc PointX then you have to set PointX+1 (highbyte) every loop if you want pointX < 255
as PointX+1 gets ror PointX+x in code.
Maybee you can find out a better way of doin it
*/
//--------------------------------------------------------------------

.var screen = $4000 //for example
.var colmem =$7c00
.var to_bm = screen
.var dest = $fb //calculated

.pc =$0801 "Basic Upstart Program"
:BasicUpstart($0810)
.pc = $0810 "Main Program"
lda $dd00 //bank 1 $4000 no chars
and #$11111100
ora #%00000010
sta $dd00

lda $d011 //go bitmap
// 0011 1011
ora #%00100000 //bit 5 go bitmap
sta $d011

lda #$c8 //def
sta $d016

// 0001 1000

lda #$f0 // 1111 0000 as screen at 7c00 in bank 1 / and bm at first chunk ie $4000 if bank 1
sta $d018

dodo:
lda #$31
cmp $d012 //w8 rast
bne *-3

jsr reloop
jsr reloop
jsr reloop
jsr reloop

lda cc2
cmp #$61 // just prevent overwriting memory
bne norescc2
lda #0
sta cc2
norescc2:

jmp dodo

reloop:

inc $d020 //visual

inc cc
bne nn2 // everywrap
inc cc2 // inc count

nn2:

//jsr plotPoint

ldx cc
lda sin,x
clc
adc cc2
inc pointX
sta pointY

//use something like this for hi bit if inc pointX
lda pointX
bne notog

jsr toggle
notog:

lda tog
//cmp #$fe
//bne nohi
bpl nohi
lda #1
sta pointX+1
lda pointX
cmp #64
bne norb
lda #0
sta pointX
sta pointX+1

jsr toggle

norb:

nohi:

jsr plotPoint
dec $d020

nn:
rts

//--------------
toggle:
// toggles 0/-1
//wrap so tog

lda tog
eor #$ff
sta tog
rts

plotPoint:

//-------------------------
//calc Y-cell, divide by 8
//y/8 is y-cell table index
//-------------------------
lda pointY
lsr /// 2
lsr /// 4
lsr /// 8
tay //tbl_8,y index

//------------------------
//calc X-cell, divide by 8
//divide 2-byte pointX / 8
//------------------------

clc //my addition
ror pointX+1 //rotate the high byte into carry flag

lda pointX
ror //lo byte / 2 [rotate C into low byte]
//clc
lsr //lo byte / 4
lsr //lo byte / 8
tax //tbl_8,x index

//----------------------------------
//add x & y to calc cell point is in
//----------------------------------
clc

lda tbl_vbaseLo,y //table of screen row base addresses

adc tbl_8Lo,x //+ [8 * Xcell]
sta dest //= cell address

lda tbl_vbaseHi,y //do the high byte

adc tbl_8Hi,x
sta dest+1

//---------------------------------
//get in-cell offset to point [0-7]
//---------------------------------
lda pointX //get pointX offset from cell topleft
and #%00000111 //3 lowest bits = [0-7]
tax //put into index register

lda pointY //get pointY offset from cell topleft
and #%00000111 //3 lowest bits = [0-7]
tay //put into index register

//----------------------------------------------
//depending on drawmode, routine draws or erases
//----------------------------------------------

lda drawmode //[0 = erase, 1 = set]
beq erase //if = 0 then branch to clear the point

//---------
//set point
//---------

/*
$fb= dest holds lb
$fb+1 holds hb
*/

lda (dest),y //get row with point in it
ora tbl_orbit,x //isolate and set the point
sta (dest),y //write back to screen
jmp past //skip the erase-point section

//-----------
//erase point
//-----------
erase: //handled same way as setting a point
lda (dest),y //just with opposite bit-mask
and tbl_andbit,x //isolate and erase the point
sta (dest),y //write back to screen

past:

rts

/*
not used as kickass filles for us
*/
writebm:

ldx #0
bmloop:
lda #$aa
sta to_bm,x
sta to_bm+1*$100,x
sta to_bm+2*$100,x
sta to_bm+3*$100,x

sta to_bm+4*$100,x
sta to_bm+5*$100,x
sta to_bm+6*$100,x
sta to_bm+7*$100,x

sta to_bm+8*$100,x
sta to_bm+9*$100,x
sta to_bm+10*$100,x
sta to_bm+11*$100,x

sta to_bm+12*$100,x
sta to_bm+13*$100,x
sta to_bm+14*$100,x
sta to_bm+15*$100,x

sta to_bm+16*$100,x
sta to_bm+17*$100,x
sta to_bm+18*$100,x
sta to_bm+19*$100,x

sta to_bm+20*$100,x
sta to_bm+21*$100,x
sta to_bm+22*$100,x
sta to_bm+23*$100,x

sta to_bm+24*$100,x
sta to_bm+25*$100,x
sta to_bm+26*$100,x
sta to_bm+27*$100,x

sta to_bm+28*$100,x
sta to_bm+29*$100,x
sta to_bm+30*$100,x
sta to_bm+31*$100,x
inx
bne bmloop

ldx #0
lda #0
clcol:
sta colmem,x
sta colmem+$100,x
sta colmem+$200,x
sta colmem+$300,x
inx
bne clcol

rts
//----------------------------------------------------------------
.pc=* "px" // kickassembler spec..
pointX:
.word 0

pointY: //0-199
.byte 80

drawmode: //0 = erase point, 1 =set point
.byte 1

tog: .byte 0 //toggler
cc: .byte 0 // sin x counter
.pc=* "cc2" // misc counter
cc2: .byte 0

//#< lo
// tabels for finding bitmap offset to plot
tbl_vbaseLo:
.byte <screen+[0*320],<screen+[1*320],<screen+[2*320],<screen+[3*320]
.byte <screen+[4*320],<screen+[5*320],<screen+[6*320],<screen+[7*320]
.byte <screen+[8*320],<screen+[9*320],<screen+[10*320],<screen+[11*320]
.byte <screen+[12*320],<screen+[13*320],<screen+[14*320],<screen+[15*320]
.byte <screen+[16*320],<screen+[17*320],<screen+[18*320],<screen+[19*320]
.byte <screen+[20*320],<screen+[21*320],<screen+[22*320],<screen+[23*320]
.byte <screen+[24*320]

tbl_vbaseHi:
.byte >screen+[0*320],>screen+[1*320],>screen+[2*320],>screen+[3*320]
.byte >screen+[4*320],>screen+[5*320],>screen+[6*320],>screen+[7*320]
.byte >screen+[8*320],>screen+[9*320],>screen+[10*320],>screen+[11*320]
.byte >screen+[12*320],>screen+[13*320],>screen+[14*320],>screen+[15*320]
.byte >screen+[16*320],>screen+[17*320],>screen+[18*320],>screen+[19*320]
.byte >screen+[20*320],>screen+[21*320],>screen+[22*320],>screen+[23*320]
.byte >screen+[24*320]

tbl_8Lo:
.byte <0*8,<1*8,<2*8,<3*8,<4*8,<5*8,<6*8,<7*8,<8*8,<9*8
.byte <10*8,<11*8,<12*8,<13*8,<14*8,<15*8,<16*8,<17*8,<18*8,<19*8
.byte <20*8,<21*8,<22*8,<23*8,<24*8,<25*8,<26*8,<27*8,<28*8,<29*8
.byte <30*8,<31*8,<32*8,<33*8,<34*8,<35*8,<36*8,<37*8,<38*8,<39*8

tbl_8Hi:
.byte >0*8,>1*8,>2*8,>3*8,>4*8,>5*8,>6*8,>7*8,>8*8,>9*8
.byte >10*8,>11*8,>12*8,>13*8,>14*8,>15*8,>16*8,>17*8,>18*8,>19*8
.byte >20*8,>21*8,>22*8,>23*8,>24*8,>25*8,>26*8,>27*8,>28*8,>29*8
.byte >30*8,>31*8,>32*8,>33*8,>34*8,>35*8,>36*8,>37*8,>38*8,>39*8

// use mask to set / clear bit get /in-cell offset to point [0-7]

tbl_orbit:
.byte %10000000 //set bit mask
.byte %01000000
.byte %00100000
.byte %00010000
.byte %00001000
.byte %00000100
.byte %00000010
.byte %00000001

tbl_andbit: //clear bit mask
.byte %01111111
.byte %10111111
.byte %11011111
.byte %11101111
.byte %11110111
.byte %11111011
.byte %11111101
.byte %11111110
sin:
.fill 256, 60 + 40*sin(toRadians(i*360/256)) // Generates a sine curve or fill in your own

.pc = $4000 //bitmap memory
.fill 8000,0
.pc = $7c00 // screenmem (sets colors of bitmap when using bitmap)
.fill 1024,%00010000 //bit set color of 1 bit
