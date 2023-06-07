//coded by Bitbreaker Oxyron ^ Nuance ^ Arsenic
//feel free to change $d020/$d021 to other registers like $d022/$d023 for effects with multicolor charsets
//as you see, there are plenty of cycles free for more action.
 
BasicUpstart2(start)			// <- This creates a basic sys basic line that can start your program
 
.label tmpa    = $22
.label tmpx    = $23
.label tmpy    = $24
.label tmp_1   = $25
 
 start:
         sei
         lda #$7f
         sta $dc0d
         lda $dc0d
         lda #$01
         sta $d01a
         sta $d019
         lda #$32
         sta $d012
         lda $d011
         and #$3f
         sta $d011
         lda #$34
         sta $01
         lda #<irq1
         sta $fffe
         lda #>irq1
         sta $ffff
         cli
         jmp *
 
irq1:
         //irq enter stuff
         sta tmpa
         stx tmpx
         sty tmpy
         lda $01
         sta tmp_1
         lda #$35
         sta $01
         dec $d019
 
         ldx #$01
         dex
         bpl *-1
 
         //do raster
         jsr raster
 
         //exit irq
         lda tmp_1
         sta $01
         ldy tmpy
         ldx tmpx
         lda tmpa
         rti
 
raster:  
         ldx #$00
minusminus:
         ldy #$07       //2
 
         lda tab,x      //4
         sta $d020      //4
         sta $d021      //4
         inx            //2
         cpx #$c8       //2
         beq plus          //2
         nop            //2 _20
minus:
         lda tab,x      //4
         sta $d020      //4
         sta $d021      //4
         jsr plus         //12
         jsr plus          //12
         jsr plus         //12 _48
         nop            //2
         inx            //2
         cpx #$c8       //2
         beq plus          //2
         dey            //2
         beq minusminus         //2 / 3 _61 (+2)
         bne minus          //3     _63
plus:
         rts
 
//align 255, 0
 
//your colors go here
tab:
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"
        .text "kloaolk"