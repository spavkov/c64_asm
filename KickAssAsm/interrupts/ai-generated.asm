BasicUpstart2(start)
.pc = $2000     // Set the load address for the program

start:
    sei         // Disable interrupts
    lda #$35    // Bank out KERNAL and BASIC_ROM
    sta $01     // $e000-$ffff

    lda #<init_interruptHandler    // Set the address of the initialization interrupt handler
    ldx #>init_interruptHandler
    sta $fffe   // Store the low byte of initialization interrupt handler's address
    stx $ffff   // Store the high byte of initialization interrupt handler's address

    lda #$01    // Enable RASTER interrupts
    sta $d01a

    lda #<update_interruptHandler    // Set the address of the update interrupt handler
    ldx #>update_interruptHandler
    sta $0314   // Store the low byte of update interrupt handler's address
    stx $0315   // Store the high byte of update interrupt handler's address

    ldx #$00    // Set initial color value
loop:
    stx $d020   // Store the color value to background register
    inx
    beq loop    // Color cycling loop

init_interruptHandler:    // Initialization interrupt handler
    asl $d019   // Acknowledge initial raster interrupt
    rts

update_interruptHandler:    // Update interrupt handler
    asl $d019   // Acknowledge update raster interrupt
    rts

