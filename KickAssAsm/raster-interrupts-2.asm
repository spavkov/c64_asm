// 10 sys2064

*=$0801

    .byte    $0b, $08, $0a, $00, $9e, $32, $30, $36, $34, $00, $00, $00
    
*=$0810

start:                   sei                             // set interrupt disabled flag to prevent interrupts

                        lda #$7f                        // c64 has system set to recieve interrupts from cia #1
                        sta $dc0d                       // so we need to disable those 

                        lda #<irq1                      // set lo-.byte of 
                        sta $0314                       // irq vector
                        lda #>irq1                      // set hi-.byte on
                        sta $0315                       // irq vector
                        
                        lda #$fa                        // set rasterline 
                        sta $d012                       // where we want interrupt
                        lda #$1b                        // set default value of $d011 with highest bit clear because 
                        sta $d011                       // it serve as highest bit of rasterline (for lines 256 - ...)
                        
                        lda #$00                        // lets clear last .byte of gfx bank
                        sta $3fff                       // so we dont get black artefacts on borders
                        
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

irq1:                    lda $d011                       // load $d011
                        and #$f7                        // and clear bit #3 to
                        sta $d011                       // set 24 rows mode

                        dec $d020                       // lets change border color so we see "where we are"
                        
                        ldx #$10                        // we need some delay before
dummydelay:             dex                             // we can change 25 rows back, 
                        bne dummydelay                 // so lets loop and wait a bit...
                        
                        lda $d011                       // load $d011
                        ora #$08                        // and set bit #3 to
                        sta $d011                       // set 25 rows mode

                        inc $d020                       // lets change border color back...
                        
                        lda #$ff                        // acknowledge all vic ii
                        sta $d019                       // interrupts

                        jmp $ea81                       // jump to last part of kernals regular interrupt service routine
                    
                    