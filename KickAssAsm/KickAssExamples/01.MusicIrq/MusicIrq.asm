BasicUpstart2(start)			// <- This creates a basic sys line that can start your program

//----------------------------------------------------------
//----------------------------------------------------------
//					Simple IRQ
//----------------------------------------------------------
//----------------------------------------------------------
			.const RASTER_BASE = $30		// PAL first visible line (~$30); use $20 for NTSC
			.const RASTER_TARGET = RASTER_BASE + ($1b & $07) // first visible text row given y-scroll=3 -> $33
			.const RASTER_PRE = RASTER_TARGET - 1
			* = $4000 "Main Program"		// <- The name 'Main program' will appear in the memory map when assembling
start:		lda #$00
			sta $d020
			lda #$01
			sta $d021
			lda #$00
			jsr music_init
			sei
			lda #$35
			sta $01
			lda #<irq_pre			// first IRQ one line before target (pre-IRQ)
			sta $fffe
			lda #>irq_pre
			sta $ffff
			lda #RASTER_PRE			// pre-IRQ at fixed line (target-1)
			sta $d012
			lda #$1b				// normal screen, yscroll=3
			sta $d011
			lda #$81
			sta $d01a
			lda #$7f
			sta $dc0d
			sta $dd0d

			lda $dc0d
			lda $dd0d
			lda #$ff
			sta $d019

			cli
			jmp *
//----------------------------------------------------------
irq_pre:  	pha					// pre-IRQ on line-1: arm the main IRQ on target line
			txa
			pha
			tya
			pha
			lda #$ff
			sta	$d019				// ACK raster IRQ

			lda #RASTER_TARGET		// set next IRQ on fixed target line
			sta $d012
			lda #<irq_main			// switch vector to main IRQ
			sta $fffe
			lda #>irq_main
			sta $ffff

			pla
			tay
			pla
			tax
			pla
			rti

irq_main:	pha					// main IRQ at target line (stable timing)
			lda #$ff
			sta	$d019				// ACK raster IRQ
			SetBorderColor(GREEN) 		// do border change as early as possible
			txa
			pha
			tya
			pha
			jsr music_play
			SetBorderColor(BLACK)

			lda #RASTER_PRE			// re-arm pre-IRQ on fixed line (target-1)
			sta $d012
			lda #<irq_pre
			sta $fffe
			lda #>irq_pre
			sta $ffff

			pla
			tay
			pla
			tax
			pla
			rti
			
//----------------------------------------------------------
			*=$1000 "Music"
			.label music_init =*			// <- You can define label with any value (not just at the current pc position as in 'music_init:') 
			.label music_play =*+3			// <- and that is useful here
			.import binary "ode to 64.bin"	// <- import is used for importing files (binary, source, c64 or text)	

//----------------------------------------------------------
// A little macro
.macro SetBorderColor(color) {		// <- This is how macros are defined
	lda #color
	sta $d020
}