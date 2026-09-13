; .nolist
; .include "tn13def.inc"
; .list


.section .text
.global RESET
.global main

; Defines - 20.0 Register Summary
; -----------------------------------------------------------------------------
.equ RAMEND, 0x009F
.equ SPL   , 0x3D
.equ SREG  , 0x3F

.equ PORTB , 0x18
.equ DDRB  , 0x17
.equ PINB  , 0x16

.equ GTCCR , 0x28
.equ TSM   , 0x80

.equ TIMSK0, 0x39
.equ OCIE0A, 0x04

.equ TCCR0A, 0x2F
.equ COM0A1, 0x80
.equ COM0A0, 0x40
.equ WGM01 , 0x02

.equ TCCR0B, 0x33
.equ CS00  , 0x01
.equ CS02  , 0x04

.equ OCR0A , 0x36
.equ TCNT0 , 0x32

.equ GIMSK , 0x3B
.equ PCIE  , 0x20
.equ INT0  , 0x40

.equ MCUCR , 0x35
.equ ISC01 , 0x02
.equ ISC00 , 0x01
.equ SE    , 0x20

.equ PCMSK , 0x15
.equ PCINT4, 0x10

.equ PB0   , 0x01                       ; Motorola 68000 RESET and HALT OUT pin
.equ PB0b  , 0
.equ PB1   , 0x02                       ; Motorola 68000 Clock Reference IN pin
.equ PB1b  , 1
.equ PB2   , 0x04
.equ PB2b  , 2
.equ PB3   , 0x08                       
.equ PB3b  , 3
.equ PB4   , 0x10                       ; Motorola 68000 RESET IN  pin
.equ PB4b  , 4
; -----------------------------------------------------------------------------


; Datasheet - 9.1 Interrupt Vectors
; -----------------------------------------------------------------------------
.org 0x0000 * 2
    rjmp RESET                          ; Reset Handler

.org 0x0001 * 2
    rjmp INT                            ; External Interrupt Request 0

.org 0x0002 * 2
    rjmp PCINT                          ; Pin Change Interrupt Request 0

.org 0x0003 * 2
    ;rjmp TIM0_OVF                      ; Timer/Counter Overflow

.org 0x0004 * 2
    ;rjmp EE_RDY                        ; EEPROM Ready

.org 0x0005 * 2
    ;rjmp ANA_COMP                      ; Analog Comparator

.org 0x0006 * 2
    rjmp TIM0_COMPA                     ; Timer0 CompareA Handler

.org 0x0007 * 2
    ;rjmp TIM0_COMPB                    ; Timer0 CompareB Handler

.org 0x0008 * 2
    ;rjmp WDT                           ; Watchdog Time-out

.org 0x0009 * 2
    ;rjmp ADC                           ; ADC Conversion Complete


; -------------------------------------
RESET:
    ldi r16, lo8(RAMEND)                ; Point to lower byte of max RAM address
    out SPL, r16                        ; Set Stack Pointer to lower byte of max RAM address
                                        ; There's no SPH register on ATTiny 13

    clr r16
    mov r0, r16                         ; Use it as Zero Register

    ser r17                
    mov r1, r17                         ; Use it as One Register

    out SREG, r0                        ; Clear Status Register flags
    sei                                 ; Enable Interrupts
    rjmp main                           ; Jump to main function

; -------------------------------------
INT:
    inc r20                             ; Count Motorola external clock cycles
    cp r21, r20
    breq i0eq                           ; Branch if we count at least r21 amount of Motorola external clock cycles
    i0neq:
        reti                            ; Return from ISR otherwise
    i0eq:
        ldi r16, PCIE
        out GIMSK, r16                  ; Disable External Interrupt
        sbi PORTB, PB0b                 ; Motorola 68000 RESET is ACTIVE LOW, so we output logical HIGH after reset routine
        clr r20                         ; Reset Clock Counts counter
        reti                            ; Return from interrupt

; -------------------------------------
PCINT:
    in r16, MCUCR
    cbr r16, SE
    out MCUCR, r16                      ; Sleep Disable - 7.5.2 MCUCR - MCU Control Register 
    
    cbi PORTB, PB0b                     ; Motorola 68000 RESET is ACTIVE LOW, so we output logical LOW during reset routine
    in  r16, GIMSK
    sbr r16, INT0
    out GIMSK, r16                      ; Enable both Pin Change and External Interrupts
    reti

; -------------------------------------
TIM0_COMPA:
    in r16, MCUCR
    cbr r16, SE
    out MCUCR, r16                      ; Sleep Disable - 7.5.2 MCUCR - MCU Control Register 

    out GTCCR, r16                      ; Set TSM bit and stop Timer/Counter0
    out TIMSK0, r0                      ; Clear OCIE0A bit to disable Compare Match with OCR0A register
    sbi PORTB, PB0b                     ; Motorola 68000 RESET is ACTIVE LOW, so we output logical HIGH after reset routine
    reti                                ; Return from interrupt
; -----------------------------------------------------------------------------

main:
    ; Motorola 68000 - Initial RESET routine
    ; -------------------------------------------------------------------------
    ; IO setup
    ; ---------------------------------
    clr DDRB                            ; All DDRB IO pins as input
    sbi DDRB, PB0b                      ; PB0 pin as output

    ldi r16, (PB1 | PB4)
    out PORTB, r0                       ; All PORTB IO output logical LOW
    out PORTB, r16                      ; PB1 and PB4 pull-up resistors

    clr r20                             ; Clock Counts counter
    ldi r21, 135                        ; Clock Counts counter reference value

    ldi r16, (ISC01 | ISC00)            
    out MCUCR, r16                      ; External Interrupt on Rising Edge

    ldi r16, PCINT4
    out PCMSK, r16                      ; Pin Change Enable Mask on PCINT4 aka PB4

    ldi r16, PCIE
    out GIMSK, r16                      ; Enable Pin Change Interrupt 

    ; Timer/Counter0 Setup
    ; ---------------------------------
    ldi r16, TSM
    out GTCCR, r16                      ; Set TSM bit and stop Timer/Counter0

    ldi r16, OCIE0A
    out TIMSK0, r16                     ; Set OCIE0A bit to enable Compare Match with OCR0A register

    ldi r16, WGM01
    out TCCR0A, r16                     ; Set WGM01 bits to enable CTC mode
    
    ldi r16, (CS02 | CS00)
    out TCCR0B, r16                     ; Set CS02 and CS00 bits to enable prescaler /1024

    ldi r16, 125
    out OCR0A, r16                      ; Number of ticks after ~100ms
    out TCNT0, r0                       ; Clear TCTN0 register so it's in a known state

    ldi r16, TSM                        ; Prepare register to clear TSM bit in ISR
    out GTCCR, r0                       ; Clear TSM bit and start Timer/Counter0
    ; -------------------------------------------------------------------------

    loop:
        cli                             ; Disable Interrupts
        in r16, MCUCR
        sbr r16, SE
        out MCUCR, r16                  ; Sleep Enable - 7.5.2 MCUCR - MCU Control Register
        sei                             ; Enable Interrupts
        sleep                           ; Enter Sleep Mode and wait for interrupt

        rjmp loop                       ; Infinite super loop
