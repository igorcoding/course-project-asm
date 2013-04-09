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
