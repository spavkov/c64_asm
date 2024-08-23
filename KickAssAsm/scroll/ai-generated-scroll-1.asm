BasicUpstart2(init)


init:
        sei                    // disable interrupts
        ldx #$ff               // initialize stack
        txs
        lda #$00
        sta $d020              // set border color to black
        sta $d021              // set background color to black
        lda #$1b
        sta $d011              // set screen control register

        ldx #$00
        ldy #$04               // load y with number of rows (5 in this case)
clearscreen:
        lda #$20               // ascii space character
        sta $0400, x           // clear screen memory
        sta $0500, x           // clear screen memory
        inx
        bne clearscreen        // loop until screen memory is clear
        dey
        bpl clearscreen

        ldx #$00               // initialize scroll position
        ldy #$00

mainloop:
        lda message, x         // load character from message
        beq endscroll          // if zero .byte, end of message
        sta $0400, y           // store character in screen memory
        inx
        iny
        cpy #$28               // 40 columns wide screen
        bne mainloop           // if not the end of the line, continue

scroll:
        lda $d016              // load vic-ii control register
        and #$ef               // mask out the lower bit (disable horizontal scroll)
        sta $d016              // reset scroll
        lda $d016
        ora #$01               // set horizontal scroll bit
        sta $d016

        lda #$00               // delay loop
        ldy #$00
delayloop:
        iny
        bne delayloop

        dec scrollpos          // move .text to the left
        bpl scroll

        ldx scrollpos
        bne mainloop           // repeat scrolling

endscroll:
        jmp init              // loop forever

scrollpos:
        .byte $28              // initial scroll position

message:
        .text "hello c64 fans! " // your message goes here
        .byte $00              // end of message marker