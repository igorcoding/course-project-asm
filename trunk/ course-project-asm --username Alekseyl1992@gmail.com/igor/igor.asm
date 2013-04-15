;тестировочный проект (igor)
IgorPart segment PARA
assume CS:IgorPart, DS:IgorPart
org 100h

;резидентная часть
_start:
	jmp _loadTSR
	old DD 0
	
	_endProgram
	_loadTSR:
		mov AH, 35h               
		mov AL, XXh					; получение адреса старого обработчика
		int 21h                     ; прерываний от таймера
		mov WORD ptr old, BX        ; сохранение смещения обработчика
		mov WORD ptr old + 2, ES    ; сохранение сегмента обработчика
		mov AH, 25h
		mov AL, XXh					 ; установка адреса нашего обработчика
		;mov DX,  offset _proc        ; указание смещения нашего обработчика
		int 21h                      ; вызов DOS
		mov AX, 3100h                ; функция DOS завершения резидентной программы
		mov DX, (_endProgram - _start + 10Fh) / 16 ; определение размера резидентной
												   ; части программы в параграфах
		int 21h                  	; вызов DOS
	
IgorPart ends					 	 ; конец кодового сегмента
end _start							 ; конец программы