*=$0801
BasicUpstart2(start)

*=$1000

// -----------------------------------------------------------------------------
// C64 smooth horizontal text scroller (beginner-friendly version)
//
// What this program does:
// 1) Clears the whole text screen and color RAM.
// 2) Uses VIC-II register $D016 for 8-step "fine" horizontal scroll.
// 3) After each full fine-scroll cycle, shifts one text row by one character.
// 4) Inserts the next message character at the RIGHT edge, so text travels LEFT.
//
// Result on screen:
// New letters appear on the right side and move toward the left.
// -----------------------------------------------------------------------------

// --- Useful C64 memory/register addresses ---
.const SCREEN      = $0400
.const COLOR_RAM   = $D800
.const BORDER      = $D020
.const BG          = $D021
.const RASTER      = $D012
.const VIC_CTRL2   = $D016
.const BASE_D016   = $C8
.const ROW         = 12
.const ROW_ADDR    = SCREEN + (ROW * 40)
.const COLOR_ADDR  = COLOR_RAM + (ROW * 40)
.const STEP_FRAMES = 2

start:
    // Disable interrupts while we initialize video state and memory.
    sei

    // Set border and background to black.
    lda #$00
    sta BORDER
    sta BG

    // Set VIC-II control register #2 base bits + fine scroll = 7.
    // Bits in BASE_D016 keep 40-column text mode and multicolor settings stable.
    lda #BASE_D016 + 7
    sta VIC_CTRL2

    // -------------------------------------------------------------------------
    // Clear full 1000-byte text screen RAM ($0400-$07E7).
    // We write 4 pages of 256 bytes using indexed addressing:
    //   SCREEN + $000, +$100, +$200, +$300
    // This is a common fast clear pattern on 6502.
    // -------------------------------------------------------------------------
    ldx #$00
    lda #' '
clear_screen:
    sta SCREEN,x
    sta SCREEN+$100,x
    sta SCREEN+$200,x
    sta SCREEN+$300,x
    inx
    bne clear_screen

    // -------------------------------------------------------------------------
    // Clear full color RAM ($D800-$DBE7) to color #1 (white).
    // Same 4-page technique as screen clear.
    // -------------------------------------------------------------------------
    ldx #$00
    lda #$01
clear_colors:
    sta COLOR_RAM,x
    sta COLOR_RAM+$100,x
    sta COLOR_RAM+$200,x
    sta COLOR_RAM+$300,x
    inx
    bne clear_colors

    // Ensure the dedicated scroll row starts blank and with consistent colors.
    ldx #39
clear_row:
    lda #' '
    sta ROW_ADDR,x
    lda #$01
    sta COLOR_ADDR,x
    dex
    bpl clear_row

    // fine_phase  = current fine-scroll pixel step (0..7)
    // frame_div   = frame divider to control speed
    // msg_index   = index into the message text
    //
    // We start at fine step 7 because our loop decrements and wraps with AND #$07.
    lda #$07
    sta fine_phase
    sta frame_div
    sta msg_index

    // Initialization complete: re-enable interrupts.
    cli

main:
    // Wait exactly one video frame (raster sync), then do time-based updates.
    jsr wait_frame

    // Slow down scrolling: update only once every STEP_FRAMES frames.
    inc frame_div
    lda frame_div
    cmp #STEP_FRAMES
    bcc main
    lda #$00
    sta frame_div

    // Fine horizontal scroll step:
    // Decrement 0..7 and mask to 3 bits.
    // This creates smooth pixel motion between character-cell shifts.
    dec fine_phase
    lda fine_phase
    and #$07
    sta fine_phase
    ora #BASE_D016
    sta VIC_CTRL2

    // Only when fine_phase wrapped back to 7 do we shift character cells.
    // That keeps coarse character movement synchronized with fine scroll.
    lda fine_phase
    cmp #$07
    bne main
    jsr shift_row_left
    jmp main

wait_frame:
    // Wait until raster line becomes $FF...
    lda #$ff
wait_line:
    cmp RASTER
    bne wait_line
    // ...then wait until it changes, meaning a new frame boundary passed.
wait_next:
    cmp RASTER
    beq wait_next
    rts

shift_row_left:
    // Shift visible row left by one character:
    // col0<-col1, col1<-col2, ... col38<-col39
    ldx #0
copy_loop:
    lda ROW_ADDR+1,x
    sta ROW_ADDR,x
    inx
    cpx #39
    bcc copy_loop

    // Insert next message character at the rightmost column (39).
    ldx msg_index
    lda message,x
    sta ROW_ADDR+39
    // Advance message index and wrap at message length.
    inx
    cpx #message_end-message
    bcc store_index
    ldx #0
store_index:
    stx msg_index
    rts

fine_phase: .byte 0
frame_div:  .byte 0
msg_index:  .byte 0

// Message stream that continuously feeds the right edge of the row.
// Leading spaces delay first visible letters, dots create trailing gap.
message:
    .text "                 smooth horizontal scroll demo moving left to right on c64............   "
message_end:
