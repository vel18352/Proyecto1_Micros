;Archivo:	Proyecto 1
;Dispositivo:   PIC16F887
;Autor:		Emilio Velasquez 18352
;Compilador:	XC8, MPLABX 5.40
;Programa:      Generador de frecuencias
;Hardware:	3 pulsadores, 1 barra led, 4 displays, 1 DAC0832, 1 Opamp LM358
;Creado:	25/02/2023
;Ultima modificacion: 20/03/2023

// CONFIG1
CONFIG FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
CONFIG MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG CP = OFF         // Code Protection bit (Program memory code protection is disabled)
CONFIG CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
CONFIG BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
CONFIG IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG LVP = OFF       // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
CONFIG BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

//#pragma CONFIG statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

PROCESSOR 16F887
#include <xc.inc>
    
UP	EQU	1
DOWN	EQU	0   
SELECT	EQU	2
SHAPE	EQU	3
SQUARE	EQU	0xFF	;Valores pre establecidos 
	
Offset macro numero	;Macro para offset
    movlw   numero	;mueve el valor ingresado y hace una resta
    subwf   Pivote3,0	;Devuelve valor a pivote3
endm 
 
PSECT	udata_bank0	;common memory
  Contador_A:		    DS 1
  Contador_B:		    DS 1
  Unidades:		    DS 1    
  Decenas:		    DS 1    
  Centenas:		    DS 1 
  Unidades_2:		    DS 1    
  Decenas_2:		    DS 1
  Centenas_2:		    DS 1
  Display_Bandera:	    DS 1 
  Display_Valor:	    DS 4
  Contador:		    DS 1
  Selector:		    DS 1
  Selector_2:		    DS 1
  Pivote:		    DS 1
  Pivote2:		    DS 1
  Pivote3:		    DS 1
  Banderita:		    DS 1
      
PSECT	udata_shr	;common memory
  W_TEMP:	DS 1	;1 Byte
  STATUS_TEMP:  DS 1	;1 Byte
    
PSECT resVect,	class=code, abs, delta=2
;------------------------- Vector Reset ---------------------------
ORG 00h			    ;Posicion del reset
resVect:
    PAGESEL main
    goto    main
    
PSECT intVect,	class=code, abs, delta=2
;------------------------- Interrupcion de Reset ---------------------------  
ORG 04h			    ;Posicion para la interrupciones
push:
    movwf   W_TEMP	    ;Se mueve de W a F 
    swapf   STATUS, W	    ;Se hace un swap de status y se almacena en W
    movwf   STATUS_TEMP	    ;Se mueve W a Status Temp  
isr:			    ;Sub Rutinas de interrupcion
    btfsc   RBIF	    ;Se chequea Interrupcion del puerto B
    call    Cambiar_Limites ;Se llama funcion de incrementar o decrementar Puerto B
    btfsc   TMR2IF	    ;Se chequea la bandera de interrupcion TMR2
    call    Mostrar_Display ;Se llama a la funcion de display
    btfsc   T0IF	    ;Se chequea Interrupcion de Timer0
    call    Cuadrada	    ;Se llama funcion de onda cuadrada      
pop:    
    swapf   STATUS_TEMP, W  ;Se hace un swap de STATUS TEMP a W
    movwf   STATUS	    ;se mueve status a F
    swapf   W_TEMP, F	    ;Se hace swap de temp a f
    swapf   W_TEMP, W	    ;se hace swap de temp a w
    retfie		    ;regresa a la interrupcion
;----------------------- SUBRUTINA DE INTERRUPCI?N ----------------------------- 
Cambiar_Limites:
    btfsc   PORTC,5
    call    int_iocbHz
    btfsc   PORTC,4
    call    int_iocbKhz   
    return		    ;Chequea el selector de KHz y Hz para cambiar la configuracion de limites
    
int_iocbHz:     
    btfss   PORTB, DOWN	    ;Se verifica el bit DOWN para incrementar 
    incf    Contador        ;Incrementa Contador
    movf    Contador,0	    ;Mover Contador a W
    sublw   137		    ;Resta 137
    btfss   STATUS,0	    ;Chequea la bandera C
    call    ValH2	    ;Llama la funcion de limite Ssuperior
    btfss   PORTB, UP	    ;Se verifica el bit UP para decrementar
    decf    Contador	    ;Decrementa Puerto A   
    movf    Contador,0	    ;Mover contador a W
    sublw   87		    ;Resta 87
    btfsc   STATUS,0	    ;Chequea la bandera C
    call    ValL2	    ;Llama la funcion de limite inferior
    btfss   PORTB, DOWN	    ;Se verifica el bit DOWN para incrementar 
    incf    Pivote3	    ;Incrementa Pivote 3
    movf    Pivote3,0	    ;Mover Pivote 3 a W
    sublw   50		    ;Restar 50
    btfss   STATUS,0	    ;Chequear la bandera C
    call    ValH3	    ;Llama a la funcion de limite superior
    btfss   PORTB, UP	    ;Se verifica el bit UP para decrementar
    decf    Pivote3	    ;Decrementa Pivote 3    
    movf    Pivote3,0	    ;Se mueve Pivote 3 a W
    sublw   1		    ;Se resta 1 
    btfsc   STATUS,0	    ;Se chquea la bandera C
    call    ValL3	    ;Se llama la funcion de lmite inferior
    btfss   PORTB,SELECT    ;Se verifica el bit SELECT	para cambiar de Hz a Khz
    incf    Selector	    ;Se incrementa selector
    movf    Selector,0	    ;Se mueve selector a W
    andlw   0x01	    ;Se hace un and de 1 con W para no superar 1
    bcf	    RBIF	    ;Se limpia bandera de interrupcion
    return
    
int_iocbKhz:    
    btfss   PORTB, DOWN	    ;Se verifica el bit UP para incrementar 
    incf    Contador	    ;Incrementa Contador
    movf    Contador,0	    ;Mover Contador a W
    sublw   188		    ;Resta 188
    btfss   STATUS,0	    ;Chequea la bandera C
    call    ValH	    ;Llama la funcion de limite Ssuperior
    btfss   PORTB, UP	    ;Se verifica el bit UP para decrementar
    decf    Contador	    ;Decrementa Contador  
    movf    Contador,0	    ;Mover Contador a W
    sublw   138		    ;Resta 138
    btfsc   STATUS,0	    ;Chequea la bandera C
    call    ValL	    ;Llama la funcion de limite inferior
    btfss   PORTB, DOWN	    ;Se verifica el bit DOWN para incrementar 
    incf    Pivote3	    ;Incrementa Pivote 3
    movf    Pivote3,0	    ;Mover pivote 3 a W
    sublw   101		    ;Resta 101
    btfss   STATUS,0	    ;Chequea la bandera C
    call    ValH4	    ;Llama la funcion limite superior
    btfss   PORTB, UP	    ;Se verifica el bit DOWN para decrementar
    decf    Pivote3	    ;Decrementa Puerto A    
    movf    Pivote3,0	    ;Chequea la bandera C
    sublw   51		    ;Resta 51
    btfsc   STATUS,0	    ;Chequea la bandera C
    call    ValL4	    ;Llama la funcion limite inferior
    btfss   PORTB,SELECT    ;Se verifica el bit SELECT	para cambiar de Hz a Khz 
    incf    Selector	    ;Se incrementa selector
    movf    Selector,0	    ;Se mueve selector a W
    andlw   0x01	    ;Se hace un and de 1 con W para no superar 1
    bcf	    RBIF	    ;Se limpia bandera de interrupcion
    return   
Cuadrada:    
    call    reinicio_TMR0   ;Llama la funcion reinicio TMR0
    btfss   Banderita, 0    ;Chequea bit 0 de variable Banderita
    goto    CuadradaOn	    ;Va a la funcion de encender puerto
    goto    CuadradaOff	    ;Va a la funcion de apagar puerto A
    return
CuadradaOn:
    call    reinicio_TMR0   ;Llama funcion reinicio TMR0
    bsf	    Banderita, 0    ;Enciende bit 0 de Banderita
    movf    SQUARE, 0	    
    movwf   PORTA	    ;Escribe el valor de SQUARE PORTA
    return   
CuadradaOff:
    call    reinicio_TMR0   ;Llama a la funcion de TMR0
    bcf	    Banderita, 0    ;Limpia el bit 0 de Banderita
    clrf    PORTA	    ;Limpia PORTA
    return        
PSECT CODE, DELTA=2, ABS
ORG 100h		    ;Posicion del codigo  
;----------- Tabla del display -----------      
Display:		    ;Tabla de display para Anodo comun
    clrf    PCLATH
    bsf	    PCLATH,0
    andlw   0x0F
    addwf   PCL
    retlw   0xC0    ;0
    retlw   0xF9    ;1
    retlw   0x24    ;2
    retlw   0x30    ;3
    retlw   0x19    ;4
    retlw   0x12    ;5
    retlw   0x02    ;6
    retlw   0xF8    ;7
    retlw   0x00    ;8
    retlw   0x10    ;9
    retlw   0x48    ;A
    retlw   0x03    ;B
    retlw   0xC6    ;C
    retlw   0x21    ;D
    retlw   0x06    ;E
    retlw   0x0E    ;F      
;----------- Tablas de display de frecuencias----------
Tabla_Low:		    ;Tabla de decenas y unidades de displays
    clrf    PCLATH
    bsf	    PCLATH,0
    andlw   0xFF
    addwf   PCL
    retlw	10
    retlw	13
    retlw	19
    retlw	22
    retlw	23
    retlw	26
    retlw	31
    retlw	39
    retlw	47
    retlw	49
    retlw	49
    retlw	62
    retlw	76
    retlw	78
    retlw	81
    retlw	96
    retlw	98
    retlw	00
    retlw	01
    retlw	09
    retlw	12
    retlw	19
    retlw	24
    retlw	39
    retlw	45
    retlw	52
    retlw	56
    retlw	60
    retlw	62
    retlw	65
    retlw	69
    retlw	70
    retlw	74
    retlw	85
    retlw	93
    retlw	00
    retlw	05
    retlw	09
    retlw	18
    retlw	20
    retlw	25
    retlw	36
    retlw	41
    retlw	48
    retlw	59
    retlw	66
    retlw	73
    retlw	80
    retlw	88
    retlw	97
    retlw	05
    retlw	14
    retlw	21
    retlw	30
    retlw	38
    retlw	47
    retlw	56
    retlw	65
    retlw	74
    retlw	85
    retlw	94
    retlw	04
    retlw	15
    retlw	24
    retlw	36
    retlw	45
    retlw	56
    retlw	67
    retlw	78
    retlw	90
    retlw	02
    retlw	15
    retlw	25
    retlw	38
    retlw	63
    retlw	70
    retlw	78
    retlw	03
    retlw	18
    retlw	18
    retlw	32
    retlw	47
    retlw	77
    retlw	90
    retlw	93
    retlw	09
    retlw	25
    retlw	42
    retlw	60
    retlw	77
    retlw	95
    retlw	13
    retlw	33
    retlw	51
    retlw	71
    retlw	92
    retlw	12
    retlw	35
    retlw	58
    retlw	79
    retlw	03       
Tabla_Hi:		    ;Tabla de Miles y Centenas de Display   
    clrf    PCLATH
    bsf	    PCLATH,0
    andlw   0xFF
    addwf   PCL
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	7
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	8
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	9
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	10
    retlw	11
    retlw	11
    retlw	11
    retlw	11
    retlw	11
    retlw	11
    retlw	11
    retlw	11
    retlw	11
    retlw	12
    retlw	12
    retlw	12
    retlw	12
    retlw	12
    retlw	12
    retlw	12
    retlw	13
    retlw	13
    retlw	13
    retlw	13
    retlw	13
    retlw	13
    retlw	13
    retlw	13
    retlw	14
    retlw	14
    retlw	14
    retlw	14
    retlw	14
    retlw	14
    retlw	15
    retlw	15
    retlw	15
    retlw	15
    retlw	15
    retlw	16
    retlw	16
    retlw	16
    retlw	16
    retlw	17
;----------------------------- CONFIGURACION -----------------------------------
main:
    call    config_IO
    call    config_reloj
    call    config_iocb
    call    config_int_enable
    call    CONFIG_TMR0	    
    call    Config_TMR2		;Se llaman las sub rutinas de conofiguracion 
;---------------------------- LOOP PRINCIPAL -----------------------------------
loop:
    call    Mover_Valor		;Llama funcion de mover valor a los displays
    call    Display_Datos	;Llama funcion para mover valores de las tablas de displays a los displays
    call    S_Centenas		
    call    S_Centenas2		;Funciones para separar decenas y unidades para mostrarse en displays 
    call    toggle_led		;Cambia la led que indica de Hz y KHz
    goto    loop		;regresa al bucle  
;----------------------------- SUB RUTINAS -------------------------------------
config_IO:
    banksel ANSEL
    clrf    ANSEL
    clrf    ANSELH	    ;I/O Digitales  
;------------ LEDs --------------    
    banksel TRISA
    clrf    TRISA	    ;Salida digital   
    banksel TRISB
    clrf    TRISB	    ;Salida digital	
    banksel TRISC
    clrf    TRISC	    ;Salida digital
    banksel TRISD
    clrf    TRISD	    ;Salida digital 
;------------ PUSH BOTTOM -----------    
    bsf	    TRISB, UP
    bsf	    TRISB, DOWN	    
    bsf	    TRISB, SELECT
    bsf	    TRISB, SHAPE   
    bcf	    PORTC, 5
    bcf	    PORTC, 6	    ;Configuracion de entradas 
;---------- HABILITAR PULL-UP INTERNO ------    
    bcf	    OPTION_REG, 7
    bsf	    WPUB, UP
    bsf	    WPUB, DOWN
    bsf	    WPUB, SELECT
    bsf	    WPUB, SHAPE	    ;Configuracion de Pullup interno
;------------ LIMPIAR PUERTO -------
    banksel PORTA
    clrf    PORTA	    ;Limpiar puerto    
    banksel PORTB
    clrf    PORTB	    ;Limpiar puerto     
    banksel PORTC
    clrf    PORTC	    ;Limpiar puerto   
    banksel PORTD
    clrf    PORTD	    ;Limpiar puerto   
    clrf    Contador_A	    ;Limpiar Contador
    clrf    Contador_B	    ;Limpiar Contador
    movlw   87
    movwf   Contador	    ;Valor inicial para contador
    clrf    Selector	    ;Limpia el selector
    movlw   1		    
    movwf   Pivote3	    ;Valor incial para desfase para la tabla
    bsf	    STATUS, 0	    ;Limpiar STATUS
    clrf    TRISB	    ;Limpia TRISB
    bsf	    TRISB, 2	    ;Setea bit 2 de TRISB
    movlw   0x08	    
    movwf   TRISD	    ;Configuracion de salidas de TRISD
    bcf	    STATUS, 1	    ;Limpia ZERO 
;----------- CONFIGURACION DE IOCB -----------
config_iocb:
    banksel TRISB
    bsf	    IOCB, UP
    bsf	    IOCB, DOWN	      
    bsf	    IOCB, SELECT
    bsf	    IOCB, SHAPE	    ;Se habilita las interrupciones para cambio de estado en Puerto B  
    banksel PORTB
    movf    PORTB, 0	    ;Terminar mistmatch al terminar
    bcf	    RBIF	    ;Se limpia la bandera de interrupcion del Puerto B
    return
;----------- CONFIGURACION DEL RELOJ ----------    
config_reloj:
    banksel OSCCON
    bsf	    IRCF2
    bsf	    IRCF1
    bsf	    IRCF0	    ;Frecuencia de 8 MHz
    bsf	    SCS		    ;Reloj interno
    return
;-------- HABILITACION DE INTERRUPCIONES -------    
config_int_enable:   
    banksel INTCON
    bsf	    GIE		    ;Habilitar interrupciones globales
    bsf	    RBIE	    ;Se habilita la interrupcion de Puerto B
    bcf	    RBIF	    ;Se limpia la bandera de interrupcion del Puerto B
    bsf	    T0IE	    ;Se habilita interrupcion TMR0
    bcf	    T0IF	    ;Se limpia bandera de TMR0
    bsf	    TMR2IE
    bcf	    TMR2IF
    return  
;----------- CONFIGURACION DEL TIMER0 -----------      
CONFIG_TMR0:
    banksel OPTION_REG	    ;Se cambia de banco
    bcf	    T0CS	    ;TMR0 como temporizador
    bcf	    PSA		    ;Prescaler a TMR0
    bcf	    PS2
    bsf	    PS1
    bcf	    PS0		    ;010 prescaler 1 : 8  
    banksel TMR0	    ;Se cambia de banco
    movlw   128
    movwf   TMR0	    ;Se carga Pre carga a TMR0
    bcf	    T0IF	    ;Se limpia bandera de interrupción
    return  
;----------- REINICIAR EL TIMER0 -----------    
reinicio_TMR0:
    banksel TMR0
    movf    Contador,0	    ;Mover Contador a W
    movwf   TMR0	    ;Mover W a F
    bcf	    T0IF	    ;Se limpia bandera de interrupcion
    return    
;--------------- TIMER 2----------------------
Config_TMR2:
    banksel T2CON	    ;Selecciona banco TMR2
    bsf	    TMR2ON	    ;Encender TMR2
    bcf	    T2CKPS1
    bcf	    T2CKPS0	    ;Prescaler a 1:1
    bcf	    TOUTPS3
    bcf	    TOUTPS2
    bcf	    TOUTPS1
    bcf	    TOUTPS0	    ;Postscaler 1:1
    movlw   180
    movwf   PR2		    ;Mover 180 a PR2
    bcf     TMR2IF	    ;Limpiar bandera de interrupcion
    return    
;--------------------Reiniciar timer 2-------------------------------------
Reset_TMR2:
    movlw   180
    banksel PR2		    ;Ir a banco de PR2
    movwf   PR2		    ;Mover 180 a PR2
    banksel PIR1	    ;Regresar al banco de interrupcion
    bcf	    TMR2IF	    ;Limpiar Interrupcion TMR2
    return 
;------------------ Funcion para cambiar led de Hz y Khz-----------------------    
toggle_led:
    btfsc   Selector,1	    ;Chquea bit 1 de selector
    bsf	    PORTC,4	    ;Enciende led de Hz
    btfsc   Selector,1	    ;Chequea bit 1 de selector
    bcf	    PORTC,5	    ;Limpia led de KHz
    btfss   Selector,1	    ;Chequea bit 1 de selector
    bsf	    PORTC,5	    ;Enciende bit de Hz
    btfss   Selector,1	    ;Chequea bit 1 de selector
    bcf	    PORTC,4	    ;Limpia led de Hz
    return    
;------------------------ Cambio de valor de tablas para display-----------------    
Display_Datos:
    Offset 1		    ;Llama la macro de Offset
    call    Tabla_Low	    ;Obtiene el valor de la tabla correspondiente al valor
    movwf   Pivote	    ;Mueve valor de la tabla a pivote para mostrar primeros 2 valores de display
    Offset 1		    ;Llama la macro de Offset
    call    Tabla_Hi	    ;Obtiene el valor de la tabla correspondiente al valor
    movwf   Pivote2	    ;Mueve valor de la tabla a pivote2 para mostrar segundos 2 valores de display
    return
;---------------------------Rutinas para limites-------------------
ValL:
    movlw   138
    movwf   Contador	    ;Funcion para limite inferior en KHz a Contador
    return     
ValH:
    movlw   188
    movwf   Contador	    ;Funcion para limite superior en KHz a Contador
    return    
ValL2:
    movlw   87
    movwf   Contador	    ;Funcion para limite inferior en Hz a Contador
    return       
ValH2:
    movlw   137
    movwf   Contador	    ;Funcion para limite superior en hHz a Contador
    return     
ValL3:
    movlw   1
    movwf   Pivote3	    ;Funcion para limite inferior de pivote3 para tabla en Hz
    return		    
ValH3:
    movlw   50
    movwf   Pivote3	    ;Funcion para limite Superior de pivote3 para tabla en Hz
    return 
ValL4:
    movlw   51
    movwf   Pivote3	    ;Funcion para limite inferior de pivote3 para tabla en KHz
    return       
ValH4:
    movlw   101
    movwf   Pivote3	    ;Funcion para limite Superior de pivote3 para tabla en KHz
    return 
;----------- Mostrar valores en display -----------       
 Mostrar_Display:
    call    Reset_TMR2		    ;Reinicia Timer2 
    bcf	    PORTC, 0		
    bcf	    PORTC, 1		
    bcf	    PORTC, 2		    ;Se limpian selectores de multiplexado
    bcf	    PORTC, 3
    btfsc   Display_Bandera, 0	    ;Se verifica bandera de unidades
    goto    Display_3		    ;De estar encendida escribe valor de unidades
    btfsc   Display_Bandera, 1	    ;Se verifica bandera de decenas
    goto    Display_2		    ;De estar encendida escribe valor de decenas
    btfsc   Display_Bandera, 2	    ;Se verifica bandera de centenas
    goto    Display_1		    ;De estar encendida escribe valor de centenas   
    btfsc   Display_Bandera, 3	    ;Se verifica bandera de centenas
    goto    Display_0		    ;De estar encendida escribe valor de centenas 
    return
;----------- Asignar valores a displays -----------       
Mover_Valor:
    movf    Unidades_2, 0		
    call    Display		
    movwf   Display_Valor	    ;Se mueve el valor de unidades y se carga en PORTD   
    movf    Decenas, 0		
    call    Display		
    movwf   Display_Valor+1	    ;Se mueve el valor de decenas y se carga en PORTD   
    movf    Unidades, 0		
    call    Display		
    movwf   Display_Valor+2	    ;Se mueve el valor centenas y se carga en PORTD
    movf    Decenas_2, 0		
    call    Display		
    movwf   Display_Valor+3	    ;Se mueve el valor centenas y se carga en PORTD
    return    
;----------- Display Unidades-----------
Display_0:
    MOVF    Display_Valor+3, W	;Se mueve valor de MILES a W
    MOVWF   PORTD		;Se muestra en el display
    BSF	    PORTC, 3		;Se enciende display de miles
    BCF	    Display_Bandera, 3	;Se apaga la bandera de miles
    BSF	    Display_Bandera, 2	;Se enciende la bandera de centenas
    RETURN     
Display_1:
    MOVF    Display_Valor, W	;Se mueve valor de CENTENAS a W
    MOVWF   PORTD		;Se muestra en el display
    BSF	    PORTC, 2		;Se enciende set-display de centenas
    BCF	    Display_Bandera, 2	;Se apaga la bandera de centenas
    BSF	    Display_Bandera, 1	;Se enciende la bandera de decenas  
    RETURN
Display_2:
    MOVF    Display_Valor+1, W	;Se mueve valor de DECENA a W
    MOVWF   PORTD		;Se muestra en el display
    BSF	    PORTC, 1		;Se enciende set-display de decenas
    BCF	    Display_Bandera, 1	;Se apaga la bandera de decenas
    BSF	    Display_Bandera, 0	;Se enciende la bandera de unidades
    RETURN   
Display_3:
    MOVF    Display_Valor+2, W	;Se mueve valor de UNIDADES a W
    MOVWF   PORTD		;Se muestra en el display
    BSF	    PORTC, 0		;Se enciende display de unidades
    BCF	    Display_Bandera, 0	;Se apaga la bandera de unidades
    BSF	    Display_Bandera, 3	;Se enciende la bandera de centenas
    RETURN     
;----------- Sub Rutinas para separar valor ----------- 
;----------- Separar Centenas -----------   
S_Centenas:
    clrf    Centenas		
    clrf    Decenas		
    clrf    Unidades		;Limpiar variables     
    movf    Pivote, 0		;Se transfiere el valor de PORTA
    movwf   Contador_A		;Mover a Contador_A
    movlw   100			;100 a W
    subwf   Contador_A, 1	;Restar 100 a Contador_A
    incf    Centenas		;Incrementar Centenas
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Centenas		;Si no enciende resta una Centena compensando al momento de re evaluar PORTA
    movlw   100			;100 a W
    addwf   Contador_A, 1	;Añadir 100 para compensar el numero negativo
    call    S_Decenas	        ;Ir a sub rutina de Dececnas   
    return
;----------- Separar Decenas -----------       
S_Decenas:
    movlw   10			;10 a W
    subwf   Contador_A, 1	;Se resta 10 a Contador_A
    incf    Decenas		;Incrementar Decenas
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Decenas		;Si no enciende incrementa una Decima para compensar al re evaluar PORTA
    movlw   10			;10 a W
    addwf   Contador_A, 1	;Añadir 10 para compensar numero negativo
    call    S_Unidades		;Ir a sub rutina de Unidades  
    return
;----------- Separar Unidades -----------       
S_Unidades:
    movlw   1			;1 a W
    subwf   Contador_A, 1	;Se resta 1 a Contador_A
    incf    Unidades		;Incrementar Unidades
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Unidades		;Si no enciende incrementa una Unidad para compensar al re evaluar PORTA
    movlw   1			;1 a W
    addwf   Contador_A, 1	;Incrementar 1 para compensar negativo en este caso da 0
    return 
;----------- Sub Rutinas para separar valor ----------- 
;----------- Separar Centenas -----------   
S_Centenas2:
    clrf    Centenas_2		
    clrf    Decenas_2		
    clrf    Unidades_2		;Limpiar variables        
    movf    Pivote2, 0		;Se transfiere el valor de PORTA
    movwf   Contador_B		;Mover a Contador_A
    movlw   100			;100 a W
    subwf   Contador_B, 1	;Restar 100 a Contador_A
    incf    Centenas_2		;Incrementar Centenas
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Centenas_2		;Si no enciende resta una Centena compensando al momento de re evaluar PORTA
    movlw   100			;100 a W
    addwf   Contador_B, 1	;Añadir 100 para compensar el numero negativo
    call    S_Decenas2	        ;Ir a sub rutina de Dececnas   
    return
;----------- Separar Decenas -----------       
S_Decenas2:
    movlw   10			;10 a W
    subwf   Contador_B, 1	;Se resta 10 a Contador_A
    incf    Decenas_2		;Incrementar Decenas
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Decenas_2		;Si no enciende incrementa una Decima para compensar al re evaluar PORTA
    movlw   10			;10 a W
    addwf   Contador_B, 1	;Añadir 10 para compensar numero negativo
    call    S_Unidades2		;Ir a sub rutina de Unidades  
    return
;----------- Separar Unidades -----------       
S_Unidades2:
    movlw   1			;1 a W
    subwf   Contador_B, 1	;Se resta 1 a Contador_A
    incf    Unidades_2		;Incrementar Unidades
    btfsc   STATUS, 0		;Verificar bandera BORROW, Si obtiene valor positivo se mantiene en 1 de lo contrario es negativo
    goto    $-4			;Si esta encendida regresa a restar
    decf    Unidades_2		;Si no enciende incrementa una Unidad para compensar al re evaluar PORTA
    movlw   1			;1 a W
    addwf   Contador_B, 1	;Incrementar 1 para compensar negativo en este caso da 0
    return
END    