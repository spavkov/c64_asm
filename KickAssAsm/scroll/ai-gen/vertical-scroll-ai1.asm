// Commodore 64 Vertical Smooth Scroller (FIXED)
// KickAssembler Format

:BasicUpstart2(start)

// -- Constants --
.const SCREEN_RAM = $0400
.const COLOR_RAM  = $d800
.const IRQ_RASTER = 250     

// -- Zero Page Pointers --
// REQUIRED: Indirect addressing (lda (ptr),y) MUST use Zero Page
.const ZP_PTR_LO = $fb
.const ZP_PTR_HI = $fc

// -- VIC-II Registers --
.const D011 = $d011 
.const D012 = $d012
.const D01A = $d01a
.const D019 = $d019

// -- Variables (Main Memory) --
scroll_y: .byte 7 

// ----------------------------------------------------------------
// MAIN PROGRAM START
// ----------------------------------------------------------------
start:
    sei                     // Disable interrupts

    // 1. Initialize Text Pointer in Zero Page
    lda #<message
    sta ZP_PTR_LO
    lda #>message
    sta ZP_PTR_HI

    // 2. Clear Screen
    //jsr clear_screen

    // 3. Setup Interrupts
    lda #$7f
    sta $dc0d               // Turn off CIA interrupts
    lda $dc0d               // Acknowledge

    lda #$01
    sta D01A                // Enable Raster Interrupt

    lda #<irq_handler       
    sta $fffe
    lda #>irq_handler       
    sta $ffff

    lda #IRQ_RASTER         
    sta D012

    lda D011                
    and #$7f                // High bit of raster = 0
    sta D011

    cli                     // Enable interrupts

loop:
    jmp loop                // Infinite loop


// ----------------------------------------------------------------
// INTERRUPT HANDLER
// ----------------------------------------------------------------
irq_handler:
    // Acknowledge interrupt
    lda #$01
    sta D019

    // -- Smooth Scroll Logic --
    dec scroll_y            
    bpl update_register     // If scroll_y >= 0, skip the hard shift

    // -- Hard Shift Logic --
    lda #7
    sta scroll_y
    
    jsr shift_screen_up     
    jsr draw_new_line       

update_register:
    lda D011
    and #%11110000          // Clear scroll bits and 24-row bit
    ora scroll_y            // Set new scroll amount
    // Bit 3 is left 0, enabling 24-row mode (hides the top/bottom glitch)
    sta D011

    // Exit Interrupt
    jmp $ea31               // Return to Kernel


// ----------------------------------------------------------------
// SUBROUTINES
// ----------------------------------------------------------------

shift_screen_up:
    ldx #0
loop_shift:
    // Move screen memory up by 40 bytes
    // Row 0 gets Row 1, Row 1 gets Row 2, etc.
    lda SCREEN_RAM + 40, x
    sta SCREEN_RAM, x
    
    lda SCREEN_RAM + 250 + 40, x
    sta SCREEN_RAM + 250, x
    
    lda SCREEN_RAM + 500 + 40, x
    sta SCREEN_RAM + 500, x
    
    // Safety check for the last chunk to avoid overflow
    cpx #232                
    bcs skip_last           
    lda SCREEN_RAM + 750 + 40, x
    sta SCREEN_RAM + 750, x
skip_last:

    inx
    cpx #250
    bne loop_shift
    rts

draw_new_line:
    ldy #0
next_char:
    // Read using Zero Page Pointer
    lda (ZP_PTR_LO), y
    
    // Check for End of String ($00)
    cmp #0
    bne put_char
    
    // -- Reset Pointer to start --
    lda #<message
    sta ZP_PTR_LO
    lda #>message
    sta ZP_PTR_HI
    jmp draw_new_line       

put_char:
    // Write to the hidden 25th row (starting at offset 960)
    sta SCREEN_RAM + 960, y 
    
    iny
    cpy #40                 
    bne next_char
    
    // -- Advance Pointer by 40 --
    clc
    lda ZP_PTR_LO
    adc #40
    sta ZP_PTR_LO
    lda ZP_PTR_HI
    adc #0
    sta ZP_PTR_HI
    rts

clear_screen:
    ldx #0
    lda #32                 // Space
c_loop:
    sta SCREEN_RAM, x
    sta SCREEN_RAM + 250, x
    sta SCREEN_RAM + 500, x
    sta SCREEN_RAM + 750, x
    inx
    bne c_loop
    
    // Set colors to White
    ldx #0
    lda #1                  
col_loop:
    sta COLOR_RAM, x
    sta COLOR_RAM + 250, x
    sta COLOR_RAM + 500, x
    sta COLOR_RAM + 750, x
    inx
    bne col_loop
    rts

// ----------------------------------------------------------------
// DATA
// ----------------------------------------------------------------
// KickAssembler Text Encoding: Ensure we get Screen Codes, not ASCII
.encoding "screencode_mixed"

message:
    // 40 chars per line strictly
    .text "                                        "
    .text "   *** VERTICAL SCROLLER FIXED *** "
    .text "                                        "
    .text "   now using zero page pointers $fb/$fc "
    .text "   for indirect addressing mode.        "
    .text "                                        "
    .text "   the 6502 cpu requires pointers to    "
    .text "   live in the zero page (mem 0-255)    "
    .text "   to use instructions like:            "
    .text "   lda ($fb), y                         "
    .text "                                        "
    .text "   without this, the cpu reads garbage  "
    .text "   and you get a blank screen.          "
    .text "                                        "
    .text "   enjoy the smooth scrolling!          "
    .text "                                        "
    .text "                                        "
    .text "                                        "
    .byte 0