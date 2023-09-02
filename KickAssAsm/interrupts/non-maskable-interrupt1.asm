// found here https://www.lemon64.com/forum/viewtopic.php?p=855342#855342
// it uses two CIA timers, and changes the color of border every second
// Timer A counts cycles 985248 (=$F08A0) cycles per second and then underflows
// Timer B just counts Timer A underflos ($0f of them) and then triggers the NMI which is on our mynmi 

.label raster   = $d012  // current raster line
.label intflag  = $d019  // interrupt flag reg

.label frame_color_register    = $d020  // frame color
.label border_color_register   = $d021  // border color

.label nmi_vector_low   = $0318  
.label nmi_vector_high   = $0319  

.label InterruptControlAndStatusRegister = $dd0d //more info here https://sta.c64.org/cbm64mem.html


BasicUpstart2(start)
start:
    ldx InterruptControlAndStatusRegister // save the current state of interrupts
    lda #%01111111 // load value to disable all to accumulator. in bit 7 we say we want to store zero, and then in bits 0-4 (bits 5 and 6 are unused) we put 1s to say we want to set those bits
    sta InterruptControlAndStatusRegister // store this back to interrupts register to disable all
    // now that we disabled all interrupts, we can safely set the new NMI vector to point to our routine
    lda #<mynmi
    sta nmi_vector_low
    lda #>mynmi
    sta nmi_vector_high

    // 985248 (=$F08A0) cycles per second -> for PAL , for NTSC you need to use different values
    // load timer A with $F08A and timer B with #$10
    
    lda #$89 // $8A - 1 (because timer does not fire on zero but on unerflow)
    sta $dd04 // Low byte for Timer A
    lda #$f0  
    sta $dd05 // high byte for Timer A
    lda #$f // #$10 -1 (because timer does not fire on zero but on unerflow)  //https://www.lemon64.com/forum/viewtopic.php?t=70222&start=15
    sta $dd06
    lda #$00
    sta $dd07

    lda     #$11
    sta     $dd0e           // start timer A counting cycles
    lda     #$51
    sta     $dd0f           // start timer B counting timer A underflows    

    lda     #$82
    sta     InterruptControlAndStatusRegister          // enable NMI on timer B underflows

mynmi:
    pha
    lda     $dd0d
    bpl     done            // NMI is not from CIA2 so jump to rti
    inc     $d020           // do something visible
done:           
    pla
    rti