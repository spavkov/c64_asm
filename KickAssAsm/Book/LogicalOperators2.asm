
:BasicUpstart2(start) 

// this programs runs until we press RUNSTOP (semicolon on PC) or we enter any alphabetic character (a-z)

.var RUNSTOP_CHECK_SUBROUTINE = $FFE1 // sets the Z flag if RUNSTOP is pressed
.var GET_KEY_SUBROUTINE = $FFE4  // gets the character from input and places it into A register (in PET ASCI format) - subroutine does not wait and returns immediately
.var PRINT_CHAR_SUBROUTINE = $ffd2 // sets the Z flag if RUNSTOP is pressed

start:
    jsr RUNSTOP_CHECK_SUBROUTINE  // check if RUN/STOP is pressed
    beq exit   // if it is, z flag will be set, and we will branch to exit
    lda #$00 // just in case
    jsr GET_KEY_SUBROUTINE
    cmp #$41 // alphanumerical chars are from $41 to $5a inclusive
    bcc start // if its lower then $30 we go back to start
    cmp #$5b  // now check if its greater or equal to $3c which comes after $39 (number 9)
    bcs start // if its greater then or euqal to $3c its also not a number so jump to start
    jsr PRINT_CHAR_SUBROUTINE              // now we know its number so print it to screen
exit:    
    rts