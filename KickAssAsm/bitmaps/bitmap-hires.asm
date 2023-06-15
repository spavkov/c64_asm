// https://github.com/joakimkarlsson/c64/blob/4bd57548038a83f41dfe6870b0b1b496c4f7b5cb/src/bitmaps/bitmaps.asm
#import "macros.asm"

.var vic_bank=1
.var vic_base=$4000*vic_bank    // A VIC-II bank indicates a 16K region
.var screen_memory=$0000 + vic_base
.var bitmap_address=$2000 + vic_base

BasicUpstart2(start)
start:
    SwitchVICBank(vic_bank)
    SetHiresBitmapMode()
    SetScreenMemory(screen_memory - vic_base)
    SetBitmapAddress(bitmap_address - vic_base)
    CopyScreenMemory()
    rts

.var bitmap = LoadBinary("indus3.hir", BF_C64FILE)

*=$6000;  .fill bitmap.getSize(), bitmap.get(i)

.macro CopyScreenMemory() {
    //
    // Screen memory is 40 * 25 = 1000 bytes ($3E8 bytes)
    //
    .var source = $6000+$1f40
    .var destination = screen_memory
    ldx #$00
!loop:
    lda source,x
    sta destination,x
    lda (source + $100),x
    sta (destination + $100),x
    lda (source + $200),x
    sta (destination + $200),x
    lda (source + $300),x
    sta (destination + $300),x    
    lda (source + $400),x
    sta (destination + $400),x      
    lda (source + $500),x
    sta (destination + $500),x           
    dex
    bne !loop-
}


.print "vic_bank: " + toHexString(vic_bank)
.print "vic_base: " + toHexString(vic_base)
.print "screen_memory: " + toHexString(screen_memory)
.print "bitmap_address: " + toHexString(bitmap_address)