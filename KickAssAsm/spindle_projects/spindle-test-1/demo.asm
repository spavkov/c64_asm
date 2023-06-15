// This is an example demo bundled with Spindle
// linusakesson.net/software/spindle/

	* = $800
entry:
	// Call music init.

	lda	#0
	jsr	$1000

	// Set up raster interrupt.
	lda #00    
	sta $d011   //Turn off the display

	lda	#$ff
	sta	$d012
	lda	#$01
	sta	$d01a
	lsr	$d019

	// Install IRQ handler to call playroutine.

	lda	#<irq
	sta	$fffe
	lda	#>irq
	sta	$ffff
	cli

	// Switch banks so we can watch the loading process.


	// Load the first picture.
	jsr	nextpart

	lda	#$3d
	sta	$dd02
	lda	#$08
	sta	$d018
	lda	#$18
	sta	$d016
	lda	#$0
	sta	$d020

	lda	#$3b
	sta	$d011

	jsr	wait4space
	jsr	nextpart

	jmp	*

nextpart:
	jsr	$200	// Call the loader.

	// Since Spindle 3.0, we cannot load directly into colour RAM, because
	// that wouldn't work with in-place decrunching. So we load the colours
	// just after the vm data, and copy them into place.

	ldx	#0
copy:
	lda	$4000+1000,x
	sta	$d800,x
	lda	$4100+1000,x
	sta	$d900,x
	lda	$4200+1000,x
	sta	$da00,x
	lda	$4300+1000,x
	sta	$db00,x
	inx
	bne	copy

	lda	$6000
	sta	$d021
	rts

wait4space:
	lda	#$ff
	sta	$dc02
	lsr
	sta	$dc00
	lda	#$10
	bit	$dc01
	beq	*-3
	bit	$dc01
	bne	*-3
	rts

	// A simple IRQ to call the playroutine and acknowledge the interrupt.
irq:
	pha
	txa
	pha
	tya
	pha
	jsr	$1003
	pla
	tay
	pla
	tax
	pla
	lsr	$d019
	rti
