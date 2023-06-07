BasicUpstart2(start)

start:

        sei                     // disable interrupts

        lda #$7f                // turn off the CIA timer interrupt
        sta $dc0d               
        sta $dd0d

        // Setup Raster Interrupt

        lda #$7f                // clear high bit of raster line
        and $d011               
        sta $d011

        lda #50                // set raster interrupt to trigger on line 100
        sta $d012

        lda #<my_interrupt1      // set pointer for raster interrupt
        sta $0314
        lda #>my_interrupt1
        sta $0315
        
        lda #$01                // enable raster interrupt
        sta $d01a

        cli                     // enable interrupts

main_loop:
        
        // do some work here

        jmp main_loop


my_interrupt1:

        // Set bit 0 in Interrupt Status Register to acknowledge raster interrupt
        inc $d019

        // actual code goes here
        // ----------------------------------------------------------------------
        inc $d020

        // do some stuff
        ldx #200        
delay1:
        inx
        bne delay1

        dec $d020

        //-----------------------------------------------------------------------

        // configure raster interrupt for my_interrupt2

        lda #$7f                // clear high bit of raster line
        and $d011               
        sta $d011

        lda #200                // set raster interrupt to trigger on line 100
        sta $d012

        lda #<my_interrupt2      // set pointer for raster interrupt
        sta $0314
        lda #>my_interrupt2
        sta $0315

        // Restores A, X & Y registers and CPU flags before returing from Interrupt.
        jmp $ea81


my_interrupt2:

        // Set bit 0 in Interrupt Status Register to acknowledge raster interrupt
        inc $d019

        // actual code goes here
        // ----------------------------------------------------------------------
        inc $d020

        // do some stuff
        ldx #100        
delay2:
        inx
        bne delay2

        dec $d020

        //-----------------------------------------------------------------------

        // Configure raster interrupt for my_interrupt1

        lda #$7f                // clear high bit of raster line
        and $d011               
        sta $d011

        lda #50                // set raster interrupt to trigger on line 100
        sta $d012

        lda #<my_interrupt1      // set pointer for raster interrupt
        sta $0314
        lda #>my_interrupt1
        sta $0315

        // Restores A, X & Y registers and CPU flags before returing from Interrupt.
        jmp $ea81
