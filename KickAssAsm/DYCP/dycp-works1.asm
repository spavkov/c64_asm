// tutorial here: http://www.antimon.org/dl/c64/code/dycp.txt

.label sinus=  $cf00   // place for the sinus table
.label chrset= $3800   // here begins the character set memory
.label gfx=    $3c00   // here we plot the dycp data
.label x16=    $ce00   // values multiplicated by 16 (0,16,32..)
.label d16=    $ce30   // divided by 16  (16 x 0,16 x 1 ...)
.label start=  $033c   // pointer to the start of the sinus
.label counter= $033d  // scroll counter (x-scroll register)
.label pointer= $033e  // pointer to the .text char
.label ypos=   $0340   // lower 4 bits of the character y positions
.label yposh=  $0368   // y positions divided by 16
.label char=   $0390   // scroll .text characters, multiplicated by eight
.label zp=     $fb     // zeropage area for indirect addressing
.label zp2=    $fd
.label amount= 38      // amount of chars to plot-1
.label padchar= 32     // code used for clearing the screen

BasicUpstart2(bootstart)

bootstart:

        sei             // disable interrupts
        lda #$32        // character generator rom to address space
        sta $01
        ldx #0
loop0:  lda $d000,x     // copy the character set
        sta chrset,x
        lda $d100,x
        sta chrset+256,x
        dex
        bne loop0
        lda #$37        // normal memory configuration
        sta $01
        ldy #31
       
       
loop1:  lda #66         //   compose a full sinus from a 1/4th of a
        clc             //   cycle
        adc sin,x
        sta sinus,x
        sta sinus+32,y
        lda #64
        sec
        sbc sin,x
        sta sinus+64,x
        sta sinus+96,y
        inx
        dey
        bpl loop1
        ldx #$7f
loop2:   lda sinus,x
        lsr
        clc
        adc #32
        sta sinus+128,x
        dex
        bpl loop2

        ldx #39
loop3:  txa
        asl
        asl
        asl
        asl
        sta x16,x       // multiplication table (for speed)
        txa
        lsr
        lsr
        lsr
        lsr
        clc
        adc #>gfx
        sta d16,x       // dividing table
        lda #0
        sta char,x      // clear the scroll
        dex
        bpl loop3
        sta pointer     // initialize the scroll pointer
        ldx #7
        stx counter
loop10: sta chrset,x    // clear the -sign..
        dex
        bpl loop10

        lda #>chrset    // the right page for addressing
        sta zp2+1
        lda #<irq       // our interrupt handler address
        sta $0314
        lda #>irq
        sta $0315
        lda #$7f        // disable timer interrupts
        sta $dc0d
        lda #$81        // enable raster interrupts
        sta $d01a
        lda #$a8        // raster compare to scan line $a8
        sta $d012
        lda #$1b        // 9th bit
        sta $d011
        lda #30
        sta $d018       // use the new charset
        cli             // enable interrupts and return
        rts

irq:    inc start       // increase counter
        ldy #amount
        ldx start
loop4:  lda sinus,x     // count a pointer for each .text char and according
        and #7          //  to it fetch a y-position from the sinus table
        sta ypos,y      //   then divide it to two .bytes
        lda sinus,x
        lsr
        lsr
        lsr
        sta yposh,y
        inx             // chars are two positions apart
        inx
        dey
        bpl loop4

        lda #0
        ldx #79
loop11:  sta gfx,x       // clear the dycp data
        sta gfx+80,x
        sta gfx+160,x
        sta gfx+240,x
        sta gfx+320,x
        sta gfx+400,x
        sta gfx+480,x
        sta gfx+560,x
        dex
        bpl loop11

make:    lda counter     // set x-scroll register
        sta $d016
        ldx #amount
        clc             // clear carry
loop5:   ldy yposh,x     // determine the position in video matrix
        txa
        adc linesl,y    // carry won"t be set here
        sta zp          // low .byte
        lda #4
        adc linesh,y
        sta zp+1        // high .byte
        lda #padchar    // first clear above and below the char
        ldy #0          // 0. row
        sta (zp),y
        ldy #120        // 3. row
        sta (zp),y
        txa             // then put consecuent character codes to the places
        asl             //  carry will be cleared
        ora #$80	// inverted chars
        ldy #40         // 1. row
        sta (zp),y
        adc #1          // increase the character code, carry won"t be set
        ldy #80         // 2. row
        sta (zp),y

        lda char,x      // what character to plot ? (source)
        sta zp2         //  (char is already multiplicated by eight)
        lda x16,x       // destination low .byte
        adc ypos,x      //  (16*char code + y-position"s 3 lowest bits)
        sta zp
        lda d16,x       // destination high .byte
        sta zp+1

        ldy #6          // transfer 7 .bytes from source to destination
        lda (zp2),y
        sta (zp),y
        dey             // this is the fastest way i could think of.
        lda (zp2),y
        sta (zp),y
        dey
        lda (zp2),y
        sta (zp),y
        dey
        lda (zp2),y
        sta (zp),y
        dey
        lda (zp2),y
        sta (zp),y
        dey
        lda (zp2),y
        sta (zp),y
        dey
        lda (zp2),y
        sta (zp),y
        dex
        bpl loop5	// get next char in scroll

        lda #1
        sta $d019       // acknowledge raster interrupt

        dec counter     // decrease the counter = move the scroll by 1 pixel
        bpl out
loop12:  lda char+1,y    // move the .text one position to the left
        sta char,y      //  (y-register is initially zero)
        iny
        cpy #amount
        bne loop12
        lda pointer
        and #63         // text is 64 .bytes long
        tax
        lda scroll,x    // load a new char and multiply it by eight
        asl
        asl
        asl
        sta char+amount // save it to the right side
        dec start       // compensation for the .text scrolling
        dec start
        inc pointer     // increase the .text pointer
        lda #7
        sta counter     // initialize x-scroll

out:     jmp $ea7e       // return from interrupt


sinus2addedbyme: //dycp
 .byte 15,17,19,21,23,25
      .byte 27,29,30,32,33,34
      .byte 34,35,35,35,35,34
      .byte 33,32,31,29,28,26
      .byte 24,22,20,18,16,14
      .byte 12,10,8,7,5,4
      .byte 3,2,1,1,1,1
      .byte 2,2,3,4,6,7
      .byte 9,11,13,15,17,19
      .byte 21,23,25,27,28,30
      .byte 31,33,34,34,35,35
      .byte 35,35,34,33,32,31
      .byte 30,28,26,25,23,21
      .byte 18,16,14,12,10,9
      .byte 7,5,4,3,2,2
      .byte 1,1,1,1,2,3
      .byte 4,5,7,9,10,12
      .byte 14,16,18,20,22,24
      .byte 26,28,30,31,32,33
      .byte 34,35,35,35,35,34
      .byte 34,33,31,30,28,27
      .byte 25,23,21,19,17,15
      .byte 13,11,9,7,6,4
      .byte 3,2,2,1,1,1
      .byte 1,2,3,4,5,7
      .byte 8,10,12,14,16,18
      .byte 20,22,24,26,28,29
      .byte 31,32,33,34,35,35
      .byte 35,35,34,34,33,32
      .byte 30,29,27,25,23,21
      .byte 19,17,15,13,11,9
      .byte 8,6,5,3,2,2
      .byte 1,1,1,1,2,3
      .byte 4,5,6,8,10,11
      .byte 13,15,18,20,22,24
      .byte 26,27,29,31,32,33
      .byte 34,34,35,35,35,35
      .byte 34,33,32,31,29,27
      .byte 26,24,22,20,18,16
      .byte 14,12,10,8,6,5
      .byte 4,3,2,1,1,1
      .byte 1,2,2,3,5,6
      .byte 8,9,11,13     

sin:    .byte 0,3,6,9,12,15,18,21,24,27,30,32,35,38,40,42,45
        .byte 47,49,51,53,54,56,57,59,60,61,62,62,63,63,63
                        // 1/4 of the sinus

linesl:  .byte 0,40,80,120,160,200,240,24,64,104,144,184,224
        .byte 8,48,88,128,168,208,248,32

linesh:  .byte 0,0,0,0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,2,3

scroll:  .text "thisisanexamplescrollfor"
        .text "commodoremagazinebypasiojala"
                        // scr will convert .text to screen codes
