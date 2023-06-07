BasicUpstart2(start)			// <- This creates a basic sys basic line that can start your program

start:
           sei          // turn off interrupts
           lda #$7f
           ldx #$01
           sta $dc0d    // Turn off CIA 1 interrupts
           sta $dd0d    // Turn off CIA 2 interrupts
           stx $d01a    // Turn on raster interrupts

           lda #$1b
           ldx #$08
           ldy #$14
           sta $d011    // Clear high bit of $d012, set .text mode
           stx $d016    // single-colour
           sty $d018    // screen at $0400, charset at $2000

           lda #<int1    // low part of address of interrupt handler code
           ldx #>int1   // high part of address of interrupt handler code
           ldy #$32     // line to trigger interrupt
           sta $0314    // store in interrupt vector
           stx $0315
           sty $d012

           lda $dc0d    // ACK CIA 1 interrupts
           lda $dd0d    // ACK CIA 2 interrupts
           asl $d019    // ACK VIC interrupts
           cli

loop:
           jmp loop     // infinite loop

int1:
           lda #$01
           sta $d020    // flash border

           lda #<int2    // low part of address of interrupt handler code
           ldx #>int2   // high part of address of interrupt handler code
           ldy #$61     // line to trigger interrupt
           sta $0314    // store in interrupt vector
           stx $0315
           sty $d012

           asl $d019    // ACK interrupt (to re-enable it)
           pla
           tay
           pla
           tax
           pla
           rti          // return from interrupt

int2:
           lda #$02
           sta $d020    // flash border

           lda #<int1    // low part of address of interrupt handler code
           ldx #>int1   // high part of address of interrupt handler code
           ldy #$30     // line to trigger interrupt
           sta $0314    // store in interrupt vector
           stx $0315
           sty $d012

           asl $d019    // ACK interrupt (to re-enable it)
           pla
           tay
           pla
           tax
           pla
           rti          // return from interrupt           