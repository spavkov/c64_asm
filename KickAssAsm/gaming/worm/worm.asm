// https://www.youtube.com/watch?v=Tgv46iXWC7Y&ab_channel=GRayDefender
:BasicUpstart2(start)


.label Const_KBD_BUFFER    = $c5                                   // Keyboard matrix
.label Const_UP            = $09                                   //
.label Const_DOWN          = $0c                                   //values
.label Const_LEFT          = $0a                                   //for up down left right
.label Const_RIGHT         = $0d                                   //
.label Const_LEVELUP_KEY   = $16                                   // "T" pressed = increase length of worm
//*****************************************************
// Initialize worm memory areas
//*****************************************************
start:
                    ldx                 #0
                    lda                 #0
loop:                sta                 worm1,x
                    sta                 worm2,x
                    inx
                    dex
                    bne                 loop                
                    lda                 #$93                 // Clear the screen
                    jsr                 $ffd2
                    lda                 #$30                
                    
                    pokeaxy(startx,starty)
main_loop:
                    
                    lda                 #$20                // Erase starting position
                    pokeaxy(startx,starty)

                    lda                 startdir            
                    cmp                 #1                  
                    beq                 down
                    cmp                 #2                                    
                    beq                 left
                    cmp                 #3                  
                    beq                 right

up:                 dec starty
                    jmp cont
down:               inc starty
                    jmp cont
left:               dec startx
                    jmp cont
right:              inc startx
                    jmp cont
cont:               
                    lda                 #$30
                    pokeaxy(startx,starty)
                
                    jsr                 get_key                                 
                    jsr                 delay                                   
                    jmp                 main_loop                    
                    rts
                    

get_key:             lda                 Const_KBD_BUFFER    // Input a key from Keyboard
                    sta $400

_ck_pressed:
                    cmp                 #Const_DOWN         // down - z pressed
                    beq                 downdir
                    cmp                 #Const_RIGHT        // up - w pressed
                    beq                 rightdir
                    cmp                 #Const_LEFT         // left - a pressed
                    beq                 leftdir
                    cmp                 #Const_UP           // right - s pressed
                    beq                 updir
                    cmp                 #Const_LEVELUP_KEY  // T - Pressed - advance a level - cheat
                    beq                 make_bigger            
                    rts
downdir:               
                    lda                 #1                  
                    sta                 startdir            // Down
                    rts
rightdir:              
                    inc $401
                    lda                 #3                  
                    sta                 startdir            // Right
                    rts
updir:               
                    lda                 #0                  
                    sta                 startdir            // Up
                    
                    rts
leftdir:             
                    lda                 #2                  
                    sta                 startdir            // left

                    rts
make_bigger:        inc length
                    rts
//***DELAY ***
delay:               txa
                    pha
                    ldx                 #$ff                
loop1:              ldy                 #0                  
loop2:              dey
                    bne                 loop2
                    dex
                    bne                 loop1              
                    pla
                    rts

startx:              .byte                15,00
starty:              .byte                10,00
startdir:            .byte                00,00
offset:              .byte                00,00
length:              .byte                00,00
map_off_l:           .byte                $00,$28,$50,$78,$A0,$C8,$F0,$18,$40,$68,$90,$b8,$E0,$08,$30,$58,$80,$a8,$d0,$f8,$20,$48,$70,$98,$c0
map_off_h:           .byte                $04,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07
//*****************************************************
// Grab value of screen position located at x,y
// Store result in accumulator
//*****************************************************
.macro peekaxy(param1, param2) {
                    ldx                 param2                  // X value
                    ldy                 param1                  // Y Value
                    lda                 map_off_l,x         // Load map low .byte into $fb
                    sta                 $fb
                    lda                 map_off_h,x         // Load map hig .byte into $fc
                    sta                 $fc
                    lda                 ($fb),y             // Load result into acc
}
//*****************************************************
// Store value of accumulator in screen memory at position
// x, y
//*****************************************************
.macro pokeaxy(param1, param2) {
                    pha
                    ldx                 param2                  // X value
                    ldy                 param1                  // Y value
                    lda                 map_off_l,x         // Load map low .byte into $fb
                    sta                 $fb
                    lda                 map_off_h,x         // Load map high .byte into $fc
                    sta                 $fc
                    pla
                    sta                 ($fb),y             // Store result in screen memory
}
*=$2000
worm1:
*=$2100
worm2: