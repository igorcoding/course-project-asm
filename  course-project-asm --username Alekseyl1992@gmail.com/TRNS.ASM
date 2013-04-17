.model	tiny
code	segment	'code'
	assume	CS:code, DS:code
	org	100h
start	proc
	jmp	init
	old_2Fh	dd	0
	old_09h	dd	0
	vkl	db	1
	caps	db	0

;Новый обработчик прерываний от клавиатуры

	new_09h	proc
		push	AX
		push	BX
		push	ES
		push	DS
		push	CS
		pop	DS

		mov	AX, 40h 	;40h-сегмент,где хранятся флаги сост-я клавы,кольц. буфер ввода 
		mov	ES, AX
		in	AL, 60h	;записываем в AL состояние скен-код нажатой клавиши
		cmp	AL, 2Dh	;была нажата клавиша X?
		jne	dalee
		mov	AH, ES:[17h]     ;флаги клавиатуры
		and	AH, 00001111b
		cmp	AH, 00000100b	;был ли нажат ctrl?
		jne	dalee
		mov	AL, 1
		sub	AL, vkl
		mov	vkl, AL

		in	AL, 61h	;контроллер состояния клавиатуры
		or	AL, 10000000b	;пометим, что клавишу нажали
		out	61h, AL
		and	AL, 01111111b	;пометим, что клавишу отпустили
		out	61h, AL
		mov	AL, 20h
		out	20h, AL	;отправим в контроллер прерываний признак конца 	прерывания

		pop	DS
		pop	ES
		pop	BX
		pop	AX
		iret

dalee:		mov	AH, ES:[17h]
		and	AH, 01000000b	;CapsLock
		cmp	AH, 0
		je	prod
		mov	caps, 1
prod:		pushf
		call	old_09h
		cmp	vkl, 0
		je	_vih
		mov	BX, ES:[1Ch]	;адрес хвоста
		dec	BX	;сместимся назад к последнему
		dec	BX	;введённому символу
		cmp	BX, 1Eh	;не вышли ли мы за пределы буфера?
		jae	go
		mov	BX, 3Ch	;хвост вышел за пределы буфера, значит последний введённый символ
				;находится	в конце буфера

go:		mov	AX, ES:[BX]
		cmp	AX, 2146h	;F -> А
		jne	go1
		mov	word ptr ES:[BX], 2180h
_vih:		jmp	vih
go1:		cmp	AX, 2166h			;f -> а
		jne	go2
		mov	word ptr ES:[BX], 21A0h
		jmp	vih
go2:		cmp	AX, 333Ch			; < -> б
		jne	go3
		cmp	caps, 0
		je	bol_B
		mov	word ptr ES:[BX], 33A1h 
		jmp	vih
bol_B:		mov	word ptr ES:[BX], 3381h 
		jmp	vih

go3:		cmp	AX, 332Ch	; , -> б
		jne	go4
		cmp	caps, 0
		jne	bol_B
		mov	word ptr ES:[BX], 33A1h ;б
		jmp	vih

go4:		cmp	AX, 2044h	;D->В
		jne	go5
		mov	word ptr ES:[BX], 2082h
		jmp	vih
go5:		cmp	AX, 2064h	;d->в
		jne	go6
		mov	word ptr ES:[BX], 20A2h
		jmp	vih

go6:		cmp	AX, 1655h	;U->Г
		jne	go7
		mov	word ptr ES:[BX], 1683h
		jmp	vih
go7:		cmp	AX, 1675h	;u->г
		jne	go8
		mov	word ptr ES:[BX], 16A3h
		jmp	vih

go8:		cmp	AX, 264Ch	;L->Д
		jne	go9
		mov	word ptr ES:[BX], 2684h
		jmp	vih
go9:		cmp	AX, 266Ch	;l->д
		jne	go10
		mov	word ptr ES:[BX], 26A4h
go10:		cmp	AX, 273Ah	   ;       :	-> Ж
		jne	go11
		cmp	caps, 0
		je	bol_G
		mov	word ptr ES:[BX], 27A6h	
		jmp	vih
bol_G:		mov	word ptr ES:[BX], 2786h	
		jmp	vih

go11:		cmp	AX, 273Bh	  ; ; -> ж
		jne	go12
		cmp	caps, 0
		jne	bol_G
		mov	word ptr ES:[BX], 27A6h 
		jmp	vih
go12:		cmp	AX, 1950h	;P->З
		jne	go13
		mov	word ptr ES:[BX], 1987h
		jmp	vih
go13:		cmp	AX, 1970h	;p->з
		jne	go14
		mov	word ptr ES:[BX], 19A7h
		jmp	vih

go14:		cmp	AX, 3042h	    ;B->И
		jne	go15
		mov	word ptr ES:[BX], 3088h
		jmp	vih
go15:		cmp	AX, 3062h	     ;b->и
		jne	go16
		mov	word ptr ES:[BX], 30A8h
		jmp	vih

go16:		cmp	AX, 1352h	     ;R->К
		jne	go17
		mov	word ptr ES:[BX], 138Ah
		jmp	vih
go17:		cmp	AX, 1372h	     ;r->к
		jne	vih
		mov	word ptr ES:[BX], 13AAh

vih:		mov	caps, 0
		pop	DS
		pop	ES
		pop	BX
		pop	AX
	new_09h endp

;Новый обработчик прерывания 2Fh

	new_2Fh	proc
		cmp	AH, 0FFh	;наша функция?
		jne	vihod	;нет - на старый обработчик
		cmp	AL, 0	;подфункция проверки, загружен ли резидент в память?
		je	install
		cmp	AL, 1	;подфункция выгрузки из памяти?
		je	uninstall	
		jmp	vihod	;нет - на старый обработчик
	
install:		mov	AX, 'SS'	;вернём SS, если резидент загружен	в память
		iret
	
uninstall:		push	DS
		push	ES
		push	DX

		mov	AH, 25h     ;восстановим 9-е прерывание
		mov	AL, 09h
		lds	DX, CS:old_09h
		int	21h

		mov	AH, 25h      ;восстановим прерывание 2Fh
		mov	AL, 2Fh
		lds	DX, CS:old_2Fh
		int	21h

		mov	ES, CS:2Ch	;загрузим в ES адрес окружения			
		mov	AH, 49h		;выгрузим из памяти окружение
		int	21h

		push	CS
		pop	ES	;в ES - адрес резидентной проги
		mov	AH, 49h  ;выгрузим из памяти резидент
		int	21h
		pop	DX
		pop	ES
		pop	DS
		iret

vihod:		jmp	CS:old_2Fh	;вызов старого обработчика
	new_2Fh	endp

	end_res=$
start	endp

;Инициализация

	init	proc
		call	param
		call	load_tsr
	init	endp

;Загрузчик резидента  память

	load_tsr	proc
		mov	AX, 0FF00h
		int	2Fh	;проверка на наличие резидента в памяти
		cmp	AX, 'SS'	;если вернули АА - резидент в памяти
		je	installed
		mov	AH, 35h  ;получим адрес
		mov	AL, 2Fh  ;обработчика прерывания 2Fh
		int	21h

		mov	word ptr CS:old_2Fh, BX ;запишем смещение старого обработчика
		mov	word ptr CS:old_2Fh + 2, ES ;запишем сегмент

		mov	AH, 25h		;установим новый адрес
		mov	AL, 2Fh		;обработчика прерывания 2Fh
		mov	DX, offset	new_2Fh
		int	21h

		mov	AH, 35h    ;получим адрес обработчика
		mov	AL, 09h    ;9-го прерывания
		int	21h

		mov	word ptr CS:old_09h, BX
		mov	word ptr CS:old_09h + 2, ES

		mov	AH, 25h    ;установим	новый адрес
		mov	AL, 09h    ;обработчика прерывания 09h
		mov	DX, offset	new_09h
		int	21h

		mov	AH, 09h
		mov	DX, offset tsr_load
		int	21h

		mov	AX, 3100h	;выйти из программы и оставить в ОП её резидентную часть
		mov	DX, (end_res-start+10Fh)/16	;размер резидента
		int	21h

installed:		mov	AH, 09h
		mov	DX, offset	tsr_error
		int	21h
		mov	AX, 4C01h	;выйти из программы с кодом ошибки 1
		int	21h
	load_tsr	endp

;Определение	параметров запуска

	param	proc
		push	ES
		xor	CX, CX
		mov	CL, ES:[80h]
		cmp	CL, 0
		je	konec
		mov	SI, 81h

prob:		mov	AL, ES:[SI]
		cmp	AL, ' '
		jne	vih1
		inc	SI
		loop	prob

vih1:		mov	AL, ES:[SI]
		cmp	AL, 0
		je	konec
		cmp	AL, '/'
		jne	error_p
		inc	SI
		dec	CL
		mov	AL, ES:[SI]
		cmp	AL, '?'
		jne	error_p
		inc	SI
		dec	CL
		cmp	CL, 0
		je	sprav

sprav:		mov	AH, 09h
		mov	DX, offset	spravka
		int	21h
		mov	AX, 4C00h
		int	21h

prob2:		mov	AL, ES:[SI]
		cmp	AL, ' '
		jne	vih3
		inc	SI
		loop	prob2

vih3:		mov	AL, ES:[SI]
		cmp	AL, 0
		jne	error_p
konec:		pop	ES
		ret

error_p:		mov	AH, 09h
		mov	DX, offset error
		int	21h
		mov	AX, 4C01h
		int	21h
	param	endp

tsr_load		db	'Succesfully loaded!', 10, 13, '$'
tsr_error		db	'Already loaded!', 10, 13, 'Can not load twice', 10, 13, '$'
tsr_unload	db	'Unloaded!',10, 13,	'$'
ninst		db	'Not loaded!', 10, 13, '$'

spravka		db	'Start as:', 10, 13,'>trns.com',10,13, 'To  Ctrl+x',10,13, 'To  unload: call unldtsr.exe',10,13,'$'
error		db	'Bad parametrs!', 10, 13, '$'

par_u		db	0
code		ends
end		start
