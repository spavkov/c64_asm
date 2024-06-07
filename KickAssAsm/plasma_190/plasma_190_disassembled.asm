;
; **** ZP FIELDS **** 
;
f78 = $78
f80 = $80
;
; **** ZP ABSOLUTE ADRESSES **** 
;
a20 = $20
a21 = $21
a24 = $24
a25 = $25
a26 = $26
a27 = $27
a61 = $61
a62 = $62
a63 = $63
a64 = $64
a80 = $80
aFE = $FE
;
; **** ZP POINTERS **** 
;
pED = $ED
;
; **** FIELDS **** 
;
f0030 = $0030
f0050 = $0050
f00B0 = $00B0
f1E00 = $1E00
f3820 = $3820
f9000 = $9000
f9040 = $9040
f9080 = $9080
f90C0 = $90C0

        * = $0326

; $0326 (ind) - output character                 
ROM_CHROUTi ROL 
ROM_STOPi   =*+$01
        SLO (pED,X)
ROM_GETINi   =*+$01
        INC f78,X
ROM_CLALLi   =*+$01
        LDA #$05
        STA a63
ROM_LOADi   =*+$01
        LDA #$1F
ROM_SAVEi   =*+$01
        STA a61
        STA $D018    ;VIC Memory Control Register
        LDY #$3F
        LDX #$00
b033A   INC a61
b033C   LDA a63
        STA a62
b0340   LDA a61
        STA f9000,X
        STA f90C0,Y
        EOR #$FF
        STA f9080,X
        STA f9040,Y
        STA f3820,X
        INX 
        DEY 
        BMI b036B
        DEC a62
        BPL b0340
        INC a61
        DEC a63
        CLC 
        LDA a64
        ADC a63
        ASL 
        STA a64
        BCS b033C
        BNE b033A
b036B   INY 
a036D   =*+$01
b036C   LDA #$04
        STA f0030,Y
        LDA aFE
        STA f0050,Y
        ADC #$28
        CMP aFE
        STA aFE
        BCS b0381
        INC a036D
b0381   INY 
        CPY #$20
        BNE b036C
j0386   LDY a24
        LDX a25
        LDA #$D0
        STA a0396
b038F   LDA f9000,X
        ADC f9000,Y
a0396   =*+$01
        STA a80
        TXA 
        ADC #$F9
        TAX 
        INY 
        DEC a0396
        BMI b038F
        LDA #$18
        STA a21
b03A5   LDY a21
        LDA f00B0,Y
        STA a20
        LDA f0030,Y
        STA a03C7
        LDA f0050,Y
        STA a03C6
        LDX #$27
b03BA   LDA f80,X
        ADC a20
        LSR 
        LSR 
        LSR 
        TAY 
        LDA f0030,Y
a03C6   =*+$01
a03C7   =*+$02
        STA f1E00,X
        DEX 
        BPL b03BA
        DEC a21
        BPL b03A5
        LDA a26
        ADC #$03
        STA a26
        STA a24
        LDA a27
        ADC #$01
        STA a27
        STA a25
        JMP j0386

