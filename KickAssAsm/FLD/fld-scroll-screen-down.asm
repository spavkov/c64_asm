// Kick Assembler syntax
BasicUpstart2(start)
//---------------------------------------------------------
//---------------------------------------------------------
//	Flexible Line distance http://www.antimon.org/dl/c64/code/fld.txt
//    better version here: https://web.archive.org/web/20140226123633/http://c64assembly.elorama.se/
//  
//  FLD is a hack that never allows a badline.
//  This is done by manipulating bit 0-2 in  $d011 (Vertical raster scroll.) so it newer will have the same 
//  value as  bit 0-2 $d012 ( Current raster line (bits #0-#7).)
//
//	As no graphic pointers are allowed do do their work ( in the  badlines ) no graphics can be displayed.
//  The graphic you see is a garbage byte value (last byte of Vicbank ie $3fff in this code)
//  but we can for ex use sprites.
//
//  Without badlines you have 63  "free" cycles (PAL) per rasterline at your service :) 
//---------------------------------------------------------
//---------------------------------------------------------
start:
.var from 	= $32         //start line
.var to   =  $fa          // end line
init:
   	  lda #0
      sta dir     // direction
      lda #$00    // set garbage
      sta $3fff   // 
      lda #from
      sta ofset   // set ofset
      sei         // disable interrupt
      lda #$7f    // disable timer interrupt
      sta $dc0d
      lda #1      // enable raster interrupt
      sta $d01a
      lda #<irq    // low part of address of interrupt handler code
      ldx #>irq   // high part of address of interrupt handler code
      ldy #$0     // line to trigger interrupt
      sta $0314    // store in interrupt vector
      stx $0315
      sty $d012  
      cli         // enable interrupt
      rts
//---------------------------------------
irq:       
	  ldx ofset
l2:
      ldy $d012   // moving 1st bad line
l1:
	  cpy $d012
      beq l1      // wait for begin of next line
      dey         // iy - bad line
      tya
      and #$07    // clear higher 5 bits
      ora #$10    // set text mode
      sta $d011
      
      dex
      bne l2
      
      asl $d019   // acknowledge the raster interrupt
      jsr chofs
      jmp $ea31   // do standard irq routine

//---------------------------------------
chofs:
	  lda dir     // change ofset of screen
      bne up
      inc ofset   // down
      //inc ofset   // if you want it faster uncomment
       
      lda ofset
      cmp #to
      bne skip
      sta dir
skip:
		rts
//---------------------------------------
up:
      dec ofset   // up
      dec ofset   // up
      dec ofset   // up
      dec ofset   // up
      
      lda ofset
      cmp #from
      bne skip
      lda #0
      sta dir
      rts
//---------------------------------------
ofset: .byte from
dir:   .byte 0
