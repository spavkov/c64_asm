:BasicUpstart2(start)

.var picture = LoadBinary("indus3.koa", BF_KOALA)

// https://sta.c64.org/cbm64mem.html
// https://www.lemon64.com/forum/viewtopic.php?t=82157

.label REG_INTSERVICE_LOW      = $0314              // interrupt service routine low .byte
.var REG_INTSERVICE_HIGH     = $0315              // interrupt service routine high .byte
.var REG_SCREENCTL_1         = $d011              // screen control register #1
.var REG_RASTERLINE          = $d012              // raster line position 
.var REG_SCREENCTL_2         = $d016              // screen control register #2
.var REG_MEMSETUP            = $d018              // memory setup register
.var REG_INTFLAG             = $d019              // interrupt flag register
.var REG_INTCONTROL          = $d01a              // interrupt control register
.var REG_BORCOLOUR           = $d020              // border colour register
.var REG_BGCOLOUR            = $d021              // background colour register
.var REG_INTSTATUS_1         = $dc0d              // interrupt control and status register #1
.var REG_INTSTATUS_2         = $dd0d              // interrupt control and status register #2

                        // constants

.var C_SCREEN_RAM            = $0400              // screen RAM
.var C_COLOUR_RAM            = $d800              // colour ram

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

                        // create initial interrupt

                        sei                     // set up interrupt
                        lda #$7f
                        sta REG_INTSTATUS_1     // turn off the CIA interrupts
                        sta REG_INTSTATUS_2
                        and REG_SCREENCTL_1     // clear high bit of raster line
                        sta REG_SCREENCTL_1

                        ldy #000
                        sty REG_RASTERLINE

                        lda #<sync_intro        // load interrupt address
                        ldx #>sync_intro
                        sta REG_INTSERVICE_LOW
                        stx REG_INTSERVICE_HIGH

                        lda #$01                // enable raster interrupts
                        sta REG_INTCONTROL
                        cli


                        // forever loop

forever:                 jmp forever


                        // helper routines -------------------------------------------------------------------------------------------------]
                        // -----------------------------------------------------------------------------------------------------------------]

apply_interrupt:        sta REG_RASTERLINE              // apply next interrupt
                        stx REG_INTSERVICE_LOW
                        sty REG_INTSERVICE_HIGH
                        jmp $ea81


                        // intro sync ------------------------------------------------------------------------------------------------------]
                        // -----------------------------------------------------------------------------------------------------------------]

sync_intro:              inc REG_INTFLAG                 // acknowledge interrupt
                       
                        lda #255                        // init video garbage
                        sta $3fff                       // fill to highlight fld for debugging

                        lda #001                        // test characters 
                        sta $400                        // used to verify character positions before / after fld
                        sta $770

                        jmp hook_init_frame_fld


                        // init frame fld state --------------------------------------------------------------------------------------------]
                        // -----------------------------------------------------------------------------------------------------------------]

hook_init_frame_fld:    lda #015
                        ldx #<init_frame_fld
                        ldy #>init_frame_fld
                        jmp apply_interrupt


init_frame_fld:          inc REG_INTFLAG

                        lda #$1b                        // restore register to default
                        sta REG_SCREENCTL_1

                        jmp hook_bitmap_start


                        // begin rendering bitmap ------------------------------------------------------------------------------------------]
                        // -----------------------------------------------------------------------------------------------------------------]

hook_bitmap_start:       lda #057
                        ldx #<render_bitmap_start
                        ldy #>render_bitmap_start
                        jmp apply_interrupt


render_bitmap_start:    ldx #000                        // apply fld effect to top of logo
                        beq bitmap_top_fld_done         // no fld? then skip past this

wait_bitmap_top_fld:     lda REG_RASTERLINE
                        cmp REG_RASTERLINE
                        beq wait_bitmap_top_fld + 3
                        lda REG_SCREENCTL_1
                        adc #001                        // delay next bad scan line 
                        and #007
                        ora #$18
                        sta REG_SCREENCTL_1
                        dex
                        bne wait_bitmap_top_fld

bitmap_top_fld_done:    ldx #012                        // wait for raster to get into position for bitmap
                        dex
                        bne bitmap_top_fld_done + 2

                        inc REG_INTFLAG                 // acknowledge interrupt
                
                        clc
                        lda REG_SCREENCTL_1             // switch bitmap mode on
                        and #007
                        adc #056        
                        sta REG_SCREENCTL_1
    lda %00110000 // sets screen off (bit 0) and bitmapped mode (bit 5)
	sta $d018
	lda %00000100 //  turn on vic multi-color mode
	sta $d016
                        jmp hook_bitmap_end


                        // complete rendering bitmap ---------------------------------------------------------------------------------------]
                        // -----------------------------------------------------------------------------------------------------------------]

hook_bitmap_end:        lda #121
                        ldx #<render_bitmap_end
                        ldy #>render_bitmap_end
                        jmp apply_interrupt


render_bitmap_end:      ldx #015
wait_bitmap_bot_fld:    lda REG_RASTERLINE
                        cmp REG_RASTERLINE
                        beq wait_bitmap_bot_fld + 3
                        lda REG_SCREENCTL_1
                        adc #001
                        and #007
                        ora #056
                        sta REG_SCREENCTL_1
                        dex
                        bpl wait_bitmap_bot_fld 

                        ldx #008
latch_final_bitmap_line: dex
                        bne latch_final_bitmap_line

                        inc REG_INTFLAG                 // acknowledge interrupt

                        clc
                        //lda REG_SCREENCTL_1             // bitmap off
                        //and #007                        // maintain current vertical scroll bits
                        //adc #024
                        //sta REG_SCREENCTL_1

	lda #$3B
	sta $d011
    lda %00110000 // sets screen off (bit 0) and bitmapped mode (bit 5)
	sta $d018
	lda %00000100 //  turn on vic multi-color mode
	sta $d016
	lda #$3B
	sta $d011

                        jmp hook_update_logo_fld


                        // update fld effect -----------------------------------------------------------------------------------------------]
                        // -----------------------------------------------------------------------------------------------------------------]

hook_update_logo_fld:   lda #250
                        ldx #<update_logo_fld
                        ldy #>update_logo_fld
                        jmp apply_interrupt


update_logo_fld:         inc REG_INTFLAG

                        dec logo_bounce_delay                   // smooth logo bounce effect
                        bne update_logo_fld_done
                        lda #002
                        sta logo_bounce_delay

                        ldx logo_bounce_index                   // advance bounce height index
                        inx
                        txa
                        and #015                                // loop bounce index to start
                        sta logo_bounce_index 

                        clc
                        tax
                        lda logo_bounce_heights, x              // grab next height
                        tay
                        adc #121                                // adjust bitmap ending interrupt
                        sta hook_bitmap_end + 1
                        sty render_bitmap_start + 1             // set number of fld lines before the bitmap
                        clc
                        lda #016                                // set number of fld lines after the bitmap
                        sbc render_bitmap_start + 1             
                        sta render_bitmap_end + 1

update_logo_fld_done:    jmp hook_init_frame_fld


                        // variables -----------------------------------------------------------------------------------------------------]
                        // -----------------------------------------------------------------------------------------------------------------]

logo_bounce_heights:     .byte 000, 000, 001, 001, 003, 005, 008, 013, 015, 012, 009, 006, 003, 001, 001, 000
logo_bounce_index:       .byte 000
logo_bounce_delay:       .byte 002





*=$0c00	"ScreenRam"; 		.fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$1c00	"ColorRam:"; colorRam: 	.fill picture.getColorRamSize(), picture.getColorRam(i)
*=$2000	"Bitmap";			.fill picture.getBitmapSize(), picture.getBitmap(i)