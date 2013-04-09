;реализация общеупотребительного функционала, функции типа writeln и макросы

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Макросы
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;вызов функции fun с аргументом arg
run macro fun, arg
	push BX
		push arg
		call fun
		pop BX
	pop BX
endm

;вызов функции fun с аргументом-адресом arg (для строквых функций)
runs macro fun, arg
	push BX
		push offset arg
		call fun
		pop BX
	pop BX
endm

;вывод строки по адресу arg
write macro arg
	push BX
		push offset arg
		call print
		pop BX
	pop BX
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Функции
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;вывод строки
print proc c uses AX DX, string:word
	mov		AH, 09h
	mov		DX, [string]
	int		21h
	ret
print endp	

;вывод символа
putch proc c uses AX DX, char:byte		
	mov		AH, 02h
	mov		DL, [char]
	int		21h		
	ret
putch endp

;очистка экрана
cls proc c uses AX DX
	;clear
	mov    AH, 00h
	mov    AL, 02h
	int    10H       
	
	;place cursor
	mov    AH, 02h
	mov    DX, 00h ;at 0,0
	int    10h
	ret
cls endp

;перевод строки
clrf proc c uses AX DX
	mov		AH, 02h
	mov		DL, 13
	int		21h
	mov		DL, 10
	int		21h
	ret
clrf endp

;ввод символа
getch proc
	mov     AH, 01h
	int     21h
	xor 	AH, AH
	ret
getch endp