// ============================================================
// DYCP (Different Y Character Position) Horizontal Scroller
// Commodore 64 - KickAssembler syntax
//
// Assemble:  kickass dycp.asm
// Run:       SYS 3072
// ============================================================

BasicUpstart2(start)


// ======================== DATA ========================

scroll_text:
.text " *** HELLO WORLD *** THIS IS A DYCP SCROLLER ON THE COMMODORE 64 *** EACH CHARACTER DANCES ON ITS OWN SINE WAVE *** CLASSIC DEMOSCENE EFFECT *** GREETINGS TO ALL DEMOSCENERS! ***   "
.const TEXT_LEN = 20

// 256-byte sine table: values 5-19 (screen rows for vertical movement)
sine_table:
.for(var i = 0; i < 256; i++) {
    !byte 12 + toByte(7.0 * sin(i * 6.283185 / 256.0))
}

// Column colors (5 groups of 8 columns each)
colors: !byte $07, $01, $0e, $05, $0a

// Border color cycle
border_colors:
!byte $00,$0f,$06,$0e,$03,$01,$0a,$07
!byte $0d,$05,$0c,$04,$09,$0b,$02,$08

// ======================== CODE ========================

// Zero page usage:
// $fb     = wave phase (0-255)
// $f9/$fa = working text pointer
// $fd/$fe = main text pointer (start of frame)
// $02/$03 = calculated screen address
// $04     = temporary storage

start:
    sei
    lda #$35
    sta $01                    // Disable ROMs

    lda #$00
    sta $d020                  // Black border
    sta $d021                  // Black background

    // Clear screen RAM ($0400-$07E7) with spaces
    ldx #$00
    lda #$20
clr_scr:
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    lda #$00                   // Black color RAM
    sta $d800, x
    sta $d900, x
    sta $da00, x
    sta $db00, x
    inx
    bne clr_scr

    // Initialize variables
    lda #$00
    sta $fb                    // phase = 0
    lda #<scroll_text
    sta $fd
    lda #>scroll_text
    sta $fe

// ==================== MAIN LOOP ====================

main:
    // Synchronize to vertical blank (raster line 0)
wait:
    lda $d012
    bne wait

    // Cycle border color
    lda $fb
    and #$0f
    tax
    lda border_colors, x
    sta $d020

    // --- Clear scroller area (rows 4-19, 640 bytes) ---
    lda #<($0400 + 4 * 40)     // $04A0
    sta $02
    lda #>($0400 + 4 * 40)
    sta $03
    ldy #639
.clear:
    lda #$20
    sta ($02), y
    dey
    bpl .clear

    // --- Draw DYCP characters ---
    // Copy text pointer to working pointer
    lda $fd
    sta $f9
    lda $fe
    sta $fa

    ldx #39                    // Rightmost column first
    lda $fb                    // Start with current phase

.draw:
    pha                        // Save phase accumulator

    // Look up Y position in sine table
    tay
    lda sine_table, y          // A = row (5-19)

    // --- Calculate screen address: $0400 + row * 40 + column ---
    // row * 40 = row * 8 + row * 32
    sta $04                    // Save row
    asl                        // row * 2
    asl                        // row * 4
    asl                        // row * 8
    sta $02                    // Low byte of row*8
    lda #$00
    rol                        // High byte of row*8
    sta $03
    lda $02
    asl                        // row * 16
    rol $03
    asl                        // row * 32
    rol $03
    clc
    adc $02                    // + row * 8 = row * 40
    sta $02
    lda $03
    adc #0
    sta $03
    // Add screen base
    clc
    lda $02
    adc #<$0400
    sta $02
    lda $03
    adc #>$0400
    sta $03
    // Add column
    txa
    clc
    adc $02
    sta $02
    lda #0
    adc $03
    sta $03

    // Write character to screen
    ldy #0
    lda ($f9), y
    sta ($02), y

    // Write color to color RAM
    txa                        // Column (0-39)
    lsr
    lsr
    lsr                        // Column group (0-4)
    tay
    lda colors, y              // Get color
    pha                        // Save color
    // Convert screen addr to color RAM addr (+$D400)
    lda $02
    clc
    adc #<$d400
    sta $02
    lda $03
    adc #>$d400
    sta $03
    pla                        // Restore color
    ldy #0
    sta ($02), y

    // Advance working text pointer with wrap-around
    inc $f9
    lda $f9
    bne .cw1
    inc $fa
.cw1:
    lda $f9
    cmp #<scroll_text + TEXT_LEN
    lda $fa
    sbc #>scroll_text + TEXT_LEN
    bcc .nw1
    lda #<scroll_text
    sta $f9
    lda #>scroll_text
    sta $fa
.nw1:

    // Restore phase, add column offset for wave shape
    pla
    clc
    adc #$08                   // 8 sine-steps per column

    dex
    bpl .draw

    // --- Scroll text by one character ---
    inc $fd
    lda $fd
    bne .cw2
    inc $fe
.cw2:
    lda $fd
    cmp #<scroll_text + TEXT_LEN
    lda $fe
    sbc #>scroll_text + TEXT_LEN
    bcc .nw2
    lda #<scroll_text
    sta $fd
    lda #>scroll_text
    sta $fe
.nw2:

    // Advance phase
    inc $fb
    inc $fb                    // += 2 for visible wave motion

    jmp main