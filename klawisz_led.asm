;ten program robi proste wykrywanie klawisza
;nie jest jednak najlepszy ze wzglêdu na efekt drgania styków
;nale¿y dodaæ do niego procedurê testowania oko³o 20ms stanu wci¶niêcia klawisza, w ten spo
;sób odró¿niaj±c wci¶niêcie od zak³óceñ.

	list p=P16F84a

	__CONFIG _HS_OSC & _WDTE_OFF & _PWRTE_ON
	include "p16f84a.inc"

;definicje 
	cblock	0ch
	count_to_100ms
    count_to_500ms
    count_to_1s
    	
    activities

	wcisniecie
    W_save
    STATUS_save
	endc

ON  equ 1
OFF equ 0

TASK_TMR0   equ   0
key_pressed     equ 1
led_state       equ    2


led_state_mask  equ     1 << led_state

HOW_MUCH_TO_100MS    equ 4
HOW_MUCH_TO_500MS    equ 19
HOW_MUCH_TO_1000MS    equ 39
LED_PIN        equ      7
KEY_PIN         equ 3
OUT_0_MASK     equ  b'00000001'
RAM_START  equ 0xc
RAM_END     equ 0x4f
    
    org __VECTOR_RESET
    ;org 0h

;wstawianie do pamieci 23h od adrsu C az do F
	goto	BEGIN

    org  __VECTOR_INT
    ;org 4h
    goto interrupt_vector
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
interrupt_vector
    movwf   W_save
    swapf   STATUS,W
    movwf   STATUS_save

	btfsc	INTCON,T0IF
	goto 	tmr0_interrupt

    btfsc   INTCON,INTF
    goto    rb_interrupt
    goto return_from_int
    
tmr0_interrupt
    bcf INTCON,T0IF
    bsf activities,TASK_TMR0
    goto return_from_int

rb_interrupt
    bcf INTCON,INTF
    goto return_from_int

return_from_int
    swapf  STATUS_save,W
    movwf   STATUS

    swapf   W_save,f
    swapf   W_save,W
    retfie
	
;this is for checking of keyboard being pressed every cyclic
;for 10 MHz it is every 26 ms
Cyclic_every
    banksel PORTB
    btfsc   activities,key_pressed
    goto    key_pressed_check

key_pressed_init    
    btfss  PORTB,KEY_PIN
    bsf    activities, key_pressed
    return

key_pressed_check    
    btfss   PORTB,KEY_PIN
    return

    bcf    activities, key_pressed
    movlw       led_state_mask
    xorwf   activities,f

    return

Cyclic_100ms
    clrf    count_to_100ms
    return
Cyclic_500ms
    clrf    count_to_500ms
    return
Cyclic_1s
    clrf    count_to_1s
    banksel activities 
    btfsc   activities,led_state
    goto    LED_OFF

    banksel PORTB
    btfss   PORTB,LED_PIN
    goto    LED_ON
LED_OFF
    bcf  PORTB,LED_PIN
    return
LED_ON
    bsf     PORTB,LED_PIN
    return

Cyclic
    bcf    activities,TASK_TMR0

    movlw   OUT_0_MASK
    xorwf   PORTB,f

    incf   count_to_100ms,f
    incf  count_to_500ms,f
    incf  count_to_1s,f
    
    call    Cyclic_every
    movlw  HOW_MUCH_TO_100MS
    xorwf   count_to_100ms,w
    btfsc   STATUS,Z
    call    Cyclic_100ms 


    movlw  HOW_MUCH_TO_500MS
    xorwf   count_to_500ms,w
    btfsc   STATUS,Z
    call    Cyclic_500ms 

    movlw  HOW_MUCH_TO_1000MS
    xorwf   count_to_1s,w
    btfsc   STATUS,Z
    call    Cyclic_1s 

    return


LOOP
   
	btfsc   activities,TASK_TMR0 
    call 	Cyclic
	
	goto	LOOP


BEGIN
    
    clrf    STATUS ;czyszcze status
	bsf	INTCON,T0IE
    banksel PORTA	
	clrf	PORTA
	clrf	PORTB
	movlw	b'00000000'	;wszystkie linie na wysoko
	movwf	PORTB
	;ustawienia timera

    banksel OPTION_REG
	bsf     OPTION_REG,PS0
	bsf	    OPTION_REG,PS1
	bsf 	OPTION_REG,PS2
	bcf	    OPTION_REG,PSA	;prescaling dla Timer0
	bCf     OPTION_REG,T0CS ;dopiero teraz w³±cz zegar

	movlw	b'01111110'	;ustawiam na wyjscie rb7
	movwf	TRISB


    movlw   RAM_START
    movwf   FSR
Registers_init
    clrf    INDF
    incf    FSR,f
    movlw   RAM_END
    xorwf   FSR,w
    btfss   STATUS,Z
    goto    Registers_init

    banksel PORTB 
    bsf     PORTB,LED_PIN


	bsf	INTCON,GIE
	call 	LOOP
	end
