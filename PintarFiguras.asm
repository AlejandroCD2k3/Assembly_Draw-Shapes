# ------------ MACROS PROVISIONALES ------------

# --- Macro imprimirCadena ---

.macro imprimirCadena (%str)
	la a0, %str # Direccion de la cadena
	li a7, PRINT_STRING # Imprimir la cadena
	ecall
.end_macro

# --- Macro pedirEntero ---

.macro pedirEntero
	la a0, cadenaDecision
	li a1, MAX_INT
	li a7, READ_INT
	ecall
	mv t0, a0
.end_macro


# ------------ SERVICIOS DEL SISTEMA OPERATIVO ------------

# --- Constantes globales ---

.eqv	resolucionHorizontal 	1024
.eqv	resolucionVertical 	512
.eqv 	DISPLAY			0x10040000  # Posicion de memoria donde inicia la visualizacion bitmap

.eqv EXIT 10
.eqv PRINT_INT 1
.eqv PRINT_STRING 4
.eqv READ_INT 5
.eqv READ_STRING 8

.eqv MAX_INT 32


# --- Segmento de datos ---

.data

	stringDecisionUsuario: .asciz "¿Qué desea hacer? \n\n"
	stringDecisionPintarLinea: .asciz "Pintar linea: 1 \n"
	stringDecisionPintarCirculo: .asciz "Pintar círculo: 2 \n"
	stringDecisionSalirPrograma: .asciz "Salir: 3 \n"
	stringEleccionRadio: .asciz "Elija el radio de su círculo: \n"
	stringElegirCoordx0: .asciz "Elija la coordenada x0: \n"
	stringElegirCoordx1: .asciz "Elija la coordenada x1: \n"
	stringElegirCoordy0: .asciz "Elija la coordenada y0: \n"
	stringElegirCoordy1: .asciz "Elija la coordenada y1: \n"
	stringElegirCentroX: .asciz "Elija la coordenada x para el centro del círculo: \n"
	stringElegirCentroY: .asciz "Elija la coordenada y para el centro del círculo: \n"
	cadenaDecision: .space MAX_INT
	
	# Coordenadas del pixel a dibujar
	
	x: .byte 3
	y: .byte 4
	
	# Coordenadas para el círculo
	
	xc: .word 512	# Punto central del círculo en x
	yc: .word 194	# Punto central del círculo en y
	r: .word 60	# Radio del círculo
	
	# Color de los pixeles
	
	px_rgb:	.word	0x0000ff00	# Color amarillo

# --- Segmento de texto ---

.text

bucleEjecucionDePrograma:

	li s0, resolucionHorizontal
	li s1, resolucionVertical
	li s2, DISPLAY

	imprimirCadena(stringDecisionUsuario)
	imprimirCadena(stringDecisionPintarLinea)
	imprimirCadena(stringDecisionPintarCirculo)
	imprimirCadena(stringDecisionSalirPrograma)
	
	pedirEntero
	
	li t1, 1
	li t2, 2
	li t3, 3
	
	beq t0, t1, pintarLinea
	beq t0, t2, pintarCirculo
	beq t0, t3, terminarEjecucion
	
	b bucleEjecucionDePrograma


# Subrutina para pintar un pixel 
pintarPixel:
    # a0 = x; a1 = y; a2 = color
    mul t0, s0, a1  # t0 = RES_H * y
    add t0, t0, a0  # t0 += x
    slli t0, t0, 2  # 4 bytes por pixel
    add t0, t0, s2  # Display base address
    sw a2, 0(t0)    # Color
    ret

# Subrutina para pintar líneas
pintarLinea:
    imprimirCadena(stringElegirCoordx0)
    pedirEntero
    mv t1, t0 # x0
    imprimirCadena(stringElegirCoordx1)
    pedirEntero
    mv t2, t0 # x1
    imprimirCadena(stringElegirCoordy0)
    pedirEntero
    mv t3, t0 # y0
    imprimirCadena(stringElegirCoordy1)
    pedirEntero
    mv t4, t0 # y1

    sub a3, t2, t1 # dx
    sub a4, t4, t3 # dy

    # Encontrar pendiente
    jal ra, analizarDiferenciaY
    jal ra, analizarDiferenciaX

    mv a1, t3
    mv a0, t1

    # Inicializar parámetros
    la t0, px_rgb       # Cargar la dirección de r en t2
    lw a2, 0(t0)        # Cargar el valor de r en a2

    jal ra, pintarPixel

    blt a4, a3, diferenciaDeYMenor
    b diferenciaDeXMenor

diferenciaDeYMenor: # dx > dy
    li t0, 2
    mul a5, a4, t0 # incE

    sub a6, a4, a3
    mul a6, a6, t0 # incNE

    sub a7, a5, a3 # p

cicloPintarLineaYMenor:
    bltz a7, pMenorQue0x
    b pMayorQue0x

pMenorQue0x:
    add a7, a7, a5 # p = p + incE
    b pintarRecorridox
pMayorQue0x:
    add t3, t3, t5 # y = y + stepY
    add a7, a7, a6 # p = p + incNE

pintarRecorridox:
    add a0, t1, zero
    add a1, t3, zero
    jal ra, pintarPixel

    beq t1, t2, finPintarLinea
    add t1, t1, t6 # x = x + stepX
    b cicloPintarLineaYMenor

diferenciaDeXMenor: # dx < dy
    li t0, 2
    mul a5, a3, t0 # incE

    sub a6, a3, a4
    mul a6, a6, t0 # incNE

    sub a7, a5, a4 # p

cicloPintarLineaXMenor:
    bltz a7, pMenorQue0y
    b pMayorQue0y

pMenorQue0y:
    add a7, a7, a5 # p = p + incE
    b pintarRecorridoy
pMayorQue0y:
    add t1, t1, t6 # x = x + stepX
    add a7, a7, a6 # p = p + incNE

pintarRecorridoy:
    add a0, t1, zero
    add a1, t3, zero
    jal ra, pintarPixel

    beq t3, t4, finPintarLinea
    add t3, t3, t5 # y = y + stepY
    b cicloPintarLineaXMenor

analizarDiferenciaY:
    bltz a4, YDecreciente
    li t5, 1 # stepY
    ret
YDecreciente:
    li t0, -1
    mv t5, t0 # stepY
    mul a4, a4, t0
    ret

analizarDiferenciaX:
    bltz a3, XDecreciente
    li t6, 1 # stepX
    ret
XDecreciente:
    li t0, -1
    mv t6, t0 # stepX
    mul a3, a3, t0
    ret

finPintarLinea:
    # Regresar al bucle principal o al sistema operativo
    jal ra, bucleEjecucionDePrograma


# Subrutina para pintar circulos
pintarCirculo:

	
	
	# Inicializar parámetros
	imprimirCadena(stringElegirCentroX)
	pedirEntero
    	mv a3, t0   # Cargar el valor de xc en a0
    	imprimirCadena(stringElegirCentroY)
    	pedirEntero
    	mv a4, t0   # Cargar el valor de yc en a1
    	
    	la t2, px_rgb       # Cargar la dirección de r en t2
    	lw a2, 0(t2)   # Cargar el valor de r en a2
    	
    	# Pedir valor del radio
    	
    	imprimirCadena(stringEleccionRadio)
    	pedirEntero
    	mv a7, t0

	mv t5, ra
	# a3 = Xc; a4 = Yc; a7 = radio
	li a5, 0 	# X
	mv a6, a7	# Y
	li t0, 1
	sub s4, t0, a7 	# p
	jal pintarSimetria
	
	# Ciclo
cicloWhileCirculo:
	addi a5, a5, 1
	
	li t2, 0
	blt s4, t2, ifCirculo
	li t0, 1
	sub a6, a6, t0
	li s6, 666
	
	# p = p + 2(x - y) + 5
	sub t1, a5, a6
	add t1, t1, t1
	addi t1, t1, 5
	add s4, s4, t1
	
	jal pintarSimetria	
	blt a5, a6, cicloWhileCirculo
	mv ra, t5
	b bucleEjecucionDePrograma
	
ifCirculo:
	# p = p + 2x + 3
	add t1, a5, a5
	addi t1, t1, 3
	add s4, s4, t1
	
	jal pintarSimetria
	blt a5, a6, cicloWhileCirculo
	mv ra, t5
	ret
	
# Pintar simetrica para dibujar circulos
pintarSimetria:
	mv t6, ra
	# a3 = xc; a4 = yc; a5 = x; a6 = y;  
	# Llevar a 0
	li a0, 0
	li a1, 0
	
	add a0, a3, a5
	add a1, a4, a6
	jal pintarPixel
	
	sub a0, a3, a5
	add a1, a4, a6
	jal pintarPixel
	
	add a0, a3, a5
	sub a1, a4, a6
	jal pintarPixel
	
	sub a0, a3, a5
	sub a1, a4, a6
	jal pintarPixel
	
	add a0, a3, a6
	add a1, a4, a5
	jal pintarPixel
	
	sub a0, a3, a6
	add a1, a4, a5
	jal pintarPixel
	
	add a0, a3, a6
	sub a1, a4, a5
	jal pintarPixel
	
	sub a0, a3, a6
	sub a1, a4, a5
	jal pintarPixel
	mv ra, t6
	ret
	
# Subrutina para terminar ejecución

terminarEjecucion:
	
	li a7, 10
	ecall
