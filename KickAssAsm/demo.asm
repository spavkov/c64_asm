// *****************************************************************************
// *                                                                           *
// * copyright (c) 2017 nicola cimmino                                         *
// *                                                                           *
// *   this program is free software: you can redistribute it and/or modify    *
// *   it under the terms of the gnu general public license as published by    *
// *   the free software foundation, either version 3 of the license, or       *
// *   (at your option) any later version.                                     *
// *                                                                           *
// *  this program is distributed in the hope that it will be useful,          *
// *   but without any warranty// without even the implied warranty of          *
// *   merchantability or fitness for a particular purpose.  see the           *
// *   gnu general public license for more details.                            *
// *                                                                           *
// *   you should have received a copy of the gnu general public license       *
// *   along with this program.  if not, see http://www.gnu.org/licenses/.     *
// *                                                                           *
// *                                                                           *
// *****************************************************************************

// *****************************************************************************
// * below are tbe basic tokens for 10 sys49152                                *
// * we store them at the beginning of the basic ram so when we can load       *
// * the program with autorun (load "*",8,1) and save to type the sys.         *

*=$801

        .byte $0e, $08, $0a, $00, $9e, $34, $39, $31, $35, $32, $00, $00, $00
// *                                                                           *
// *****************************************************************************

// *****************************************************************************
// * this is the entry point into our program. we do some setup and then let   *
// * things roll from here.                                                    *

*=$c000

start:   sei            // prevent interrupts while we set things up.
        jsr  $ff81      // reset vic, clear screen, this is a kernal function.

        lda  #%00110101 // disable kernal and basic roms we go bare metal.
        sta  $01        // 

        lda  #%01111111 // disable cia-1/2 interrupts.
        sta  $dc0d      //
        sta  $dd0d      //
      
        jsr  isrset     // setup isr as raster interrupt service routine.

        lda  #%00000001 // enable raster interrupt.
        sta  $d01a      //

        lda  $dc0d      // acknowledge cia interrupts.
        
        cli             // let interrupts come.

        // this is our main loop. nothing  useful, just a mix of different length 
        // instructions so  we maximise the raster  interrupt jitter  to simulate
        // real code.
        
loop:    lda  #1         // 2 cycles
        lda  $01        // 3 cycles
        lda  $0300      // 4 cycles
        lda  ($04),y    // 5 cycles
        lda  ($04,x)    // 6 cycles
        lsr  $0300,x    // 7 cycles
        jmp  loop
// *                                                                           *
// *****************************************************************************

// *****************************************************************************
// * this is the first raster interrupt  service routine.  by the time we come * 
// * here we  can be  anywhere on  the  desired line with a jitter of 7 cycles * 
// * depending  on the  instruction executing  when the interrupt happened.    *

isr:     pha            // preserve a,x,y on the stack.
        txa             //
        pha             //
        tya             //
        pha             //
                
        tsx             // we  are about to let  another interrupt happen without
                        // calling rti, so there will be one extra return address 
                        // on  the stack. save the  good stack pointer into x, we 
                        // will restore it later before rti.
        
        inc  $d012      // setup another raster interrupt for the next
        lda  #<isr2     // scan line to be served by isr2.
        sta  $fffe      //
        lda  #>isr2     //
        sta  $ffff      //

        lsr  $d019      // acknoweledge video interrupt and allow the next raster        
        cli             // interrupt to occour.

        ldy #5          // waste time waiting  the interrupt to happen  in one of 
        dey             // the nops below, which  take 2 cycles, so  the next isr      
        bne *-1         // will be called with a jitter of just 1 cycle.

        nop             
        nop             
        nop             
        nop             
// *                                                                           *
// *****************************************************************************

// *****************************************************************************
// * this is  the  second  raster interrupt routine. by the  time we come here *
// * we have a jitter of just one cycle. next  we ensure  we spend the exact   *  
// * amount of cycles it takes to draw a full scan line. the last beq *+2 we   *
// * use does the sync magic. see notes below. this  is  timed for pal systems *
// * the delay loop needs to be changed for ntsc.

                        // interrupt servicing (during a nop)          7/8 cycles
isr2:    txs             // restore the sp messed by the interrupt.       2 cycles

        ldx  #8         // the interrput servicing call and the code
        dex             // in this block are timed to last exactly one
        bne  *-1        // line (63 cycles for pal) so that cmp $d012
                        // happens either one cycle before the next 
                        // raster line or just at the beginning of it.
                        //                                              46 cycles
        bit $00         //                                               3 cylces                                                     

        lda  $d012      // get current scan line                         4 cycles
        cmp  $d012      // here we are either still on the same line     4 cycles
                        // (with one cycle to go) or at the next line.
        beq  *+2        // if we are on same line branch (3 cycles)    3/2 cycles
                        // else move on (2 cycles). note that in both
                        // cases we end up at the next instruction, but it
                        // will take different time to get there so we
                        // offset the remaining 1 cycle jitter.

                        // from here on we are stable.
                
        lda  #1         // change border and background  to  white for few cycles 
        sta  $d020      // so we show where our code is run on the screen.
        //sta  $d021      // 

rasterz:
        ldx #0
internalloop:
         lda $d012   //RASTER change yet?
         cmp $d012
         bne internalloop   //If no waste 1 more
         inx
         inc $d020
         cpx #10
         bcs internalloop
        //lda  ($04,x)    // just wait 6 cycles to make the bar longer.
        //lda  ($04,x)    // just wait 6 cycles to make the bar longer.
        
        lda  #6         // restore border and background colors.
        sta  $d020     //
        //lda  #14        //
        //sta  $d020      //
      
        jsr isrset      // set raster interrupt for the next screen.

        pla             // restore y,x,a from the stack.
        tay             //
        pla             //
        tax             //
        pla             //

        rti
// *                                                                           *
// *****************************************************************************

// *****************************************************************************
// * setup a raster interrupt to be serviced on line 91 by isr.                 *

isrset:  pha             // preserve a so we can restore it before returning.

        lda  #92        // set raster interrupt for line 91.
        sta  $d012
        lda  #%01111111 // clear rst8 bit, the interrupt line is
        and  $d011      // above raster line 255.
        sta  $d011
       
        lda  #<isr      // set the interrupt vector back to the first isr
        sta  $fffe      // (the raster sync one).
        lda  #>isr
        sta  $ffff

        lsr  $d019      // acknoweledge video interrupts.

        pla             // restore a as it was before the call.

        rts
// *                                                                           *
// *****************************************************************************