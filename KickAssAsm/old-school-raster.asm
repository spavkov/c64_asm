// https://www.youtube.com/watch?v=VBMXnDGo1G8&ab_channel=RetroCoder
// https://github.com/Retro-Coder/OldSkool-Intro---Part--1---Rasters/blob/master/Main.asm

// 10 sys2064

*=$0801

    .byte    $0b,$08,$0a, $00, $9e, $32, $30, $36, $34, $00, $00, $00
    
*=$0810

start:                   sei                             // set interrupt disabled flag to prevent interrupts

                        lda #$7f                        // c64 has system set to recieve interrupts from cia #1
                        sta $dc0d                       // so we need to disable those 

                        lda #<irq1                      // set lo-.byte of 
                        sta $0314                       // irq vector
                        lda #>irq1                      // set hi-.byte on
                        sta $0315                       // irq vector
                        
                        lda #$32                        // set rasterline 
                        sta $d012                       // where we want interrupt
                        lda #$1b                        // set default value of $d011 with highest bit clear because 
                        sta $d011                       // it serve as highest bit of rasterline (for lines 256 - ...)
                        
                        lda $dc0d                       // acknowledge cia #1 interrupts incase they happened
                        lda #$ff                        // acknowledge all vic ii
                        sta $d019                       // interrupts
                        
                        lda #$01                        // and as last thing, enable raster interrupts on
                        sta $d01a                       // vic ii 
                        
                        cli                             // clear interrupt disabled flag to allow interrupts again
                        
waitspace:              lda $dc01                       // check if 
                        and #$10                        // space is pressed?
                        bne waitspace                  // if not, keep waiting...

                        jmp $fce2                       // reset c64...

irq1:                    ldy $d012                       // load current rasterline to y register
                        ldx #$3f                        // we want 64 lines of rasters, so load x with value 63 ($3f hex)
rastercolorloop:        lda rastercolors,x              // load color from table of raster colors with offset of x
rasterwait:             cpy $d012                       // is rasterline still same?
                        beq rasterwait                 // loop as long as it is
                        sta $d021                       // set color if it"s new rasterline
                        
                        iny                             // increment y register by 1 for next line comparison
                        dex                             // decrement x so we get different color for next line
                        bpl rastercolorloop            // result is still positive we have lines left so loop...

                        ldx #$08                        // small delay loop
dummydelay:             dex                             // to time next color change
                        bne dummydelay                 // 
                        lda #$06                        // change background                     
                        sta $d021                       // color to dark blue
                        
                        // nop                           // extra delay for ntsc version of c64...
                                                        // correct timings are depending how many cycles there are
                                                        // on each raster line... 
                        
                        lda #$ff                        // acknowledge all vic ii
                        sta $d019                       // interrupts

                        jsr moverasters                 
                        
                        jmp $ea81                       // jump to last part of kernals regular interrupt service routine
                  
moverasters:            ldx #$37                        // loop
moveloop:               lda rastercolors,x              // to move
                        sta rastercolors+8,x            // raster colors 8 pixels different position
                        dex                             // to create one character high line of moving
                        bpl moveloop                   // colorblocks
                        
                        ldx #$07                        // we need 8 more colors (0..7 = 8)...
                        ldy colorpos                    // read position in our colorbar table to y
newcolorsloop:          tya                             // transfer y to a
                        and #$3f                        // 64 colors in colorbars, so limit value to $00..$3f (0..64 dec) 
                        tay                             // transfer a back to y
                        lda colorbars,y                 // load color from colorbars with offset of y
                        sta rastercolors,x              // store new color to rastercolors with offset of x
                        iny                             // increment y
                        dex                             // decrement x
                        bpl newcolorsloop              // result is still positive we have lines left so loop...
                        inc colorpos                    // increase value of colorposition with 1
                        rts                             // we"re done so return
                                  
colorpos:                .byte $00                        // position in our colorbar table

rastercolors:            
                        .byte $00, $00,$00,$00,$00,$00,$00,$00,$00                    // define constant bytes, $40 .bytes (64 dec) of value $00
                        .byte $00, $00,$00,$00,$00,$00,$00,$00,$00                    // define constant bytes, $40 .bytes (64 dec) of value $00
                        .byte $00, $00,$00,$00,$00,$00,$00,$00,$00                    // define constant bytes, $40 .bytes (64 dec) of value $00
                        .byte $00, $00,$00,$00,$00,$00,$00,$00,$00                    // define constant bytes, $40 .bytes (64 dec) of value $00
                        .byte $00, $00,$00,$00,$00,$00,$00,$00,$00                    // define constant bytes, $40 .bytes (64 dec) of value $00
                        .byte $00, $00,$00,$00,$00,$00,$00,$00,$00                    // define constant bytes, $40 .bytes (64 dec) of value $00
                        .byte $00, $00,$00,$00,$00,$00,$00,$00,$00                    // define constant bytes, $40 .bytes (64 dec) of value $00

colorbars:              .byte $00, $00, $09, $09, $08, $08, $0a, $0a     // brown orange
                        .byte $07, $07, $01, $01, $07, $07, $0a, $0a     // yellowish
                        .byte $08, $08, $09, $09, $00, $00, $00, $00     // color bar
                        .byte $00, $00, $00, $00, $00, $00, $00, $00     // 

                        .byte $00, $00, $0b, $0b, $05, $05, $03, $03     // greenish
                        .byte $0d, $0d, $01, $01, $0d, $0d, $03, $03     // color bar
                        .byte $05, $05, $0b, $0b, $00, $00, $00, $00     // 
                        .byte $00, $00, $00, $00, $00, $00, $00, $00     // 