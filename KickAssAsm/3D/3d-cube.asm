// Rotating Wireframe Cube Example for Commodore 64
// Written for KickAssembler

:BasicUpstart2(start)

// Rotating Wireframe Cube Example for Commodore 64
// Written for KickAssembler

start:
    lda #$00
    sta $d020                 // Set border color to black
    sta $d021                 // Set background color to black

    // Clear screen
    ldx #$00
clear_screen:
    lda #$20
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne clear_screen

    // Set up initial angles
    lda #$00
    sta angle_x
    sta angle_y

    // Main loop
main_loop:
    jsr clear_screen          // Clear the screen before drawing
    jsr rotate_cube
    jsr project_cube
    jsr draw_cube
    jmp main_loop

// Define the cube vertices in 3D (8 vertices, each 3 bytes: X, Y, Z)
cube_vertices:
    .byte $f0,$f0,$f0  // Vertex 0: (-1,-1,-1)
    .byte $10,$f0,$f0  // Vertex 1: (1,-1,-1)
    .byte $10,$10,$f0  // Vertex 2: (1,1,-1)
    .byte $f0,$10,$f0  // Vertex 3: (-1,1,-1)
    .byte $f0,$f0,$10  // Vertex 4: (-1,-1,1)
    .byte $10,$f0,$10  // Vertex 5: (1,-1,1)
    .byte $10,$10,$10  // Vertex 6: (1,1,1)
    .byte $f0,$10,$10  // Vertex 7: (-1,1,1)

// Screen coordinates of the projected points
screen_x:
    .byte 0,0,0,0,0,0,0,0
screen_y:
    .byte 0,0,0,0,0,0,0,0

// Rotation angles
angle_x:        .byte 0
angle_y:        .byte 0

rotate_cube:
    // Increment angles
    inc angle_x
    inc angle_y

    // Rotate each vertex in the cube
    ldx #0
rotate_loop:
    lda cube_vertices,x
    sec
    sbc #128           // Center X around 0
    sta temp_x

    lda cube_vertices+1,x
    sec
    sbc #128           // Center Y around 0
    sta temp_y

    lda cube_vertices+2,x
    sec
    sbc #128           // Center Z around 0
    sta temp_z

    // Rotate around X-axis
    ldy temp_y
    ldx temp_z
    jsr rotate_x
    sta rotated_y
    sty rotated_z

    // Rotate around Y-axis
    ldy rotated_z
    ldx temp_x
    jsr rotate_y
    sta rotated_z
    sty rotated_x

    // Store the rotated coordinates
    lda rotated_x
    sta temp_x
    lda rotated_y
    sta temp_y
    lda rotated_z
    sta temp_z

    // Store the projected 2D coordinates
    lda temp_x
    clc
    adc #128           // Re-center X
    sta screen_x,x

    lda temp_y
    clc
    adc #128           // Re-center Y
    sta screen_y,x

    inx
    inx
    inx
    cpx #24            // Loop for all 8 vertices
    bne rotate_loop
    rts

rotate_x:
    // Rotate around X: (Y, Z) -> (Y*cos - Z*sin, Y*sin + Z*cos)
    lda angle_x
    sta temp_angle
    lda sin_table,y
    sta temp_cos
    lda cos_table,y
    sta temp_sin

    lda temp_cos
    ldy temp_y
    clc
    adc cos_table,y
    sta rotated_y

    lda temp_sin
    ldy temp_z
    clc
    adc sin_table,y
    sta rotated_z
    rts

rotate_y:
    // Rotate around Y: (X, Z) -> (X*cos + Z*sin, Z*cos - X*sin)
    lda angle_y
    sta temp_angle
    lda sin_table,y
    sta temp_cos
    lda cos_table,y
    sta temp_sin

    lda temp_cos
    ldy temp_x
    clc
    adc cos_table,y
    sta rotated_x

    lda temp_sin
    ldy temp_z
    clc
    adc sin_table,y
    sta rotated_z
    rts

project_cube:
    // Project 3D coordinates to 2D screen coordinates
    // using simple perspective projection
    ldx #0
project_loop:
    lda temp_x
    lsr
    lsr
    clc
    adc #160           // Project X to screen
    sta screen_x,x

    lda temp_y
    lsr
    lsr
    clc
    adc #100           // Project Y to screen
    sta screen_y,x

    inx
    cpx #8
    bne project_loop
    rts

draw_cube:
    // Draw lines between vertices to form the cube
    ldx #0
draw_edges:
    lda edge_table,x
    tay
    lda screen_x,y
    sta x1
    lda screen_y,y
    sta y1

    inx
    lda edge_table,x
    tay
    lda screen_x,y
    sta x2
    lda screen_y,y
    sta y2

    jsr draw_line
    inx
    cpx #24
    bne draw_edges
    rts

draw_line:
    // Draw a line from (x1, y1) to (x2, y2)
    lda x1
    sta temp_x
    lda y1
    sta temp_y

    lda x2
    sta x_dest
    lda y2
    sta y_dest

    // Simple line drawing loop (not Bresenham's algorithm)
line_loop:
    lda temp_x
    cmp x_dest
    beq done_line

    lda temp_y
    cmp y_dest
    beq done_line

    // Plot the pixel (character) at temp_x, temp_y
    lda temp_x
    ldx temp_y
    sta $0400,x

    // Move towards the destination
    lda temp_x
    clc
    adc #1
    sta temp_x

    lda temp_y
    clc
    adc #1
    sta temp_y

    jmp line_loop

done_line:
    rts

// Edge table to connect vertices (12 edges)
edge_table:
    .byte 0,1, 1,2, 2,3, 3,0   // Front face
    .byte 4,5, 5,6, 6,7, 7,4   // Back face
    .byte 0,4, 1,5, 2,6, 3,7   // Connecting edges

// Sine and cosine tables (pre-calculated values for rotation)
sin_table:
    .byte $00, $06, $0c, $12, $18, $1e, $24, $2a, $30, $36, $3c, $42, $48, $4e, $54, $5a, $60
cos_table:
    .byte $60, $5a, $54, $4e, $48, $42, $3c, $36, $30, $2a, $24, $1e, $18, $12, $0c, $06, $00

// Temporary variables
temp_x:         .byte 0
temp_y:         .byte 0
temp_z:         .byte 0
rotated_x:      .byte 0
rotated_y:      .byte 0
rotated_z:      .byte 0
x1:             .byte 0
y1:             .byte 0
x2:             .byte 0
y2:             .byte 0
x_dest:         .byte 0
y_dest:         .byte 0
temp_cos:       .byte 0
temp_sin:       .byte 0
temp_angle:     .byte 0