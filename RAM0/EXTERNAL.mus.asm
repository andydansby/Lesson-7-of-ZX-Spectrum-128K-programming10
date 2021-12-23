
; Tabla de instrumentos
TABLA_PAUTAS: defw PAUTA_0

; Tabla de efectos
TABLA_SONIDOS: defw SONIDO0,SONIDO1,SONIDO2,SONIDO3

;Pautas (instrumentos)
;Instrumento 'Piano'
PAUTA_0:	defb	8,0,7,0,6,0,5,0,129

;Efectos
;Efecto 'bass drum'
SONIDO0:	defb	0,58,0,162,90,0,93,138,0,255
;Efecto 'drum'
SONIDO1:	defb	16,88,0,15,88,7,15,104,132,47,3,11,16,88,132,36,8,15,255
;Efecto 'hithat'
SONIDO2:	defb	0,9,1,0,9,2,255
;Efecto 'bass drum vol 2'
SONIDO3:	defb	186,58,0,0,102,0,162,131,0,255

;Efectos

;Frecuencias para las notas
DATOS_NOTAS: defw 0,0
defw 1711,1614,1524,1438,1358,1281,1210,1142,1078,1017
defw 960,906,855,807,762,719,679,641,605,571
defw 539,509,480,453,428,404,381,360,339,320
defw 302,285,269,254,240,227,214,202,190,180
defw 170,160,151,143,135,127,120,113,107,101
defw 95,90,85,80,76,71,67,64,60,57
