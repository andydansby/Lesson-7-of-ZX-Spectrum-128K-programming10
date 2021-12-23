; Initialise playing an effect
; Entry: a = channel
;        b = effect to play
;asm_wyz_start_effect:
PUBLIC _INICIA_EFECTO
_INICIA_EFECTO:
    ld      (CANAL_EFECTOS),a
    ld      a,b
    LD      HL,(TABLA_EFECTOS)
    CALL    EXT_WORD
    LD      (PUNTERO_EFECTO),HL
    LD      HL,INTERR
    SET     3,(HL)
RET

REPRODUCE_EFECTO:
    LD      HL,INTERR
    BIT     3,(HL)                  ;IS THE EFFECT ON?
    RET     Z
    LD      HL,(PUNTERO_EFECTO)
    LD      A,(HL)
    CP      $FF
    JP      Z,_FIN_EFECTO
    LD      B,A                     ;FRECUENCIA FINO
    INC     HL
    LD      A,(HL)
    RRCA
    RRCA
    RRCA
    RRCA
    AND     00001111B
    LD      C,A                 ;FRECUENCIA GRAVE
    LD      A,(HL)
; -- start of PoPe section with noise treatment
; If volume is 0, it might pass to F, max volume!
;
;            DEC     A                   ;DEC A TO LOWER VOLUME !!
;

	AND     00001111B

    LD   D,A                    ;VOLUME
    INC     HL                  ;INCREASE AND SAVE THE POINTER

;
; noise channel management
;
	ld a,(hl)
	inc hl
	ld e,$ff	;The mask that we will use with the mixer in principle does not touch anything on the mixer (it would leave the channels as is)
	and a
	jr z,nonoise	;if the value is 0 there is no noise (I do not touch any of the channels)

	and %00011111	;if there is noise we pass the mask to leave it in 5 bits
	ld (PSG_REG_SEC+6),a	;we put it in the buffer for the corresponding record of ay
	ld e,%11011111	;we mark channel C for noise as the default channel

nonoise:

    LD      (PUNTERO_EFECTO),HL
    LD      IX,PSG_REG_SEC
    LD      A,(CANAL_EFECTOS)       ;CHANNEL SELECTION *********
    CP      1
    JR      Z,RS_CANALA
    CP      2
    JR      Z,RS_CANALB
RS_CANALC:
    LD      (IX+4),B
    LD      (IX+5),C
    LD      (IX+10),D
poneruidomixer:		;this point is common to all 3 channels
    ld a,e	;we load the mask for the mixer
    and (ix+7)	;we apply it from the ay records buffer
    ld (ix+7),a	;we leave the result in the ay register buffer
    RET

RS_CANALA:
    LD      (IX+0),B
    LD      (IX+1),C
    LD      (IX+8),D
    rrc e	;to correctly position the mask for channel A on the mixer, we move the noise bit two positions to the right
    rrc e
    jr poneruidomixer

RS_CANALB:
    LD      (IX+2),B
    LD      (IX+3),C
    LD      (IX+9),D
    rrc e	;to correctly position the mask for channel B on the mixer, we move the noise bit one position to the right
    jr poneruidomixer

;asm_wyz_stop_effect:
PUBLIC _FIN_EFECTO
_FIN_EFECTO:
    LD      HL,INTERR
    RES     3,(HL)                  ;DESACTIVA EFECTO
RET


;effects table
TABLA_EFECTOS:	defw	0

