:BasicUpstart2(start)

.var picture = LoadBinary("indus3.koa", BF_KOALA)

// https://sta.c64.org/cbm64mem.html
// https://www.lemon64.com/forum/viewtopic.php?t=82157

start:  	
    lda %00110000 // sets screen off (bit 0) and bitmapped mode (bit 5)
	sta $d018
	lda %00000100 //  turn on vic multi-color mode
	sta $d016
	lda #$3B
	sta $d011
	lda #WHITE
	sta $d020
	lda #picture.getBackgroundColor()
	sta $d021
	ldx #0

loop1: .for (var i=0; i<4; i++) 
	{
		lda colorRam+i*$100,x
		sta $d800+i*$100,x
	}

	inx
	bne loop1
	jmp *

*=$0c00	"ScreenRam"; 		.fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$1c00	"ColorRam:"; colorRam: 	.fill picture.getColorRamSize(), picture.getColorRam(i)
*=$2000	"Bitmap";			.fill picture.getBitmapSize(), picture.getBitmap(i)