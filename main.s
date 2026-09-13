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
.equ PSR10 , 0x01

.equ TIMSK0, 0x39
.equ OCIE0A, 0x04

.equ TCCR0A, 0x2F
.equ WGM01 , 0x02

.equ TCCR0B, 0x33
.equ CS00  , 0x01
.equ CS02  , 0x04

.equ OCR0A , 0x36
.equ TCNT0 , 0x32

.equ GIMSK , 0x3B
.equ PCIE  , 0x20
.equ INT0  , 0x40

.equ GIFR  , 0x3A

.equ MCUCR , 0x35
.equ ISC01 , 0x02
.equ ISC00 , 0x01
.equ SE    , 0x20

.equ PCMSK , 0x15
.equ PCINT4, 0x10

.equ TIFR0 , 0x38

.equ PB0   , 0x01                       ; Motorola 68000 RESET OUT pin
.equ PB0b  , 0
.equ PB1   , 0x02                       
.equ PB1b  , 1
.equ PB2   , 0x04                       ; Motorola 68000 HALT  OUT pin
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
    ;rjmp INT                           ; External Interrupt Request 0

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
PCINT:
    sbic PINB, PB4b                     ; If PB4 is low,  skip next instruction
    reti                                ; If PB4 is high, return from interrupt 

    out GIMSK, r0                       ; Disable Pin Change Interrupt

    rcall sleep_dis                     ; Sleep Disable - 7.5.2 MCUCR - MCU Control Register 
    out DDRB, r21                       ; Motorola 68000 RESET is ACTIVE LOW, so we change output from Hi-Z to logical low

    out OCR0A, r17                      ; Number of ticks after ~10ms  -  M68000 - 5.5 Reset Operation 
    out TIMSK0, r19                     ; Set OCIE0A bit to enable Compare Match with OCR0A register
    out TIFR0, r1                       ; Clear any previous Compare Match interrupt requests
    out GTCCR, r0                       ; Clear TSM bit and start Timer/Counter0

    reti

; -------------------------------------
TIM0_COMPA:
    rcall sleep_dis                     ; Sleep Disable - 7.5.2 MCUCR - MCU Control Register 

    out GTCCR, r18                      ; Set TSM and PSR10 bits and stop Timer/Counter0
    out TCNT0, r0                       ; Clear TCTN0 register so it's in a known state
    out TIMSK0, r0                      ; Clear OCIE0A bit to disable Compare Match with OCR0A register

    out DDRB, r0                        ; Motorola 68000 RESET and HALT are ACTIVE LOW bi-directional, so we set PB0 and PB1 to Hi-Z

    out GIFR, r1                        ; Clear any pending ISR requests for PCINT
    out GIMSK, r20                      ; Enable Pin Change Interrupt 
    reti                                ; Return from interrupt
; -----------------------------------------------------------------------------


main:
    ; Motorola 68000 - Initial RESET routine
    ; -------------------------------------------------------------------------
    ; IO setup
    ; ---------------------------------
    ldi r21, (PB0 | PB2)   
    out DDRB, r0                        ; All DDRB IO pins as input             
    out DDRB, r21                       ; PB0 and PB2 as output

    ldi r16, (PB1 | PB4)
    out PORTB, r0                       ; All PORTB IO output logical LOW
    out PORTB, r16                      ; PB1 and PB4 pull-up resistors

    ldi r16, PCINT4
    out PCMSK, r16                      ; Pin Change Enable Mask on PCINT4 aka PB4

    ldi r20, PCIE
    out GIMSK, r16                      ; Enable Pin Change Interrupt 

    timer:
        ; Timer/Counter0 Setup
        ; ---------------------------------
        ldi r17, 15                     ; External Reset Signal cycles time

        ldi r18, (TSM | PSR10)
        out GTCCR, r18                  ; Set TSM and PSR10 bits and stop Timer/Counter0

        ldi r19, OCIE0A
        out TIMSK0, r19                 ; Set OCIE0A bit to enable Compare Match with OCR0A register

        ldi r16, WGM01
        out TCCR0A, r16                 ; Set WGM01 bit to enable CTC mode
        
        ldi r16, (CS02 | CS00)
        out TCCR0B, r16                 ; Set CS02 and CS00 bits to enable prescaler /1024

        ldi r16, 140
        out OCR0A, r16                  ; Number of ticks after ~120ms  -  M68000 - 5.5 Reset Operation 
        out TCNT0, r0                   ; Clear TCTN0 register so it's in a known state
        out GTCCR, r0                   ; Clear TSM bit and start Timer/Counter0
        out TIFR0, r1                   ; Clear any previous Compare Match interrupt requests

        rcall sleep_en                  ; Sleep Enable - 7.5.2 MCUCR - MCU Control Register
    ; -------------------------------------------------------------------------
    loop:
        sleep                           
        rjmp loop                       ; Loop if flag is not set


; Utils Functions
; -----------------------------------------------------------------------------
; Sleep Control
; -------------------------------------
sleep_en:
    cli                                 ; Disable Interrupts
    in r16, MCUCR
    sbr r16, SE
    out MCUCR, r16                      ; Sleep Enable - 7.5.2 MCUCR - MCU Control Register
    sei                                 ; Enable Interrupts
    ret

sleep_dis:                              ; Disable Interrupts
    in r16, MCUCR
    cbr r16, SE
    out MCUCR, r16                      ; Sleep Disable - 7.5.2 MCUCR - MCU Control Register 
    ret
; -----------------------------------------------------------------------------
