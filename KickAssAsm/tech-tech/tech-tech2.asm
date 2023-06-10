// vim: set et ts=8 sw=8 sts=8 syntax=64tass :
//
// simple tech-tech using fli, 112 pixels wide sinus, using one charset and
// 14 videoram banks in $4000-$7fff.
//
//
// 2016-04-20
 
 
        // music, a nice old school jch tune
        music_sid ="/home/compyx/c64/hvsc/musicians/j/jch/ninjackie.sid"
        music_init = $1000
        music_play = $1003
 
 
        // height of the tech-tech in pixels
        techtech_height = 88
 
        // size of a single line of fli code
        techtech_macro_len = 15
 
        // location of the fli-bug cover sprite
        cover_sprite = $7f80
 
        // zero page
        zp = $14
 
 
        // basic sys line: sys2061
        * = $0801
        ..word (+), 2016
        .null $9e, ^start
+       ..word 0
 
// entry point
start:
        jsr $fda3
        jsr $fd15
        // jsr $ff5b
        sei
        lda #0
        sta $d020
        sta $d021
        jsr tt_setup
        lda #0
        jsr music_init
        lda #$35
        sta $01
        lda #$7f
        sta $dc0d
        sta $dd0d
        lda #0
        sta $dc0e
        lda #$01
        sta $d01a
        lda #$1b
        sta $d011
        lda #$2e
        ldx #<irq1
        ldy #>irq1
        sta $d012
        stx $fffe
        sty $ffff
        ldx #<break
        ldy #>break
        stx $fffa
        sty $fffb
        stx $fffc
        sty $fffd
        bit $dc0d
        bit $dd0d
        inc $d019
        cli
        jmp *
 
// irq: use the "double irq" trick to stabilize the raster
irq1:
        pha
        txa
        pha
        tya
        pha
        lda #$2e
        ldx #<irq2
        ldy #>irq2
        sta $d012
        stx $fffe
        sty $ffff
        lda #1
        inc $d019
        tsx
        cli
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
irq2:
        txs
        ldx #8
-       dex
        bne -
        bit $ea
        lda $d012
        cmp $d012
        beq +
+
        // raster is stable here
        clc
        lda #$32
        sta $d001
        adc #42
        sta $d003
        lda #0
        sta $d027
        sta $d028
        lda #%00000011  // stretch cover sprites in x and y direction
        sta $d017
        sta $d015
        sta $d01d
        lda #$08        // we need to conver the first four chars on screen,
        sta $d000       // since we have the classic three char fli bug and we
        sta $d002       // need one more char to cover since we use $d016, which
        lda #$7b        // scrolls the fli bug into the screen
        sta $d011
        lda #2
        sta $dd00
 
        // waste some cycles to start the fli routine at the correct time
        ldx #7
-       dex
        bne -
        nop
        nop
        nop
 
        // the unrolled tech-tech fli routine
        jsr tt_unrolled
        // use invalid graphics mode to cover bugs
        lda #$7b
        sta $d011
        lda #$03
        sta $dd00
        lda #$15
        sta $d018
        lda #8
        sta $d016
        ldx #89         // waste cycles until we"ve covered a full screen row
-       dex
        bne -
        lda #$1b
        sta $d011
 
 
        lda #$98
        ldx #<irq3
        ldy #>irq3
        sta $d012
        stx $fffe
        sty $ffff
        lda #1
        sta $d019
        pla
        tay
        pla
        tax
        pla
break:   rti
 
irq3:
        pha
        txa
        pha
        tya
        pha
        dec $d020
        jsr tt_sinus_unrolled   // calculate the tech-tech"s sinus data
        dec $d020
        jsr music_play
        lda #0
        sta $d020
        lda #$2d
        ldx #<irq1
        ldy #>irq1
        sta $d012
        stx $fffe
        sty $ffff
        lda #1
        sta $d019
        pla
        tay
        pla
        tax
        pla
        rti
 
 
// tech-tech setup code
tt_setup:
        // copy chargen
        //
        // for the "logo", we use the cbm font
        lda #$32
        sta $01
        ldx #0
-       lda $d000,x
        sta $4000,x
        lda $d100,x
        sta $4100,x
        lda $d200,x
        sta $4200,x
        lda $d300,x
        sta $4300,x
        lda $d400,x
        sta $4400,x
        lda $d500,x
        sta $4500,x
        lda $d600,x
        sta $4600,x
        lda $d700,x
        sta $4700,x
        inx
        bne -
 
//        ldx #7
//        lda #0
//-       sta $47f8,x
//        dex
//        bpl -
 
        // generate fli-bug cover sprite
        ldx #$3f
        lda #$ff
-       sta cover_sprite,x
        dex
        bpl -
 
        // set up the videoram banks for the tech-tech effect
        //
        // the first videoram bank at $4800 contains the "logo" in its
        // default (left-aligned) position, every next videoram bank contains
        // the "logo" shifted one column to the right. this is what makes the
        // tech-tech effect possible.
        //
        // right now, for the "logo", we simply copy the basic screen data
        // from $0400
        ldx #0
-
        lda $0400,x
        sta $4800,x
        sta $4c00 + 1,x
        sta $5000 + 2,x
        sta $5400 + 3,x
        sta $5800 + 4,x
        sta $5c00 + 5,x
        sta $6000 + 6,x
        sta $6400 + 7,x
        sta $6800 + 8,x
        sta $6c00 + 9,x
        sta $7000 + 10,x
        sta $7400 + 11,x
        sta $7800 + 12,x
        sta $7c00 + 13,x
 
        lda $0500,x
        sta $4900,x
        sta $4d00 + 1,x
        sta $5100 + 2,x
        sta $5500 + 3,x
        sta $5900 + 4,x
        sta $5d00 + 5,x
        sta $6100 + 6,x
        sta $6500 + 7,x
        sta $6900 + 8,x
        sta $6d00 + 9,x
        sta $7100 + 10,x
        sta $7500 + 11,x
        sta $7900 + 12,x
        sta $7d00 + 13,x
        inx
        bne -
 
        // make last tech-tech line use invalid $d011 mode to mask bug
        lda #((techtech_height - 1) & 7 | $78)
        sta tt_unrolled + ((techtech_height - 1) * techtech_macro_len) + 1
 
        // set cover sprite pointers for each videoram bank used
        lda #$f8
        ldx #$4b
        sta zp
        stx zp + 1
        ldx #0
-
        lda #(cover_sprite & $3fff) / 64
        ldy #0
        sta (zp),y
        iny
        sta (zp),y
        lda zp + 1
        clc
        adc #4
        sta zp + 1
        inx
        cpx #14
        bne -
 
        jsr tt_sinus_precalc
 
        lda #$37
        sta $01
        rts
 
 
// precalcute sinus data
//
tt_sinus_precalc:
        ldx #0
        ldy #0
-       lda sinus,y
        and #7
        sta sinus_d016,x
        sta sinus_d016 + 256,x
        lda sinus,y             // divide by 8, multiply by 16 to get videoram
                                // index
        asl
        and #$f0
        adc #$20                // c is clear
        sta sinus_d018,x
        sta sinus_d018 + 256,x
        tya
        clc
        adc #1
        tay
        inx
        bne -
        rts
 
 
        .cerror * > $0fff, "code too long"
 
 
 
// link music
        * = $1000
.binary music_sid, $7e
 
 
 
 
// a single rasterline of fli-code to display the tech-tech
//
// param 1: row number (used to calculate the correct $d011 value)
//
// we trigger a badline condition at each rasterline to trigger a videoram
// update which we use to alter the videoram bank
//
ttmacro: .macro
        lda #$18 + ((\1 + 3) & 7)
        sta $d011
        lda #$20        // gets updated in the sinus routine
        sta $d018
        lda #$08        // gets updated in the sinus routine
        sta $d016
        .endm
 
 
        * = $2000
 
// the tech-tech display routine: a simple unrolled fli routine which also sets
// $d016 at each line
tt_unrolled:
.for row = 0, row < techtech_height, row = row + 1
        #ttmacro row
.next
        rts
 
 
 
        .align 256
// unrolled sinus updating routine
//
// uses two tables of 512 .bytes each, to allow for x index overflow (we add
// an offset to each sinus_d016 and sinus_d018 table for each row, combine that
// with x register indexing and we would go past the 256-.byte mark in a table)
tt_sinus_unrolled:
_index:  ldx #0
 
.for row = 0, row < techtech_height, row = row + 1
        lda sinus_d018 + row,x
        sta tt_unrolled + (row * techtech_macro_len) + 6
        lda sinus_d016 + row,x
        sta tt_unrolled + (row * techtech_macro_len) + 11
.next
        lda _index + 1
        clc
        adc #2
        sta _index + 1
        rts
 
// sinus used for the tech-tech effect: 112 pixels wide since we use 14
// videoram banks
        .align 256
sinus:
        ..byte 55.5 + 56 * cos(range(256) * rad(360.0/256))
 
 
// precalculated $d016 values
sinus_d016:
        .fill 512, 0
 
// precalculated $d018 values
sinus_d018:
        .fill 512,0