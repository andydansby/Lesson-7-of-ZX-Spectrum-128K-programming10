
; ZX PSG proPLAYER V 0.3 - WYZ 19.03.2016
; ASSEMBLE WITH AsMSX

; THE DATA TO CHANGE :
; * SOUND BUFFER WHERE THE MUS FILE IS FULLY DECODED
; * # SONG.
; * SONG TABLE

; breakpoints to look for
; PLAYER_INIT_start		$8AA9
; calls PLAYER_INIT		$C52D

; INIT_BUFFERS_start	$8AAC
; calls INIT_BUFFERS	$C545

; PLAYER_OFF_start		$8AAF
; calls PLAYER_OFF		$C143

; WYZ_LOAD_SONG_start	$8AB2
; calls WYZ_LOAD_SONG	$C016

; check_interrupts		$8C36
; calls enable_interupts	$8971

; inside_loop			$8C39


; look at _INICIO		$C020

;______________________________________________________

PUBLIC _WYZ_SONG_Number
_WYZ_SONG_Number:        defb     0

;---------------------------------------------------
PUBLIC _WYZ_LOAD_SONG
_WYZ_LOAD_SONG:
	ld a, L
	CALL UNCOMP_SONG		; Uncompress song
	LD A,0
	CALL _CARGA_CANCION
ret
;---------------------------------------------------

PUBLIC _INICIO       ;asm_wyz_play
_INICIO:
    CALL ROUT

    LD HL,PSG_REG
    LD DE,PSG_REG_SEC
    LD BC,14
    LDIR
    CALL REPRODUCE_SONIDO
    CALL PLAY

    ; CALL REPRODUCE_EFECTO
RET

;--------- PLAY -----------
PLAY:
	LD HL,INTERR       ;PLAY BIT 1 ON?
	BIT 1,(HL)
	RET Z
;TEMPO
	LD HL,TTEMPO       ;TEMPO METER
	INC (HL)
	LD A,(TEMPO)
	CP (HL)
	JR NZ,PAUTAS
	LD (HL),0

;interpreter
	LD IY,PSG_REG
	LD IX,PUNTERO_A
	LD BC,PSG_REG+8
	CALL LOCALIZA_NOTA
	LD IY,PSG_REG+2
	LD IX,PUNTERO_B
	LD BC,PSG_REG+9
	CALL LOCALIZA_NOTA
	LD IY,PSG_REG+4
	LD IX,PUNTERO_C
	LD BC,PSG_REG+10
	CALL LOCALIZA_NOTA
	LD IX,PUNTERO_P    ;THE EFFECT CHANNEL MASKS ANOTHER CHANNEL
	CALL LOCALIZA_EFECTO

;PAUTAS

PAUTAS:
	LD IY,PSG_REG+0
	LD IX,PUNTERO_P_A
	LD HL,PSG_REG+8
	CALL PAUTA           ;PAUTA CANAL A
	LD IY,PSG_REG+2
	LD IX,PUNTERO_P_B
	LD HL,PSG_REG+9
	CALL PAUTA           ;PAUTA CANAL B
	LD IY,PSG_REG+4
	LD IX,PUNTERO_P_C
	LD HL,PSG_REG+10
	CALL PAUTA           ;PAUTA CANAL C
RET

; GUIDELINE OF THE 3 CHANNELS
; IN:(IX):GUIDELINE POINTER
;    (HL):VOLUME RECORD
;    (IY):FREQUENCY REGISTERS

; GUIDELINE FORMAT
;	    7    6     5     4   3-0                        3-0
; BYTE 1 (LOOP|OCT-1|OCT+1|ORNMT|VOL) - BYTE 2 ( | | | |PITCH/NOTA)

PAUTA:
	BIT 4,(HL)        ;IF THE ENVELOPE IS ACTIVATED, IT DOES NOT WORK GUIDELINES
	RET NZ

	LD A,(IY+0)
	LD B,(IY+1)
	OR B
	RET	Z


	PUSH HL

PCAJP4:
	LD L,(IX+0)
	LD H,(IX+1)
	LD A,(HL)

	BIT 7,A		;LOOP / EL RESTO DE BITS NO AFECTAN
	JR Z,PCAJP0
	AND $1F	;00011111B       ;MÁXIMO LOOP PAUTA (0,32)X2!!!-> PARA ORNAMENTOS
	RLCA			;X2
	LD D,0
	LD E,A
	SBC HL,DE
	LD A,(HL)

PCAJP0:
	BIT 6,A		;OCTAVA -1
	JR Z,PCAJP1
	LD E,(IY+0)
	LD D,(IY+1)

	AND A
	RRC D
	RR E
	LD (IY+0),E
	LD (IY+1),D
	JR PCAJP2

PCAJP1:
	BIT 5,A		;OCTAVA +1
	JR Z,PCAJP2
	LD E,(IY+0)
	LD D,(IY+1)

	AND A
	RLC E
	RL D
	LD (IY+0),E
	LD (IY+1),D

PCAJP2:
	LD A,(HL)
	BIT	4,A
	JR NZ,PCAJP6	;ORNAMENTOS SELECCIONADOS

	INC HL		;______________________ FUNCION PITCH DE FRECUENCIA__________________
	PUSH HL
	LD E,A
	LD A,(HL)		;PITCH DE FRECUENCIA
	LD L,A
	AND	A
	LD A,E
	JR Z,ORNMJP1

	LD	A,(IY+0)	;SI LA FRECUENCIA ES 0 NO HAY PITCH
	ADD	A,(IY+1)
	AND	A
	LD	A,E
	JR	Z,ORNMJP1


	BIT	7,L
	JR	Z,ORNNEG
	LD	H,$FF
	JR	PCAJP3

ORNNEG:
	LD H,0

PCAJP3:
	LD E,(IY+0)
	LD D,(IY+1)
	ADC	HL,DE
	LD (IY+0),L
	LD (IY+1),H
	JR ORNMJP1


PCAJP6:
	INC	HL		;______________________ FUNCION ORNAMENTOS__________________

	PUSH HL
	PUSH AF
	LD A,(IX+REG_NOTA_A-PUNTERO_P_A)	;RECUPERA REGISTRO DE NOTA EN EL CANAL
	LD E,(HL)		;
	ADC	E		;+- NOTA
	CALL TABLA_NOTAS
	POP	AF


ORNMJP1:
	POP HL

	INC HL
	LD (IX+0),L
	LD (IX+1),H
PCAJP5:
	POP	HL
	LD B,(IX+VOL_INST_A-PUNTERO_P_A)	;VOLUMEN RELATIVO
	ADD	B
	JP P,PCAJP7
	LD A,1		;NO SE EXTIGUE EL VOLUMEN

PCAJP7:
	AND	$F	;00001111B	;VOLUMEN FINAL MODULADO
	LD (HL),A
RET

;PLAYER OFF
PUBLIC _PLAYER_OFF
_PLAYER_OFF:
    XOR	A			;***** IMPORTANT IF THERE IS NO MUSIC ****
    LD (INTERR),A
    ;LD	(FADE),A		;only if there is fade out

CLEAR_PSG_BUFFER:
    LD HL,PSG_REG
    LD DE,PSG_REG+1
    LD BC,14
    LD (HL),A
    LDIR

    LD A, $B8	;10111000B		; **** JUST IN CASE ****
    LD (PSG_REG+7),A

    LD HL,PSG_REG
    LD DE,PSG_REG_SEC
    LD BC,14
    LDIR

    CALL ROUT
RET

;RETURNS SOUND BUFFER TO PSG
ROUT:
    LD A,(PSG_REG+13)
    AND	A			    ;IS IT ZERO?
    JR Z,NO_BACKUP_ENVOLVENTE
    LD (ENVOLVENTE_BACK),A	;08.13 / SAVE THE ENVELOPE IN THE BACKUP


NO_BACKUP_ENVOLVENTE:
	;DUMPS SOUND BUFFER TO PSG OF THE SPECTRUM
    XOR A

ROUT_A0:
    LD DE,$FFBF
    LD BC,$FFFD
    LD HL,PSG_REG_SEC

LOUT:
    OUT (C),A
    LD B,E
    OUTI
    LD B,D
    INC A
    CP 13
    JR NZ,LOUT
    OUT (C),A
    LD A,(HL)
    AND A
    RET Z
    LD B,E
    OUTI
    XOR A
    LD (PSG_REG_SEC+13),A
    LD	(PSG_REG+13),A
RET

;CARGA UNA CANCION = LOAD A SONG
;IN:(A)= SONG #

PUBLIC _CARGA_CANCION
_CARGA_CANCION:
    LD HL,INTERR       ;LOAD SONG

    SET 1,(HL)          ;REPRODUCE CANCION
    LD HL,SONG
    LD (HL),A          ;# A

;DECODIFICAR
;IN-> INTERR 0 ON
;     SONG

;CARGA CANCION SI/NO

DECODE_SONG:
    LD A,(SONG)

;READ THE HEAD OF THE SONG
;BYTE 0=TEMPO

    LD HL,TABLA_SONG
    CALL EXT_WORD
    LD A,(HL)
    LD (TEMPO),A

    DEC A	;XOR	A

    LD (TTEMPO),A

;HEADER BYTE 1
;(-|-|-|-|  3-1 | 0  )
;(-|-|-|-|FX CHN|LOOP)

    INC HL		;LOOP 1=ON/0=OFF?
    LD A,(HL)
    BIT 0,A
    JR Z,NPTJP0
    PUSH HL
    LD HL,INTERR
    SET 4,(HL)
    POP HL

;SELECTING THE RHYTHM EFFECTS CHANNEL
NPTJP0:
    AND	$6	;00000110B
    RRA
    ;LD	(SELECT_CANAL_P),A

    PUSH HL
    LD HL,TABLA_DATOS_CANAL_SFX
    CALL EXT_WORD
    PUSH HL
    POP IX
    LD E,(IX+0)
    LD D,(IX+1)
    LD (SFX_L),DE

    LD E,(IX+2)
    LD D,(IX+3)
    LD (SFX_H),DE

	LD E,(IX+4)
	LD D,(IX+5)
	LD (SFX_V),DE

	LD A,(IX+6)
	LD (SFX_MIX),A
	POP HL

	INC HL		;2 BYTES RESERVED
	INC	HL
	INC	HL

;SEARCH AND SAVE CHANNELS IN THE MUS MODULE (OPTIMIZE****************)
;AÑADE OFFSET DEL LOOP

	PUSH HL			;IX START OFFSETS LOOP PER CHANNEL
	POP	IX

	LD DE,$0008		;UNTIL THE START OF CHANNEL A
	ADD	HL,DE


	LD (PUNTERO_P_DECA),HL	;START CHANNEL POINTER GUARD
	LD E,(IX+0)
	LD D,(IX+1)
	ADD HL,DE
	LD (PUNTERO_L_DECA),HL	;START POINTER GUARD LOOP

	CALL BGICMODBC1
	LD (PUNTERO_P_DECB),HL
	LD E,(IX+2)
	LD D,(IX+3)
	ADD HL,DE
	LD (PUNTERO_L_DECB),HL

	CALL BGICMODBC1
	LD (PUNTERO_P_DECC),HL
	LD E,(IX+4)
	LD D,(IX+5)
	ADD HL,DE
	LD (PUNTERO_L_DECC),HL

	CALL BGICMODBC1
	LD (PUNTERO_P_DECP),HL
	LD E,(IX+6)
	LD D,(IX+7)
	ADD HL,DE
	LD (PUNTERO_L_DECP),HL


;LEE DATOS DE LAS NOTAS
;(|)(|||||) LONGITUD\NOTA

INIT_DECODER:
	LD DE,(CANAL_A)
	LD (PUNTERO_A),DE
	LD HL,(PUNTERO_P_DECA)
	CALL DECODE_CANAL    	;CANAL A
	LD (PUNTERO_DECA),HL

	LD DE,(CANAL_B)
	LD (PUNTERO_B),DE
	LD HL,(PUNTERO_P_DECB)
	CALL DECODE_CANAL    	;CANAL B
	LD (PUNTERO_DECB),HL

	LD DE,(CANAL_C)
	LD (PUNTERO_C),DE
	LD HL,(PUNTERO_P_DECC)
	CALL DECODE_CANAL    	;CANAL C
	LD (PUNTERO_DECC),HL

	LD DE,(CANAL_P)
	LD (PUNTERO_P),DE
	LD HL,(PUNTERO_P_DECP)
	CALL DECODE_CANAL    	;CANAL P
	LD (PUNTERO_DECP),HL

RET

;BUSCA INICIO DEL CANAL

BGICMODBC1:
	XOR A			;BUSCA EL BYTE 0
	LD E,$3F			;CODIGO INSTRUMENTO 0
	LD B,$FF			;EL MODULO DEBE TENER UNA LONGITUD MENOR DE $FF00 ... o_O!
	CPIR

	DEC HL
	DEC HL
	LD A,E			;ES EL INSTRUMENTO 0??
	CP (HL)
	INC HL
	INC HL
	JR Z,BGICMODBC1

	DEC HL
	DEC HL
	DEC HL
	LD A,E			;ES VOLUMEN 0??
	CP (HL)
	INC HL
	INC HL
	INC HL
	JR Z,BGICMODBC1
RET

;DECODE NOTES FROM A CHANNEL
;IN (DE)=DESTINATION ADDRESS
;NOTA=0 CHANNEL END
;NOTA=1 SILENCE
;NOTA=2 PUNTILLO
;NOTA=3 COMANDO I

DECODE_CANAL:
	LD A,(HL)
	AND A               ;FIN DEL CANAL?
	JR Z,FIN_DEC_CANAL
	CALL GETLEN

	CP 1	;00000001B       ;ES SILENCIO?
	JR NZ,NO_SILENCIO
	SET 6,A
	JR NO_MODIFICA

NO_SILENCIO:
	CP $3E	;00111110B       ;ES PUNTILLO?
	JR NZ,NO_PUNTILLO
	OR A
	RRC B
	XOR A
	JR NO_MODIFICA

NO_PUNTILLO:
	CP $3F;	00111111B       ;ES COMANDO?
	JR NZ,NO_MODIFICA
	BIT 0,B             ;COMADO=INSTRUMENTO?
	JR Z,NO_INSTRUMENTO
	LD A, $C1	;11000001B     ;INSTRUMENT CODE
	LD (DE),A
	INC HL
	INC DE
	LD A,(HL)          ;# of INSTRUMENT
	LD (DE),A
	INC DE
	INC HL
	LD A,(HL)          ;RELATIVE VOLUME OF THE INSTRUMENT
	LD (DE),A
	INC DE
	INC HL
	JR DECODE_CANAL

NO_INSTRUMENTO:
	BIT 2,B
	JR Z,NO_ENVOLVENTE
	LD A, $C4	;11000100B     ;ENVELOPE CODE
	LD (DE),A
	INC DE
	INC HL
	LD A,(HL)
	LD (DE),A
	INC DE
	INC HL
	JR DECODE_CANAL

NO_ENVOLVENTE:
	BIT 1,B
	JR Z,NO_MODIFICA
	LD A, $C2	;11000010B     ;EFFECT CODE
	LD (DE),A
	INC HL
	INC DE
	LD A,(HL)
	CALL GETLEN

NO_MODIFICA:
	LD (DE),A
	INC DE
	XOR A
	DJNZ NO_MODIFICA
	SET 7,A
	SET 0,A
	LD (DE),A
	INC DE
	INC HL
RET			;** JR      DECODE_CANAL

FIN_DEC_CANAL:
	SET 7,A
	LD (DE),A
	INC DE
RET

GETLEN:
	LD B,A
	AND $3F;	00111111B
	PUSH AF
	LD A,B
	AND $C0	;11000000B
	RLCA
	RLCA
	INC A
	LD B,A
	LD A,$80	;10000000B

DCBC0:
	RLCA
	DJNZ DCBC0
	LD B,A
	POP AF
RET

;REPRODUCE SOUND EFFECTS
REPRODUCE_SONIDO:

    LD HL,INTERR
    BIT 2,(HL)          ;THE EFFECT IS ON?
    RET Z
    LD HL,(PUNTERO_SONIDO)
    LD A,(HL)
    CP $FF
    JR Z,FIN_SONIDO
    LD DE,(SFX_L)
    LD (DE),A
    INC HL
    LD A,(HL)
    RRCA
    RRCA
    RRCA
    RRCA
    AND $F	;00001111B
    LD DE,(SFX_H)
    LD (DE),A
    LD A,(HL)
    AND $F	;00001111B
    LD DE,(SFX_V)
    LD (DE),A

    INC HL
    LD A,(HL)
    LD B,A
    BIT 7,A     ;09.08.13 BIT MAS SIGINIFICATIVO ACTIVA ENVOLVENTES
    JR Z,NO_ENVOLVENTES_SONIDO
    LD A,$12
    LD (DE),A
    INC HL
    LD A,(HL)
    LD (PSG_REG_SEC+11),A
    INC HL
    LD A,(HL)
    LD (PSG_REG_SEC+12),A
    INC HL
    LD A,(HL)
    CP 1
    JR Z,NO_ENVOLVENTES_SONIDO		;NO ESCRIBE LA ENVOLVENTE SI SU VALOR ES 1
    LD (PSG_REG_SEC+13),A


NO_ENVOLVENTES_SONIDO:

    LD A,B
    RES	7,A
    AND A
    JR Z,NO_RUIDO
    LD (PSG_REG_SEC+6),A
    LD A,(SFX_MIX)
    JR SI_RUIDO

NO_RUIDO:
    XOR	A
    LD (PSG_REG_SEC+6),A
    LD A, $B8	;10111000B

SI_RUIDO:
    LD (PSG_REG_SEC+7),A

    INC HL
    LD (PUNTERO_SONIDO),HL
RET


FIN_SONIDO:
    LD HL,INTERR
    RES 2,(HL)
    LD A,(ENVOLVENTE_BACK)		;NO RESTAURA LA ENVOLVENTE SI ES 0
    AND	A
    JR Z,FIN_NOPLAYER
    ;xor a ; ***
    LD (PSG_REG_SEC+13),A			;08.13 RESTAURA LA ENVOLVENTE TRAS EL SFX

FIN_NOPLAYER:
    LD A, $B8	;10111000B
    LD (PSG_REG_SEC+7),A
RET

;LOCALIZA NOTA CANAL A
;IN (PUNTERO_A)

;LOCALIZA NOTA CANAL A
;IN (PUNTERO_A)

LOCALIZA_NOTA:
	LD L,(IX+PUNTERO_A-PUNTERO_A)	;HL=(PUNTERO_A_C_B)
	LD H,(IX+PUNTERO_A-PUNTERO_A+1)
	LD A,(HL)
	AND $C0	;11000000B      			;COMANDO?
	CP $C0	;11000000B
	JR NZ,LNJP0

;BIT(0)=INSTRUMENTO

COMANDOS:
	LD A,(HL)
	BIT 0,A             		;INSTRUMENTO
	JR Z,COM_EFECTO

	INC HL
	LD A,(HL)          		;Nº DE PAUTA
	INC HL
	LD E,(HL)

	PUSH HL				;;TEMPO ******************
	LD HL,TEMPO
	BIT 5,E
	JR Z,NO_DEC_TEMPO
	DEC	(HL)

NO_DEC_TEMPO:
	BIT 6,E
	JR Z,NO_INC_TEMPO
	INC (HL)

NO_INC_TEMPO:
	RES 5,E				;SIEMPRE RESETEA LOS BITS DE TEMPO
	RES 6,E
	POP HL

	LD (IX+VOL_INST_A-PUNTERO_A),E	;REGISTRO DEL VOLUMEN RELATIVO
	INC HL
	LD (IX+PUNTERO_A-PUNTERO_A),L
	LD (IX+PUNTERO_A-PUNTERO_A+1),H
	LD HL,TABLA_PAUTAS
	CALL EXT_WORD
	LD (IX+PUNTERO_P_A0-PUNTERO_A),L
	LD (IX+PUNTERO_P_A0-PUNTERO_A+1),H
	LD (IX+PUNTERO_P_A-PUNTERO_A),L
	LD (IX+PUNTERO_P_A-PUNTERO_A+1),H
	LD L,C
	LD H,B
	RES 4,(HL)        			;APAGA EFECTO ENVOLVENTE
	XOR A
	LD (PSG_REG_SEC+13),A
	LD (PSG_REG+13),A
	;LD	(ENVOLVENTE_BACK),A		;08.13 / RESETEA EL BACKUP DE LA ENVOLVENTE
	JR LOCALIZA_NOTA

COM_EFECTO:
	BIT 1,A             		;EFECTO DE SONIDO
	JR Z,COM_ENVOLVENTE

	INC HL
	LD A,(HL)
	INC HL
	LD (IX+PUNTERO_A-PUNTERO_A),L
	LD (IX+PUNTERO_A-PUNTERO_A+1),H
	CALL INICIA_SONIDO
RET

COM_ENVOLVENTE:
	BIT 2,A
	RET Z               		;IGNORA - ERROR

	INC HL
	LD A,(HL)			;CARGA CODIGO DE ENVOLVENTE
	LD (ENVOLVENTE),A
	INC HL
	LD (IX+PUNTERO_A-PUNTERO_A),L
	LD (IX+PUNTERO_A-PUNTERO_A+1),H
	LD L,C
	LD H,B
	LD (HL), $10	;00010000B          	;ENCIENDE EFECTO ENVOLVENTE
	JR LOCALIZA_NOTA


LNJP0:
	LD A,(HL)
	INC HL
	BIT 7,A
	JR Z,NO_FIN_CANAL_A	;
	BIT 0,A
	JR Z,FIN_CANAL_A

FIN_NOTA_A:
	LD E,(IX+CANAL_A-PUNTERO_A)
	LD D,(IX+CANAL_A-PUNTERO_A+1)	;PUNTERO BUFFER AL INICIO
	LD (IX+PUNTERO_A-PUNTERO_A),E
	LD (IX+PUNTERO_A-PUNTERO_A+1),D
	LD L,(IX+PUNTERO_DECA-PUNTERO_A)	;CARGA PUNTERO DECODER
	LD H,(IX+PUNTERO_DECA-PUNTERO_A+1)
	PUSH BC

	CALL DECODE_CANAL    		;DECODIFICA CANAL
	POP BC
	LD (IX+PUNTERO_DECA-PUNTERO_A),L	;GUARDA PUNTERO DECODER
	LD (IX+PUNTERO_DECA-PUNTERO_A+1),H
	JP LOCALIZA_NOTA

FIN_CANAL_A:
	LD HL,INTERR			;LOOP?
	BIT 4,(HL)
	JR NZ,FCA_CONT
	POP AF
	JP _PLAYER_OFF


FCA_CONT:
	LD L,(IX+PUNTERO_L_DECA-PUNTERO_A)	;CARGA PUNTERO INICIAL DECODER
	LD H,(IX+PUNTERO_L_DECA-PUNTERO_A+1)
	LD (IX+PUNTERO_DECA-PUNTERO_A),L
	LD (IX+PUNTERO_DECA-PUNTERO_A+1),H
	JR FIN_NOTA_A

NO_FIN_CANAL_A:
	LD (IX+PUNTERO_A-PUNTERO_A),L        	;(PUNTERO_A_B_C)=HL GUARDA PUNTERO
	LD (IX+PUNTERO_A-PUNTERO_A+1),H
	AND A               		;NO REPRODUCE NOTA SI NOTA=0
	JR Z,FIN_RUTINA
	BIT 6,A             		;SILENCIO?
	JR Z,NO_SILENCIO_A
	LD A,(BC)
	AND	$10	;00010000B
	JR NZ,SILENCIO_ENVOLVENTE

	XOR A
	LD (BC),A				;RESET VOLUMEN DEL CORRESPODIENTE CHIP
	LD (IY+0),A
	LD (IY+1),A
RET

SILENCIO_ENVOLVENTE:
	LD A,$FF
	LD (PSG_REG+11),A
	LD (PSG_REG+12),A
	XOR A
	LD (PSG_REG+13),A
	LD (IY+0),A
	LD (IY+1),A
RET

NO_SILENCIO_A:
	LD (IX+REG_NOTA_A-PUNTERO_A),A	;REGISTRO DE LA NOTA DEL CANAL
	CALL NOTA            		;REPRODUCE NOTA
	LD L,(IX+PUNTERO_P_A0-PUNTERO_A)     ;HL=(PUNTERO_P_A0) RESETEA PAUTA
	LD H,(IX+PUNTERO_P_A0-PUNTERO_A+1)
	LD (IX+PUNTERO_P_A-PUNTERO_A),L       ;(PUNTERO_P_A)=HL
	LD (IX+PUNTERO_P_A-PUNTERO_A+1),H

FIN_RUTINA:
RET

;LOCALIZA EFECTO
;IN HL=(PUNTERO_P)

LOCALIZA_EFECTO:
	LD L,(IX+0)       ;HL=(PUNTERO_P)
	LD H,(IX+1)
	LD A,(HL)
	CP $C2	;11000010B
	JR NZ,LEJP0

	INC HL
	LD A,(HL)
	INC HL
	LD (IX+00),L
	LD (IX+01),H
	CALL INICIA_SONIDO
RET


;START THE SOUND # (A)
INICIA_SONIDO:
    ;CP	8		;SFX SPEECH
    ;JP	Z,SLOOP		;

    LD HL,TABLA_SONIDOS
    CALL EXT_WORD
    LD (PUNTERO_SONIDO),HL
    LD HL,INTERR
    SET 2,(HL)
RET


LEJP0:
	INC HL
	BIT 7,A
	JR Z,NO_FIN_CANAL_P	;
	BIT 0,A
	JR Z,FIN_CANAL_P


FIN_NOTA_P:
	LD DE,(CANAL_P)
	LD (IX+0),E
	LD (IX+1),D
	LD HL,(PUNTERO_DECP)	;CARGA PUNTERO DECODER
	PUSH BC
	CALL DECODE_CANAL    	;DECODIFICA CANAL
	POP BC
	LD (PUNTERO_DECP),HL	;GUARDA PUNTERO DECODER
	JP LOCALIZA_EFECTO

FIN_CANAL_P:
	LD HL,(PUNTERO_L_DECP)	;CARGA PUNTERO INICIAL DECODER
	LD (PUNTERO_DECP),HL
	JR FIN_NOTA_P

NO_FIN_CANAL_P:
	LD (IX+0),L        ;(PUNTERO_A_B_C)=HL GUARDA PUNTERO
	LD (IX+1),H
RET


;NOTA : REPRODUCE UNA NOTA
;IN (A)=CODIGO DE LA NOTA
;   (IY)=REGISTROS DE FRECUENCIA
NOTA:
	LD L,C
	LD H,B
	BIT 4,(HL)
	LD B,A
	JR NZ,EVOLVENTES
	LD A,B

TABLA_NOTAS:
	LD HL,DATOS_NOTAS		;BUSCA FRECUENCIA
	CALL EXT_WORD
	LD (IY+0),L
	LD (IY+1),H
RET


;IN (A)=CODIGO DE LA ENVOLVENTE
;   (IY)=REGISTRO DE FRECUENCIA

EVOLVENTES:
	LD HL,DATOS_NOTAS
	;SUB 12
	RLCA                    ;X2
	LD D,0
	LD E,A
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)

	PUSH DE
	LD A,(ENVOLVENTE)		;FRECUENCIA DEL CANAL ON/OFF
	RRA
	JR NC,FRECUENCIA_OFF
	LD (IY+0),E
	LD (IY+1),D
	JR CONT_ENV

FRECUENCIA_OFF:
	LD DE,$0000
	LD (IY+0),E
	LD (IY+1),D
	;CALCULO DEL RATIO (OCTAVA ARRIBA)

CONT_ENV:
	POP DE
	PUSH AF
	PUSH BC
	AND $3	;00000011B
	LD B,A
	;INC B

	;AND A			;1/2
	RR D
	RR E

CRTBC0:
	;AND A			;1/4 - 1/8 - 1/16
	RR D
	RR E
	DJNZ CRTBC0
	LD A,E
	LD (PSG_REG+11),A
	LD A,D
	AND $3	;00000011B
	LD (PSG_REG+12),A
	POP BC
	POP AF			;SELECCION FORMA DE ENVOLVENTE

	RRA
	AND $6	;00000110B		;$08,$0A,$0C,$0E
	ADD 8
	LD (PSG_REG+13),A
	LD (ENVOLVENTE_BACK),A
RET


PUBLIC _PLAYER_INIT
_PLAYER_INIT:
    LD HL,BUFFER_CANAL_A       ;RESERVAR MEMORIA PARA BUFFER DE SONIDO!!!!!
    LD (CANAL_A),HL            ;RECOMENDABLE $10 O MAS BYTES POR CANAL.

    LD HL,BUFFER_CANAL_B
    LD (CANAL_B),HL

    LD HL,BUFFER_CANAL_C
    LD (CANAL_C),HL

    LD HL,BUFFER_CANAL_P
    LD (CANAL_P),HL



PUBLIC _INIT_BUFFERS
_INIT_BUFFERS:
	ld HL,BUFFER_DEC	;* $40 BYTES FREE RAM MEMORY
	ld (CANAL_A),HL		;* $10 BYTES x CHANNEL SHOULD BE ENOUGH

	ld HL,BUFFER_DEC+$10
	ld (CANAL_B),HL

	ld HL,BUFFER_DEC+$20
	ld (CANAL_C),HL

	ld HL,BUFFER_DEC+$30
	ld (CANAL_P),HL
ret




;EXTRACT A WORD FROM A TABLE
;IN:(HL)=ADDRESS TABLE
;   (A)= POSITION
;OUT(HL)=WORD

EXT_WORD:
    LD D,0
	RLCA
	LD E,A
	ADD HL,DE
	LD E,(HL)
	INC HL
	LD D,(HL)
	EX DE,HL
RET


; ZX0 Parameters:
; HL: source address (compressed data)
; DE: destination address (decompressing)
;
;extern _dzx0_turbo
UNCOMP_SONG:
	ld hl, TABLA_SONG_CMP
	call EXT_WORD
	ld de, BUFFER_UNCOMP
	call dzx0_standard
ret




; -----------------------------------------------------------------------------
; ZX0 decoder by Einar Saukas & Urusergi
; "Standard" version (68 bytes only)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------

dzx0_standard:
        ld      bc, $ffff               ; preserve default offset 1
        push    bc
        inc     bc
        ld      a, $80
dzx0s_literals:
        call    dzx0s_elias             ; obtain length
        ldir                            ; copy literals
        add     a, a                    ; copy from last offset or new offset?
        jr      c, dzx0s_new_offset
        call    dzx0s_elias             ; obtain length
dzx0s_copy:
        ex      (sp), hl                ; preserve source, restore offset
        push    hl                      ; preserve offset
        add     hl, de                  ; calculate destination - offset
        ldir                            ; copy from offset
        pop     hl                      ; restore offset
        ex      (sp), hl                ; preserve offset, restore source
        add     a, a                    ; copy from literals or new offset?
        jr      nc, dzx0s_literals
dzx0s_new_offset:
        pop     bc                      ; discard last offset
        ld      c, $fe                  ; prepare negative offset
        call    dzx0s_elias_loop        ; obtain offset MSB
        inc     c
        ret     z                       ; check end marker
        ld      b, c
        ld      c, (hl)                 ; obtain offset LSB
        inc     hl
        rr      b                       ; last offset bit becomes first length bit
        rr      c
        push    bc                      ; preserve new offset
        ld      bc, 1                   ; obtain length
        call    nc, dzx0s_elias_backtrack
        inc     bc
        jr      dzx0s_copy
dzx0s_elias:
        inc     c                       ; interlaced Elias gamma coding
dzx0s_elias_loop:
        add     a, a
        jr      nz, dzx0s_elias_skip
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        rla
dzx0s_elias_skip:
        ret     c
dzx0s_elias_backtrack:
        add     a, a
        rl      c
        rl      b
        jr      dzx0s_elias_loop
; -----------------------------------------------------------------------------
