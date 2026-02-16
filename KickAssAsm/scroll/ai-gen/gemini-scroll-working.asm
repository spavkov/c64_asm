// ============================================================================
// C64 Smooth Horizontal Scroller (KickAssembler)
// ============================================================================

// --- Constants & Memory ---
.const SCREEN_RAM = $0400         // Default Screen RAM
.const RASTER_LINE = 200          // Raster line to trigger interrupt (bottom of screen)
.const SCROLL_ROW = 0            // Row number to put text on (0-24)
.const SCROLL_ADDR = SCREEN_RAM + (SCROLL_ROW * 40) 

// --- Zero Page Variables ---
.var msg_ptr = $fb                // Pointer to current character in message (2 bytes)

// --- Basic Loader ---
:BasicUpstart2(start)

// ============================================================================
// Main Initialization
// ============================================================================
start:
    sei                           // Disable interrupts

    // 1. Clear Screen
    lda #$20                      // Space character
    ldx #0
clear_loop:
    sta SCREEN_RAM, x
    sta SCREEN_RAM + 250, x
    sta SCREEN_RAM + 500, x
    sta SCREEN_RAM + 750, x
    inx
    bne clear_loop

    // 2. Setup Message Pointer
    lda #<message                 // Low byte of message address
    sta msg_ptr
    lda #>message                 // High byte of message address
    sta msg_ptr+1

    // 3. Setup Interrupts
    lda #$7f                      // Disable CIA interrupts
    sta $dc0d
    sta $dd0d
    lda $dc0d                     // Acknowledge any pending CIA interrupts

    lda #$01                      // Enable Raster Interrupt
    sta $d01a

    lda #RASTER_LINE              // Trigger on this raster line
    sta $d012

    lda $d011                     // Clear bit 8 of raster (because line 200 < 255)
    and #$7f
    sta $d011

    lda #<irq                     // Point hardware vector to our routine
    sta $0314
    lda #>irq
    sta $0315

    cli                           // Re-enable interrupts
    jmp * // Infinite loop (CPU does nothing, IRQ does the work)

// ============================================================================
// Interrupt Routine (The Engine)
// ============================================================================
irq:
    // Acknowledge interrupt by writing to status register
    lda #$01
    sta $d019

    // --- Scroller Logic ---
    
    // Decrease horizontal scroll value
    dec x_scroll_val
    lda x_scroll_val
    and #$07                      // Keep it in range 0-7
    sta x_scroll_val
    
    // Check if we need to shift screen memory (when scroll resets to 7)
    cmp #$07
    bne update_register           // If not 7, just update register

    jsr shift_screen_row          // If 7, it means we wrapped 0->7, so shift characters

update_register:
    // Update VIC-II Register $D016
    // Bit 3 = 0 sets 38-column mode (hides the edges where we shift)
    // Bits 0-2 = Scroll value
    lda $d016
    and #$F0                      // Clear lower 4 bits (scroll & column select)
    ora x_scroll_val              // Add our scroll value (0-7)
    // Note: We leave bit 3 as 0 implied (38 columns)
    sta $d016

    // Exit Interrupt
    jmp $ea31                     // Jump to standard Kernal IRQ handler

// ============================================================================
// Subroutines
// ============================================================================

shift_screen_row:
    // 1. Shift existing characters left by 1
    ldx #0
shift_loop:
    lda SCROLL_ADDR + 1, x        // Load char to the right
    sta SCROLL_ADDR, x            // Store in current position
    inx
    cpx #39                       // Do 39 times (leaving last spot open)
    bne shift_loop

    // 2. Fetch new character from message
    ldy #0
fetch:
    lda (msg_ptr), y              // Load char from message
    bne store_char                // If not 0 (end marker), print it

    // Reset message pointer if 0 found
    lda #<message
    sta msg_ptr
    lda #>message
    sta msg_ptr+1
    jmp fetch                     // Try again with reset pointer

store_char:
    // Convert ASCII/Petscii if needed, or just store.
    // Screen codes: A=1, B=2. Standard text usually works directly if using .text
    sta SCROLL_ADDR + 39          // Put new char at far right (hidden by 38-col mode)

    // 3. Advance pointer
    inc msg_ptr
    bne done_shift
    inc msg_ptr+1
done_shift:
    rts

// ============================================================================
// Data
// ============================================================================

x_scroll_val: 
    .byte 7                       // Current fine scroll position (Starts at 7)

message:
    .text "hello world! this is smooth scroller in KickAssembler done by Gemini 3....                   "
    .byte 0                       // End marker