:BasicUpstart2(main)

main:
	// set to 25 line text mode and turn on the screen
	lda #$1B
	sta $d011

	// disable SHIFT-Commodore
	lda #$80
	sta $0291

	// set screen memory ($0400) and charset bitmap offset ($2000)
	lda #$18
	sta $d018

	// set border color
	lda #$06
	sta $d020

	// set background color
	lda #$06
	sta $d021

	// set text color
	lda #$0E
	sta $0286
	rts

.var charset = LoadBinary("scrap_writer_iii_17.64c", BF_C64FILE)

*=$2000;  .fill charset.getSize(), charset.get(i)

