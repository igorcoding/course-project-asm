.model	tiny
code segment	'code'
	assume	CS:code, DS:code
	org	100h
	_start:
	
	jmp _initTSR  ; на начало программы
    installed DW 8888 ; будем потом проверят,установлена прога или нет
    ignoredChars DB 'abcdefghijklmnopqrstuvwxyz' ; список игнорируемых символов
	ignoredLength DW 26
	ignoreEnabled DB 0 ; флаг функции игнорирования ввода
	translateFrom DB 'F<DUL' ;символы для замены (АБВГД на англ. раскладке)
	translateTo DB 'АБВГД' ; символы на которые будет идти замена
	translateLength DW 5 ; длина строки trasnlate_from
	translateEnabled DB 0 ; флаг функции перевода
	
	signaturePrintingEnabled DB 0 ; флаг функции вывода информации об авторе
	cursiveEnabled DB 0 ; флаг перевода символа в курсив
	
	true equ 0ffh ; константа истинности
    old_int9hOffset DW ? ; адрес старого обработчика int 9h
    old_int9hSegment DW ? ; сегмент старого обработчика int 9h
	
    ;новый обработчик
    new_int9h proc far
		; сохраняем значения всех, изменяемых регистров в стэке
		push SI
		push AX
		push BX
		push CX
		push DX
		push ES
		push DS
		; синхронизируем CS и DS
		push CS
		pop	DS

		;проверка F1-F4
		in AL, 60h
		sub AL, 58
		_F1:
			cmp AL, 1 ; F1
			jne _F2
			not signaturePrintingEnabled
			jmp _translate_or_ignore
		_F2:
			cmp AL, 2 ; F2
			jne _F3
			not cursiveEnabled
			jmp _translate_or_ignore
		_F3:
			cmp AL, 3 ; F3
			jne _F4
			not translateEnabled
			jmp _translate_or_ignore
		_F4:
			cmp AL, 4 ; F4
			jne _translate_or_ignore
			not ignoreEnabled
			jmp _translate_or_ignore
			
		
		;игнорирование и перевод
		_translate_or_ignore:
		
		pushf
		call dword ptr CS:[old_int9hOffset]
		mov	AX, 40h 	;40h-сегмент,где хранятся флаги сост-я клавы,кольц. буфер ввода 
		mov	ES, AX
		mov	BX, ES:[1Ch]	;адрес хвоста
		dec	BX	;сместимся назад к последнему
		dec	BX	;введённому символу
		cmp	BX, 1Eh	;не вышли ли мы за пределы буфера?
		jae	_go
		mov	BX, 3Ch	;хвост вышел за пределы буфера, значит последний введённый символ
				;находится	в конце буфера

	_go:		
		mov DX, ES:[BX] ; в DX 0 введённый символ
		;включен ли режим блокировки ввода?
		cmp ignoreEnabled, true
		jne _check_translate
		
		; да, включен
		mov SI, 0
		mov CX, ignoredLength ;кол-во игнорируемых символов
		
		; проверяем, присутствует ли текущий символ в списке игнорируемых
	_check_ignored:
		cmp DL,ignoredChars[SI]
		je _block
		inc SI
	loop _check_ignored
		jmp _check_translate
		
	; блокируем
	_block:
		mov ES:[1Ch], BX ;блокировка ввода символа
		; если по варианту нужно не блокировать ввод символа,
		; а заменять одни символы другими,
		; замените строку выше строкой
		; mov ES:[BX], AX
		; на месте AX может быть '*' для замены всех символов множества ignoredChars на звёздочки
		; или, для перевода одних символов в другие - завести массив
		; replaceWith DB '...', где перечислить символы, на которые пойдёт замена
		; и раскомментировать строки ниже:
		;   xor AX, AX
		; 	mov AL, replaceWith[SI]
		;	mov ES:[BX], AX	; замена символа
		jmp _quit
	
	_check_translate:
		;включен ли режим перевода?
		cmp translateEnabled, true
		jne _quit
		
		; да, включен
		mov SI, 0
		mov CX, translateLength ;кол-во символов для перевода
		; проверяем, присутствует ли текущий символ в списке для перевода
		_check_translate_loop:
			cmp DL, translateFrom[SI]
			je _translate
			inc SI
		loop _check_translate_loop
		jmp _quit
		
		; переводим
		_translate:		
			xor AX, AX
			mov AL, translateTo[SI]
			mov ES:[BX], AX	; замена символа
			; замените AX на '*', если нужно заменять символы на звёздочку
			
	_quit:
		; восстанавливаем все регистры
		pop	DS
		pop	ES
		pop DX
		pop CX
		pop	BX
		pop	AX
		pop SI
		iret
new_int9h endp  

_initTSR:                         ; старт основной программы
    mov AX,3509h                    ; получить в ES:BX вектор 09
    int 21h                         ; прерывания
    cmp word ptr ES:installed, 8888  ; проверка того, загружена ли уже программа
    je _remove                       ; если загружена - выгружаем
    push ES
    mov AX, DS:[2Ch]                ; psp
    mov ES, AX
    mov AH, 49h                     ; хватит памяти чтоб остаться
    int 21h                         ; резидентом?
    pop ES
    jc _notMem                      ; не хватило - выходим
	mov	word ptr CS:old_int9hOffset, BX
	mov	word ptr CS:old_int9hSegment, ES
    mov AX, 2509h                   ; установим вектор на 09
    mov DX, offset new_int9h            ; прерывание
    int 21h
    mov DX, offset installedMsg         ; выводим что все ок
    mov AH, 9
    int 21h
    mov DX, offset _initTSR       ; остаемся в памяти резидентом
    int 27h                         ; и выходим
    ; конец основной программы  
_remove:                             ; выгрузка программы из памяти
    push ES
    push DS
    mov DX, ES:old_int9hOffset         ; возвращаем вектор прерывания
    mov DS, ES:old_int9hSegment        ; на место
    mov AX, 2509h
    int 21h
    pop DS
    pop ES
    mov AH, 49h                     ; освобождаем память
    int 21h
    jc _notRemove                   ; не освободилась - ошибка
    mov DX, offset removedMsg      ; все хорошо
    mov AH, 9
    int 21h
    jmp _exit                        ; выходим из программы
_notRemove:                         ; ошибка с высвобождением памяти.
    mov DX, offset noRemoveMsg                     
    mov AH, 9
    int 21h
    jmp _exit
_notMem:                            ; не хватает памяти, чтобы остаться резидентом
    mov DX, offset noMemMsg
    mov AH, 9
    int 21h
_exit:                               ; выход
    int 20h
installedMsg DB 'Installed$'
noMemMsg DB 'Out of memory$'
removedMsg DB 'Uninstalled$'
noRemoveMsg DB 'Error: cannot unload program$'

code ends
end _start