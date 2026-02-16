BasicUpstart2(start)

// Open top & bottom borders and place sprites in those areas.
// Technique: manipulate $d011 vertical scroll at precise raster lines.
// Simplified demonstration (PAL assumed). Not perfectly cycle-stable but illustrative.

.const SPRITE_Y_TOP      = 30        // target inside (opened) top border area (PAL approx < 50)
.const SPRITE_Y_BOTTOM   = 250       // target inside (opened) bottom border area (> last text row)
// Updated raster lines for a more typical top/bottom border open attempt (PAL)
.const RASTER_TOP_PRE    = $2f       // line just before first normal badline ($30)
.const RASTER_TOP        = $30       // manipulate $d011 mid-line here
.const RASTER_BOTTOM_PRE = $f2       // a few lines before normal frame end
.const RASTER_BOTTOM     = $f3       // manipulate $d011 near bottom

* = $080d "OpenBorders"

start:
	sei
	lda #$35
	sta $01

	// Clear screen colors
	lda #3
	sta $d020
    lda #2
	sta $d021

	// Sprite data pointer setup: use correct pointer = (address / 64)
	lda #spriteData/64
	sta $07f8            // sprite 0
	lda #spriteData/64
	sta $07f9            // sprite 1

	// Sprite colors
	lda #$05
    sta $d027
	lda #$05
	sta $d028

	// Positions
	lda #100
	sta $d000            // sprite 0 X
	lda #SPRITE_Y_TOP
	sta $d001            // sprite 0 Y
	lda #180
	sta $d002            // sprite 1 X
	lda #SPRITE_Y_BOTTOM
	sta $d003            // sprite 1 Y

	lda #%00000011
	sta $d015            // enable sprites 0,1

	// Install IRQ chain: pre top -> top -> pre bottom -> bottom -> loop
	lda #<irq_top_pre
	sta $fffe
	lda #>irq_top_pre
	sta $ffff
	lda #RASTER_TOP_PRE
	sta $d012
	lda #$13             // start in 24-row mode (bit3 cleared), y-scroll=3
	sta $d011
	lda #$01
	sta $d01a            // enable raster IRQ
	lda #$7f
	sta $dc0d
	sta $dd0d
	lda $dc0d
	lda $dd0d
	lda #$ff
	sta $d019
	cli

main:
	jmp main

// Pre top: arm top border open IRQ
irq_top_pre:
	pha         // save A
	txa         // X -> A
	pha         // save X
	tya         // Y -> A
	pha         // save Y
	lda #$ff
	sta $d019
	lda #RASTER_TOP
	sta $d012
	lda #<irq_top
	sta $fffe
	lda #>irq_top
	sta $ffff
	pla         // restore Y
	tay
	pla         // restore X
	tax
	pla         // restore A
	rti

// Top border open: tweak $d011 to extend display upward
irq_top:
	pha
	txa
	pha
	tya
	pha
	lda #$ff
	sta $d019
	// Top border open attempt:
	// Keep bit3 cleared, then set it after some cycles to trigger early display start.
	lda #$13        // ensure 24-row mode
	sta $d011
	nop
    nop
    nop
    nop
    nop
    nop  // crude delay (~12 cycles) - tune for stability
	lda #$1b        // set 25-row mode mid-line
	sta $d011
	// Chain to pre bottom
	lda #RASTER_BOTTOM_PRE
	sta $d012
	lda #<irq_bottom_pre
	sta $fffe
	lda #>irq_bottom_pre
	sta $ffff
	pla
	tay
	pla
	tax
	pla
	rti

irq_bottom_pre:
	pha
	txa
	pha
	tya
	pha
	lda #$ff
	sta $d019
	lda #RASTER_BOTTOM
	sta $d012
	lda #<irq_bottom
	sta $fffe
	lda #>irq_bottom
	sta $ffff
	pla
	tay
	pla
	tax
	pla
	rti

// Bottom border open attempt
irq_bottom:
	pha
	txa
	pha
	tya
	pha
	lda #$ff
	sta $d019
	// Bottom border open attempt: similar toggle
	lda #$13        // 24-row
	sta $d011
	nop
    nop
    nop
    nop
    nop
    nop
	lda #$1b        // back to 25-row
	sta $d011
	// Restart chain at top
	lda #RASTER_TOP_PRE
	sta $d012
	lda #<irq_top_pre
	sta $fffe
	lda #>irq_top_pre
	sta $ffff
	pla
	tay
	pla
	tax
	pla
	rti

// Simple sprite: small box
.align 64              // ensure sprite starts on 64-byte boundary
spriteData:
	.fill 63, $3c   // 63 bytes of pattern %00111100
	.byte 0         // final byte to make 64 total
