// source: https://codebase64.org/doku.php?id=base:8x_scale_charset_scrolling_message
/*---------------------------------------
  KickAssember variables used in routine.
---------------------------------------*/
.var scroll=$02             /* 2 Zeropage addresses to store the
                               scrolltext current read address. */
.var chardata=$04           /* 2 Zeropage addresses to store
                               character data for bit shifting. */
.var regstates=$06          /* 3 Zeropage addresses to store
                               register states during irq. */
.var chr_himem=$d0          // Hi-byte start address of charset
.var scrmem=$07e8-[$28*8]   // Screen location of scroller


.pc=$0801 "BASIC"
  :BasicUpstart($0810)  // Include basic start.


/*---------------------
  Beginning of program.
---------------------*/
.pc=$0810 "ROUTINE"
  
  sei                   // Halt any interrupts.

  /*---------------------------------------
    Set the scrolltext start address values
    to the reserved zeropage addresses.
  ---------------------------------------*/  
  lda #>scrolltext
  sta scroll+1
  lda #<scrolltext
  sta scroll
    
  /*-----------
    Set up irq.
  -----------*/   
  lda #$01              // Set raster compare irq flag and
  sta $d01a             // interrupt request register to 1. 
  sta $d019             //
  lda #$7f              // Set CIA interrupt control register.
  sta $dc0d             //
  lda #$35              // Set memory configuration to 
  sta $01               // full RAM with I/O.
  lda #<irq             // Set irq and nmi vector locations.
  ldy #<nmi
  sta $fffe
  sty $fffa
  lda #>irq
  ldy #>nmi
  sta $ffff
  sty $fffb
  lda #$f8              // Set raster line required in irq.
  sta $d012             //
  lda #$1b              // Set to view to text mode and
  sta $d011             // clear the MSB of raster line.
  lda #$03              // Set bank
  sta $dd00             //
  lda #$08              // Set X scroll position
  sta $d016             //
  lda #$14              // Set screenmem and charset base
  sta $d018             //
  lda $dc0d             // Latch CIA irq control register.
  
  cli                   // Clear interrupt flag.
  bvc *                 // loop here.

  /*-----------------------------
    Beginning of the irq routine.
  -----------------------------*/ 
irq:
  sta regstates         // Save A register state
  stx regstates+1       // Save X register state
  sty regstates+2       // Save Y register state

  /*-------------------------------------------
    Check if requested raster line has reached.
  -------------------------------------------*/    
  lda $d012
!:cmp $d012             // Z=?
  bne !-                // if Z=0, take branch

  /*----------------------------------------------------
    This is optional if you want to use the ROM charset.
  ----------------------------------------------------*/
  lda $01               // Save original $01 state
  sta original_01+1
  lda #$32              // Set memory configuration to
  sta $01               // character ROM access.

  /*--------------------------------------------------------
    Scroll 8 lines of screen memory by one char to the left.
    This isn't the foremost way performance wise, but it
    does the job at least.
  --------------------------------------------------------*/
  ldx #$00              // X=0
!:lda scrmem+$1,x
  sta scrmem+$0,x
  lda scrmem+$29,x
  sta scrmem+$28,x
  lda scrmem+$51,x
  sta scrmem+$50,x
  lda scrmem+$79,x
  sta scrmem+$78,x
  lda scrmem+$a1,x
  sta scrmem+$a0,x
  lda scrmem+$c9,x
  sta scrmem+$c8,x
  lda scrmem+$f1,x
  sta scrmem+$f0,x
  lda scrmem+$119,x
  sta scrmem+$118,x
  inx                   // X++
  cpx #$27              // Z=?
  bne !-                // if Z=0, take branch

  /*---------------------------------------------
    The 8x scale font scroll routine starts here.
  ---------------------------------------------*/
  dec print_pos+1       // print_pos--
  ldx #$07              // X=7
print_pos:
  ldy #$00              // N=?
  bpl print_char        // ? N=0 *
  iny                   // Y++
  sty chardata+1        // chardata=Y (0)
  stx print_pos+1       // print_pos=X (7)
 
  lda (scroll),y        // read scrolltext char, Z=?
  bne !+                // ? Z=0 *
  lda #>scrolltext      // Restore the start address of the
  sta scroll+1          // scrolltext to the zeropage addresses.
  lda #<scrolltext      //
  sta scroll            //
  lda (scroll),y        // read scrolltext again

  /*------------------------------------------------------------
     This following chunk of code is not necessary to include,
     but it allows spaces on the scroller to be slightly shorter
     when viewed on the screen, making the text more readable.
  ------------------------------------------------------------*/
!:cmp #$20              // * Z=0, check if char is a space, Z=?
  bne !+                // ? Z=0 **
  dec print_pos+1
  dec print_pos+1
  dec print_pos+1

  /*------------------------------------------------------------
     Do left bit shifting to get the start address of the
     character read from the scrolltext, puttin the address into
     two reserved zeropage address to allow char pixel reading.
  ------------------------------------------------------------*/
                        // A = 11111111
!:asl                   // A = 11111110, C=msb
  rol chardata+1        // chardata+1 = 0000000? <- C
  asl                   // A = 11111100, C=msb
  rol chardata+1        // chardata+1 = 000000C? <- C
  asl                   // A = 11111000, C=msb
  rol chardata+1        // chardata+1 = 00000CC? <- C
  sta chardata          // chardata = A
  lda chardata+1        // Add the the hi-byte charset base
  ora #chr_himem        // address to chardata+1
  sta chardata+1        //
  inc scroll            // Increase scrolltext read pointers.
  bne !+                //
  inc scroll+1          //
!:lda (chardata),y      // Now begin a loop of reading pixel data
  sta charbuff,x        // from the gathered char memory location
  iny                   // and store into an 8 byte buffer.
  dex                   //
  bpl !-                //
  ldx #$07              // X=7

  /*--------------------------------------------------
    Branch here is a character is still to be printed.
  --------------------------------------------------*/  
print_char:             // * N=0
  ldy #$27              // First, set the start address of screen
  lda #<scrmem          // memory to be written to.
  sta chardata          //
  lda #>scrmem          //
  sta chardata+1        //

  /*-----------------------------------------------
    This is a loop routine to print each row of the
    current character column pixel to the screen.
  -----------------------------------------------*/
print_char_loop:
  lda #$40              // Set your display character here.
  asl charbuff,x        // Bit shift character buffer left once, C=?
  ror                   // Invery display character via the C flag.
  sta (chardata),y      // Store display character to screen memory.
  lda chardata          // Set memory pointer to the next row of
  adc #$28              // screen memory.
  sta chardata          //
  lda chardata+1        //
  adc #$00              //
  sta chardata+1        //
  dex                   // How many rows left?, X-- N=?
  bpl print_char_loop   // if N=0, take branch.

  /*------------------------
    End of scroller routine.
  ------------------------*/  
original_01:
  lda #$00              // Retrieve the original memory configuration
  sta $01               // state before the scroll routine was executed. 
      
  /*-------------------------
    End of interrupt routine.
  -------------------------*/
  lda #$01              // Reset interrupt request register to 1. Spare me
  sta $d019             // the critisim on how to REALLY do this.  ;D
  lda $dc0d             // Latch CIA irq control register.
  ldy regstates+2       // Y=original state
  ldx regstates+1       // X=original state
  lda regstates         // A=original state
nmi:
  rti                   // Return from interrupt


/*---------------------------
  Character buffer data here.
---------------------------*/ 
.pc=* "CHARACTER BUFFER DATA" virtual
charbuff:
  .byte $00,$00,$00,$00,$00,$00,$00,$00


/*---------------------
  Scrolltext data here.
---------------------*/  
.pc=$0c00 "SCROLL TEXT" 
scrolltext:
  .text "hi there!  this is a test scrolltext for the tutorial routine on how to write a simple 8x scale font scroller, using "
  .text "a selectable character to write to screen memory.   the source of this routine can be found at http://codebase64.org/"
  .text "  ...feel free to do modifications or possible optimisations if you plan to use a routine as such as this one!       "
  .text "coded by conrad/onslaught/samar,  2nd january 2008.             wrap...          @"