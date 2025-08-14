//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-//
// Flashparty 2021 - 256-.bytes intro
// C64 part
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-//
//
// LIA: http://lia.rebelion.digital/
// code: riq (http://retro.moe)
//
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-//

.label CHARROM = $d000
.label CHARROM_COPY = $3800
.label PRINT_CHAR = $e716                      // Print char to screen. Like $ffd2 but
                                        // more direct. Skips some checks.

.label ZP_CHARROM_PTR_LSB = $88                // Choosing $88/$89 pair, since $89 is
.label ZP_CHARROM_PTR_MSB = $89                // already #$d0, the MSB of $d000
.label ZP_SOLID_CHAR = $80                     // Contains a good default value to print

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-//
// CODE
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-//

*= $087d                                // Start address

        // All chars are multiplied by 8 so that they can be the offset to the charrom
       // .enc "screen"
msg0:
        // Black color must always land in an empty .word to avoid adding
        // the "if color==black" inc, which cost more .bytes than just adding
        // a fews "0" here.
        .text "A" 
        .text "M" 
        .text "O" 
        .text "R" 
        .byte 0
        .text "P" 
        .text "A" 
        .text "R" 
        .text "A" 
        .byte 0
        .text "D" 
        .text "O" 
        .text "S" 
        .byte 0
        .text "B" 
        .text "E" 
        .text "S" 
        .text "I" 
        .text "T" 
        .text "O" 
        .text "S" 
        .byte 0
        .text "P" 
        .text "A" 
        .text "R" 
        .text "A" 
        .byte 0
        .text "F" 
        .text "L" 
        .text "A" 
        .text "S" 
        .text "H" 
        .text "P" 
        .text "A" 
        .text "R" 
        .text "T" 
        .text "Y" 
        .byte 0
        .text "S" 
        .text "A" 
        .text "L" 
        .text "U" 
        .text "D" 
        .text "O" 
        .text "S" 
        .byte 0
        .text "G"                    // This last .word is not printed when color
        .text "E"                    // is Black, or when the char to print is empty.
        .text "N"                    // The last two .words "saludos gente" were chosen
        .text "T"                    // on purpose so that if "gente" is not printed
        .text "E"                    // it doesn"t affect the meaning of the sentence.

        // End of message is "$8e", which is the opcode of "stx"

        // "SYS" jumps to this address
        stx $d020                       // Black border/background
        stx $d021
        iny                             // It might be possible to skip this instruction
                                        // if the scroller ends with letter "Y"
        sty $0286                       // White foreground

main_loop:
.label msg_idx = *+1
        lda msg0                        // The char to "print" is actually the
        beq next_word                   // offset of the charrrom.
        cmp #$8e                        // 0 and $83 are special characters.
        beq start

        ldy #$00                        // Y is used as the row index

        sta ZP_CHARROM_PTR_LSB          // Update charrom offset

draw_char_loop:
        sei
        ldx #%0011_0010                 // Enable Char ROM in $D000
        stx $01
        lda (ZP_CHARROM_PTR_LSB),y      // fetch .byte for row
        ldx #$07                        // Enable I/O in $D000, needed for $ffd2
        stx $01                         // This also turns On the casette motor,
                                        // but saves two .bytes.
                                        // Reusing X=7 for column index
        cli                             // Couldn"t find the root cause, but if
                                        // I don"t do CLI, program might hang.
                                        // I guess it is related to the $ffd2 call
                                        // needing some interrupts (???).
horiz_draw:
        asl                           // test one bit at the time
        pha                             // save A it for later
        bcc _l0                         // Bit not set
.label solid_char = *+1
        lda ZP_SOLID_CHAR               // Bit set, print solid char
        bne skip                        // Forced jump

_l0:    lda #$20                        // Use "space" to print
skip:
        jsr PRINT_CHAR
        pla                             // Restore A. Contains the bits

        dex                             // Already tested all cols?
        bpl horiz_draw                  // No, continue

new_line:
        lda #$0d                        // new line
        jsr PRINT_CHAR

_l1:    iny                             // increment row counter
        cpy #8                          // already 8 rows?
        bne draw_char_loop              // No, continue

next_char:
        inc msg_idx                     // Increment char to print
        bne main_loop                   // force jmp, never gets to $00

start:
        lda #<msg0-1                    // Set msg index to initial value
        sta msg_idx                     // The "-1" is to compesate an "inc" that comes later

next_word:
        inc $0286                       // Update color to print
        inc ZP_SOLID_CHAR               // Update solid char
        bne next_char                   // "bne next_char" will crash once ZP_SOLID_CHAR
                                        // is 0, which is Ok. Chars $00-$1f are not printable.