.model	tiny
code segment	'code'
	assume	CS:code, DS:code
	org	100h
	_start:
	
	jmp real_start  ; на начало программы
    installed dw 8888 ; будем потом проверят,установлена прога или нет
    ignored_chars db 'abcdefghijklmnopqrstuvwxyz' ; список игнорируемых символов
	ignored_length dw 26
	ignore_enabled db 0 ; флаг функции игнорирования ввода
	translate_from db 'F<DUL' ;символы для замены (АБВГД на англ. раскладке)
	translate_to db 'АБВГД' ; символы на которые будет идти замена
	translate_length dw 5 ; длина строки trasnlate_from
	translate_enabled db 0 ; флаг функции перевода
	
	signaturePrintingEnabled db 0 ; флаг функции вывода информации об авторе
	cursiveEnabled db 0 ; флаг перевода символа в курсив
	
	true equ 0ffh ; константа истинности
    old_int9h_offset dw ?
    old_int9h_segment dw ?
	old_09h dd 0
	
    ;новый обработчик
    new_int9h proc far
		push SI
		push	AX
		push	BX
		push	CX
		push	DX
		push	ES
		push	DS
		push	CS
		pop	DS

		;проверка F1-F4
		in AL, 60h
		sub AL, 58
		_F1:
			cmp al, 1 ; F1
			jne _F2
			not signaturePrintingEnabled
			jmp _translate_or_ignore
		_F2:
			cmp al, 2 ; F2
			jne _F3
			not cursiveEnabled
			jmp _translate_or_ignore
		_F3:
			cmp al, 3 ; F3
			jne _F4
			not translate_enabled
			jmp _translate_or_ignore
		_F4:
			cmp al, 4 ; F4
			jne _translate_or_ignore
			not ignore_enabled
			jmp _translate_or_ignore
			
		
		;игнорирование и перевод
		_translate_or_ignore:
		
		pushf
		call dword ptr cs:[old_int9h_offset]
		mov	AX, 40h 	;40h-сегмент,где хранятся флаги сост-я клавы,кольц. буфер ввода 
		mov	ES, AX
		mov	BX, ES:[1Ch]	;адрес хвоста
		dec	BX	;сместимся назад к последнему
		dec	BX	;введённому символу
		cmp	BX, 1Eh	;не вышли ли мы за пределы буфера?
		jae	go
		mov	BX, 3Ch	;хвост вышел за пределы буфера, значит последний введённый символ
				;находится	в конце буфера

	go:		
		mov DX, ES:[BX] ; в DX 0 введённый символ
		;включен ли режим блокировки ввода?
		cmp ignore_enabled, true
		jne _check_translate
		
		; да, включен
		mov si, 0
		mov cx, ignored_length ;кол-во игнорируемых символов
				
	_check_ignored:
		cmp dl,ignored_chars[si]
		je _block
		inc si
	loop _check_ignored
		jmp _check_translate
		
	_block:
		mov es:[1ch], bx ;блокировка вывода символа
		jmp _quit
	
	_check_translate:
		;включен ли режим перевода?
		cmp translate_enabled, true
		jne _quit
		
		; да, включен
		mov si, 0
		mov cx, translate_length ;кол-во символов для перевода
		
		_check_translate_loop:
			cmp dl, translate_from[SI]
			je _translate
			inc SI
		loop _check_translate_loop
		jmp _quit
		
		_translate:		
			xor ax, ax
			mov al, translate_to[SI]
			mov es:[bx], ax	; замена символа
			
	_quit:
		pop	DS
		pop	ES
		pop DX
		pop CX
		pop	BX
		pop	AX
		pop SI
		iret
new_int9h endp  

real_start:                         ; старт основной программы
    mov ax,3509h                    ; получить в ES:BX вектор 09
    int 21h                         ; прерывания
    cmp word ptr es:installed,8888  ; проверка того, загружена ли уже программа
    je remove                       ; если загружена - выгружаем
    push es
    mov ax, ds:[2Ch]                ; psp
    mov es, ax
    mov ah, 49h                     ; хватит памяти чтоб остаться
    int 21h                         ; резидентом?
    pop es
    jc not_mem                      ; не хватило - выходим
	mov	word ptr CS:old_int9h_offset, BX
	mov	word ptr CS:old_int9h_segment, ES
    mov ax, 2509h                   ; установим вектор на 09
    mov dx, offset new_int9h            ; прерывание
    int 21h
    mov dx, offset ok_installed         ; выводим что все ок
    mov ah, 9
    int 21h
    mov dx, offset real_start       ; остаемся в памяти резидентом
    int 27h                         ; и выходим
    ; конец основной программы  
remove:                             ; выгрузка программы из памяти
    push es
    push ds
    mov dx, es:old_int9h_offset         ; возвращаем вектор прерывания
    mov ds, es:old_int9h_segment        ; на место
    mov ax, 2509h
    int 21h
    pop ds
    pop es
    mov ah, 49h                     ; освобождаем память
    int 21h
    jc not_remove                   ; не освободилась - ошибка
    mov dx, offset removed_msg      ; все хорошо
    mov ah, 9
    int 21h
    jmp exit                        ; выходим из программы
not_remove:                         ; ошибка с высвобождением памяти.
    mov dx, offset noremove_msg                     
    mov ah, 9
    int 21h
    jmp exit
not_mem:                            ; не хватает памяти, чтобы остаться резидентом
    mov dx, offset nomem_msg
    mov ah, 9
    int 21h
exit:                               ; выход
    int 20h
ok_installed db 'Installed$'
nomem_msg db 'Out of memory$'
removed_msg db 'Uninstalled$'
noremove_msg db 'Error: cannot unload program$'

code ends
end _start