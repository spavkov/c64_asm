.label bank=   $96     // the value of the video bank register (cia2) in the tech-area
.label zp=     $fb     // zero page for indirect addressing
.label start=  $4400   // start of the charsets (we use inverted chars)
.label screen= $4000   // position of the video matrix
.label shiftl= $cf00   // x-shift, lowest 3 bits
.label shifth= $ce00   // x-shift, highest 3 bittid (multiplied with two)
.label pointer= $033c  // pointer to shift-table
.label value=  $033d   // shift now
.label speed=  $033e   // shift change

*= $c000  // start address..

init:    sei             // disable interrupts
        lda #$7f
        sta $dc0d       // disable timer interrupt
        lda #$81
        sta $d01a       // enable raster interrupt
        lda #<irq
        sta $0314       // our own interrupt handler
        lda #>irq
        sta $0315
        lda #49         // the interrupt to the line before the first bad line
        sta $d012
        lda #$1b
        sta $d011       // 9th bit of the raster compare

        ldy #0
        ldx #$40
        stx zp+1
        sty zp
        tya
loop0:   sta (zp),y      // clear the whole video bank ($4000-7fff)
        iny
        bne loop0
        inc zp+1
        bpl loop0

        lda #>start
        sta zp+1
        lda #$32        // character rom to address space ($d000-)
        sta $01
loop1:   tya             // (y-register is zero initially)
        lsr
        lsr
        lsr
        tax
        lda text,x      // which char to plot ?
        asl             // source
        asl
        asl
        tax             // low .byte to x
        lda #$d0
        adc #0          // high .byte (one bit) taken into account
        sta loop2+2 // self-modifying again..
loop2:   lda $d000,x
        sta (zp),y
        inx
        iny
        txa
        and #7
        bne loop2       // copy one char
        cpy #0
        bne loop1       // copy 32 chars (256 .bytes)
        lda #$37        // memory configuration back to normal
        sta $01

loop3:   lda start,y       // copy the data to each charset, shifted by one
        sta start+2056,y  //  position to the right
        sta start+4112,y
        sta start+6168,y
        sta start+8224,y
        sta start+10280,y
        sta start+12336,y
        sta start+14392,y
        iny
        bne loop3
        lda #0          // clear the pointer, value and speed
        sta pointer
        sta value
        sta speed

loop4:   tya             // (y was zero)
        ora #$80        // use the inverted chars
        sta screen,y    // set the character codes to video matrix
        sta screen+40,y
        sta screen+80,y
        sta screen+120,y
        sta screen+160,y
        sta screen+200,y
        sta screen+240,y
        sta screen+280,y
        lda #239        // leave the last line empty
        sta screen+320,y
        iny
        cpy #40
        bne loop4       // loop until the whole area is filled
        cli             // enable interrupts
        rts

irq:     lda #bank       // change the video bank, some timing
        sta $dd00
        nop
        nop

        ldy pointer     // y-register will point to x-shift
        jmp bad         // next line is a bad line
loop5:   nop
loop6:   lda shiftl,y    // do the shift
        sta $d016       // 3 lowest bits
        lda shifth,y
        sta $d018       // another 3 bits
        nop 
        nop
        nop
        nop
        nop
        nop // waste some time
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        lda $d012       // check if it is time to stop
        cmp #$78
        bpl over
        iny   // next position in table
        dex
        bne loop5       // no bad line, loop
bad:     lda shiftl,y    // this is a bad line, a bit more hurry
        sta $d016
        lda shifth,y
        sta $d018
        iny
        ldx #7          // new bad line coming up
        jmp loop6

over:    lda #$97        // video bank to "normal"
        sta $dd00
        lda #22         // same with the charset
        sta $d018
        lda #8          // and the horizontal scroll register
        sta $d016

        lda $dc00       // let"s check the joysticks
        and $dc01
        tax
        ldy speed
        and #8          // turned right, add speed
        bne eip
        iny
        cpy #4          // don"t store, too much speed
        bpl eip
        sty speed
eip:     txa
        and #4          // turned left
        bne ulos
        dey
        cpy #$fc        // too much ?
        bmi ulos
        sty speed
ulos:    lda value       // add speed to value (signed)
        clc
        adc speed
        bpl ok
        lda speed       // banged to the side ?
        eor #$ff
        clc
        adc #1
        sta speed
        lda value
ok:      sta value
        lsr             // value is twice the shift
        tax             // remember the shift
        and #7          // lowest 3 bits
        ora #8          // (screen 40 chars wide)
        ldy pointer
        sta shiftl,y
        txa
        lsr
        lsr
        lsr             // highest 3 bits too
        asl             //  multiplicated by two
        sta shifth,y
        dec pointer

        lda #1          // ack the interrupt
        sta $d019
        jmp $ea31       // the normal interrupt routine

text:    .text "this is tech-tech for c=64 by me" // test .text
                        // scr converts to screen codes
