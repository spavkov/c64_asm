// found here and translated via google translator: https://www.retro-programming.de/programming/nachschlagewerk/interrupts/der-rasterzeileninterrupt/

.label raster   = $d012  // current raster line
.label intflag  = $d019  // interrupt flag reg
.label frame_color_register    = $d020  // frame color
.label border_color_register   = $d021  // border color
.label interrupt_control_register = $d01a  // border color

.label irq_vector_low   = $0314  // border color
.label irq_vector_high   = $0315  // border color

BasicUpstart2(start)
start:
    sei
    
    lda #%01111111
    sta $dc0d

    and $d011
    sta $d011

    lda $dc0d
    lda $dd0d

    lda #<irq_1
    sta irq_vector_low
    lda #>irq_1
    sta irq_vector_high

    lda #$00       // we tell the VIC that we want to start from line 00
    sta $d012      // by putting #%00 to $do12
    lda $d011      // we load whats in $d011
    and #%01111111 // and then switch off the 8th bit by using AND
    sta $d011      // and we then store this back to $d011
                   // since the IRQ should be triggered in line 0 and not accidentally in the 256th line, the 8th bit of the raster line in $d011 is then also deleted
                   // because 8th bit of $d011 is the most significant bit of the VIC's nine-bit raster register see here: https://sta.c64.org/cbm64mem.html

    lda interrupt_control_register      // load whats in the interrupt control register
    ora #%00000001                      // enable raster interrupt bit (bit 0) on the vic
    sta interrupt_control_register      // store this back to register
    cli
    rts

irq_1:   



    lda $d019
    bmi real_raster_interrupt1
    lda $dc0d
    cli;
    jmp $ea31


real_raster_interrupt1:
    lda #%00000001 // clear $d019 bit 0 to acknowledge the interrupt
    sta $d019

    lda #$00
    sta border_color_register

    // we setup the next interrupt address  
    lda #<irq2
    sta $0314
    lda #>irq2
    sta $0315

    lda #$90  // next raster line irq
    sta $d012
    lda $d011      // we load whats in $d011
    and #%01111111 // and then switch off the 8th bit by using AND
    sta $d011      // and we then store this back to $d011    

    // Check if VIC triggered this interrupt (bit 7=1 of $d019)
    //lda $d019
    //tax // save accumulator to X register
    //and #%10000000 // this mask sets all bits to zero except the most significant bit (7th) 
    // we AND that mask with accumulator with value from $d019 
    //bne raster_interrupt_begin // so if result is zero then its not raster interrupt, but if its not equal to zero it means we are in raster interrupt
    //txa
    // Load interrupt control reg
    // This will clear all inter-
    // rupts
    //lda $dc0d
    //cli       // enable interrupts
    // Jump to entry point of normal
    // interrupt routine if no
    // raster compare IRQ triggered
    jmp $ea31

irq2:

    lda #%00000001 // clear $d019 bit 0 to acknowledge the interrupt
    sta $d019

    lda #$01
    sta border_color_register    

    // setup to again go to first interrupt address next time
    lda #<irq_1
    sta irq_vector_low
    lda #>irq_1
    sta irq_vector_high

    lda #$00       // we tell the VIC that we want to start from line 00
    sta $d012      // by putting #%00 to $do12
    lda $d011      // we load whats in $d011
    and #%01111111 // and then switch off the 8th bit by using AND
    sta $d011      // and we then store this back to $d011
                   // since the IRQ should be triggered in line 0 and not accidentally in the 256th line, the 8th bit of the raster line in $d011 is then also deleted
                   // because 8th bit of $d011 is the most significant bit of the VIC's nine-bit raster register see here: https://sta.c64.org/cbm64mem.html

    jmp $ea31  
