/**************************************************************************
 *	    File: Lab05.asm
 *  Lab Name: Pardon the Interruption...
 *    Author: Dr. Greg Nordstrom
 *   Created: 02/19/2021
 * Processor: ATmega128A (on the ReadyAVR board)
 *
 * Modified by: Christian Sorensen
 * Modified on: 09/30/2026
 *
 * This program uses the ReadyAVR joystick to toggle up and down the
 * frequency of its BOOT LED between 1 and 15 Hz. The blink rate is
 * visually displayed on LEDs 0-3 as a four-bit binary number.
 *
 *************************************************************************/

 /*********
 * Interrupt Jump Table
 *********/
.org 0x0000                 ; next instruction address is 0x0000
	JMP main	            ; (the location of the reset vector)

.org INT1addr				; address of INT1 routine (joystick up)
	JMP ISRJoystickUp

.org INT3addr				; address of INT3 routine (joystick down)
	JMP ISRJoystickDown

rjmp main					; allow reset to run this program

/**********
* Main code
**********/
.def BlinkFreq = R20		; holds the current blink rate (1-15 Hz)
.equ BlinkFreqMin = 1
.equ BlinkFreqMax = 15
.equ InitialBlinkFreq = BlinkFreqMin

.org 0x0020					; Move the "main" to 0x0020 to make room for ISRs
main:                       ; jump here on reset
    ldi R16, HIGH(RAMEND)   ; initialize stack (default RAMEND = 0x10FF)
    out SPH, R16
    ldi R16, low(RAMEND)
    out SPL, R16

	/* Additional Setup before Main Loop */

	LDI R16,0x00
	OUT DDRB,R16			; DDRB: set pins 1 and 3 as inputs (up/down joystick)

	LDI R16,0x0F	
	OUT DDRC,R16			; set pins 3:0 as outputs (blink rate LEDs)

	SBI PORTC,PORTC3
	SBI PORTC,PORTC2
	SBI PORTC,PORTC1		; initial blink rate 1 Hz (0001)

	LDI R16,0x00
	OUT DDRD,R16			; DDRD: set pins 1 and 3 as inputs

	LDI R16,0x0A
	OUT PORTB,R16			; Set internal pull-ups on pins 1 and 3

	LDI R16, (1<<ISC11)|(1<<ISC10)|(1<<ISC31)|(1<<ISC30)
	STS EICRA, R16			; Set INT1 and INT3 to activate on RISING edge

	LDI R16, (1<<INT1)|(1<<INT3)
	OUT EIMSK, R16			; Allow INT1 and INT3 to generate interrupts

	SEI						; Enable global interrupts

	LDI  R16,(1<<DDA7)		; Set the mask to make Port A.7 an output
	OUT  DDRA,R16			; Load bitmask to PORTA register

	LDI BlinkFreq, InitialBlinkFreq
 
mainLoop:
    CBI  PORTA, PORTA7       ; turn BOOT LED on (active low) by clearing PORTA.7

    ; kill some time
    LDI R16, 0x10              ; R16 is outer loop counter
	MOV R19, BlinkFreq
	NEG R19
	ADD R16, R19

outer_loop1:
    ldi R24, low(0xFFFF)     ; load low and high parts of R25:R24 pair with
    ldi R25, high(0xFFFF)    ; loop count by loading registers separately
    inner_loop1:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop1    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop1        ; loop back if R16 isn't zero

    sbi PORTA, PORTA7       ; turn BOOT LED off (active low) by setting PORTA.7

	; kill some time
    LDI R16, 0x10              ; R16 is outer loop counter
	MOV R19, BlinkFreq		   
	NEG R19
	ADD R16, R19					

outer_loop2:
    ldi R24, low(0xFFFF)     ; load low and high parts of R25:R24 pair with
    ldi R25, high(0xFFFF)    ; loop count by loading registers separately
    inner_loop2:
        sbiw R24, 1         ; decrement inner loop counter (R25:R24 pair)
        brne inner_loop2    ; loop back if R25:R24 isn't zero
    dec R16                 ; decrement the outer loop counter (R16)
    brne outer_loop2        ; loop back if R16 isn't zero

    rjmp mainLoop           ; play it again, Sam...

/**********
* ISR code
**********/
.org 0x0200							; Load the ISR code higher than main code

ISRJoystickUp:
	PUSH R18
	IN R18,SREG
	PUSH R18						; Preserve SREG

	CPI BlinkFreq,BlinkFreqMax
	BREQ end_INT1
	INC BlinkFreq
	
	end_INT1:
	MOV R17, BlinkFreq	
	LSR R17
	BRCS bit0_on
	SBI PORTC, PORTC0
	JMP next0

	bit0_on:
	CBI PORTC, PORTC0

	next0:
	LSR R17
	BRCS bit1_on
	SBI PORTC, PORTC1
	JMP next1

	bit1_on:
	CBI PORTC, PORTC1

	next1:	
	LSR R17
	BRCS bit2_on
	SBI PORTC, PORTC2
	JMP next2

	bit2_on:
	CBI PORTC, PORTC2

	next2:	
	LSR R17
	BRCS bit3_on
	SBI PORTC, PORTC3
	JMP next3

	bit3_on:
	CBI PORTC, PORTC3

	next3:
	POP R18
	OUT SREG,R18
	POP R18
	RETI

ISRJoystickDown:			; Preserve SREG
	PUSH R18
	IN R18,SREG
	PUSH R18

    CPI  BlinkFreq, BlinkFreqMin
    BREQ end_INT3 
    DEC  BlinkFreq

	end_INT3:
	MOV R17, BlinkFreq	
	LSR R17
	BRCS bit00_on
	SBI PORTC, PORTC0
	JMP next00

	bit00_on:
	CBI PORTC, PORTC0

	next00:
	LSR R17
	BRCS bit01_on
	SBI PORTC, PORTC1
	JMP next01

	bit01_on:
	CBI PORTC, PORTC1

	next01:
	LSR R17
	BRCS bit02_on
	SBI PORTC, PORTC2
	JMP next02

	bit02_on:
	CBI PORTC, PORTC2

	next02:	
	LSR R17
	BRCS bit03_on
	SBI PORTC, PORTC3
	JMP next03

	bit03_on:
	CBI PORTC, PORTC3

	next03:
	POP R18
	OUT SREG,R18
	POP R18
    RETI