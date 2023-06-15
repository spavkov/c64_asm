/*
How to remove upper and lower border

KickAssembler syntax

w8 for rasterline $fa
set rows to 24
w8 for rasterline $fc
set rows to 25

borders gone

https://web.archive.org/web/20140226123633/http://c64assembly.elorama.se/

*/

:BasicUpstart2(oloop) // 2049 dec

oloop:

lda #$a8
//jsr $ffd2 // just delay visual

lda #$f9
cmp $d012
bne *-3

inc cc
bne oloop
dec cc+1 //just aw8 on cc+1 to be 0
bne oloop

start:
sei
loop:
lda #$bd // pattern for "border gfx"
sta $3fff

lda #$fa // Remove borders up/down f9
w81:

cmp $d012 // w8 rast line
bne w81
dec $d020
inc $d020

lda $d011
and #%11110111 //24 rows
sta $d011

lda #$fc
cmp $d012 // w8 rast line
bne * -3

lda $d011
ora #%00001000 //25 rows
sta $d011

jmp loop

cc: .byte 0,2