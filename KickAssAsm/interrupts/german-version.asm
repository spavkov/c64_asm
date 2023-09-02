// found here and translated via google translator: https://www.retro-programming.de/programming/nachschlagewerk/interrupts/der-rasterzeileninterrupt/

// Mark the raster line for the colors
.label startblack = $00  // black
.label startred = $90    // red
.label startgold = $d0   // gold

.label raster   = $d012  // current raster line
.label intflag  = $d019  // interrupt flag reg
.label frame    = $d020  // frame color
.label border   = $d021  // border color

BasicUpstart2(start)
start:
         sei       // disable interrupts

         // Tell the CPU where to jump to
         // when raster IRQ triggers
         lda #<rasterirq
         sta $0314 // RAM IRQ vector
         lda #>rasterirq
         sta $0315 // high .byte

         // Tell the raster IRQ when to
         // trigger (when raster line=0)
         lda #startblack
         sta raster

         // Clear bit 8 of raster reg
         lda $d011 // VIC control reg
         and #%01111111
         sta $d011

         // Enable raster compare IRQ
         lda $d01a // interrupt request
         ora #%00000001 // set bit 0
         sta $d01a
         cli       // enable interrupts
         rts       // back to BASIC

//---------------------------------------
// The interrupt routine
rasterirq:
         // Check if VIC triggered an
         // interrupt (bit 7=1 of $d019)
         lda intflag
         bmi dorasterirq
         // Load interrupt control reg
         // This will clear all inter-
         // rupts
         lda $dc0d
         cli       // enable interrupts
         // Jump to entry point of normal
         // interrupt routine if no
         // raster compare IRQ triggered
         jmp $ea31

dorasterirq:
         sta intflag
         lda raster
         bne dored // raster is not 0
         lda #$00  // black
         sta frame
         sta border
         lda #startred
         sta raster
         jmp exit

dored:
         cmp #startred
         bne dogold
         lda #$02  // red
         sta frame
         sta border
         lda #startgold
         sta raster
         jmp exit

dogold:
         lda #$07  // yellow (gold)
         sta frame
         sta border
         lda #startblack
         sta raster

exit:
         pla       // restore Y
         tay
         pla       // restore X
         tax
         pla       // restore accu
         rti       // return from IRQ
//---------------------------------------
