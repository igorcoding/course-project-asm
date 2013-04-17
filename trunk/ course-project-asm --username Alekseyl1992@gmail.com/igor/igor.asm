;тестировочный проект (igor)
IgorPart segment 'code'
assume CS:IgorPart, DS:IgorPart, SS:IgorPart
org 100h


;резидентная часть
_start:
	jmp _loadTSR
	
	msg2	  				DB	'resident has been loaded', 13, 10, '$'
	mess_load 				DB  'Program has already loaded !!!','$'
	old_09h   				DD	0
	old_1Ch   				DD	0
	counter	  				DW	0
	isPrintingSignature		DW	0
	printDelay				equ	2 ; задержка перед выводом "подписи" в секундах
	printPos				DW	1 ; положение подписи на экране. 0 - верх, 1 - центр, 2 - низ
	
	;;;;заменить на собственные данные. формирование таблицы идет по строке бОльшей длины.
	;;;;можно формировать через код, но это слишком сильно увеличивает как объем работы, так и объем самого кода
	signatureLine1			DB	179, 'Игорь Латкин', 179, 10
	Line1_length 			equ	$-signatureLine1
	signatureLine2			DB	179, 'ИУ5-44      ',179,  10
	Line2_length 			equ	$-signatureLine2
	signatureLine3			DB	179, 'Вариант #0  ', 179, 10
	Line3_length 			equ	$-signatureLine3
	helpMsg					DB	10, 13, 'some help', 10, 13
	helpMsg_length			equ $-helpMsg
	errorParamMsg			DB	10, 13, 'some error on param', 10, 13
	errorParamMsg_length	equ	$-errorParamMsg
	tmpMsg					DB	10, 13, 'temp message', 10, 13
	tmpMsg_length			equ $-tmpMsg
	
	tableTop				DB	218, Line1_length-3 dup (196), 191, 10
	tableTop_length 		equ	$-tableTop
	tableBottom				DB	192, Line1_length-3 dup (196), 217, 10
	tableBottom_length 		equ $-tableBottom
	
	;=== Обработчик прерывания int 09h ===
	new_09h proc
		push AX
		push DX
		
		pushf
		call CS:old_09h
		
		push CS
		pop DS
		
		in AL,60h
		cmp AL,3Bh
		jne _noF1
		
		mov isPrintingSignature, 1

		_noF1:
		pop DX
		pop AX
		
		iret
	new_09h endp
	
	;=== Обработчик прерывания int 1Ch ===;
	;=== Вызывается каждые 55 мс ===;
	new_1Ch proc
		push AX
		push CS
		pop DS
		
		pushf
		call CS:old_1Ch
		
		cmp isPrintingSignature, 1 ;если нажата управляющая клавиша (в данном случае F1)
		jne _notToPrint		
		
			cmp counter, printDelay*1000/55 + 1 ;если кол-во "тактов" эквивалентно %printDelay% секундам
			je _letsPrint
			
			jmp _dontPrint
			
			_letsPrint:
				mov isPrintingSignature, 0
				mov counter, 0
				call printSignature
			
			_dontPrint:
				add counter, 1
			
		_notToPrint:
		
		pop AX
		
		iret
	new_1Ch endp
	
	printSignature proc
		push AX
		push DX
		push CX
		push BX
		push ES
		push SP
		push BP
		push SI
		push DI

		xor AX, AX
		xor DX, DX
		
		mov AH, 03h						;чтение текущей позиции курсора
		int 10h
		push DX							;помещаем информацию о положении курсора в стек
		
		cmp printPos, 0
		je _printTop
		
		cmp printPos, 1
		je _printCenter
		
		cmp printPos, 2
		je _printBottom
		
		;все числа подобраны на глаз...
		_printTop:
			mov DH, 0
			mov DL, 1Fh
			jmp _actualPrint
		
		_printCenter:
			mov DH, 9
			mov DL, 1Fh
			jmp _actualPrint
			
		_printBottom:
			mov DH, 19
			mov DL, 1Fh
			jmp _actualPrint
			
		_actualPrint:	
			mov AH, 0Fh					;чтение текущего видеорежима. в BH - текущая страница
			int 10h
	
			push CS						;
			pop ES						;указываем ES на CS
			
			;вывод 'верхушки' таблицы
			lea BP, CS:tableTop			;помещаем в BP указатель на выводимую строку
			mov CX, tableTop_length		;в CX - длина строки
			mov BL, 0111b 				;цвет выводимого текста ref: http://en.wikipedia.org/wiki/BIOS_color_attributes
			mov AX, 1301h				;AH=13h - номер ф-ии, AL=01h - курсор перемещается при выводе каждого из символов строки
			int 10h
			
			;вывод первой линии
			lea BP, CS:signatureLine1
			mov CX, Line1_length
			mov BL, 0111b
			sub DL, tableTop_length-1	;смещаем начало ввода на "нужное"
			mov AX, 1301h
			int 10h
			
			;вывод второй линии
			lea BP, CS:signatureLine2
			mov CX, Line2_length
			mov BL, 0111b
			sub DL, Line1_length-1		;смещаем начало ввода на "нужное"
			mov AX, 1301h
			int 10h
			
			;вывод третьей линии
			lea BP, CS:signatureLine3
			mov CX, Line3_length
			mov BL, 0111b
			sub DL, Line2_length-1
			mov AX, 1301h
			int 10h
			
			;вывод 'низа' таблицы
			lea BP, CS:tableBottom
			mov CX, tableBottom_length
			mov BL, 0111b
			sub DL, Line3_length-1		;смещаем начало ввода на "нужное"
			mov AX, 1301h
			int 10h
			
			pop DX						;восстанавливаем из стека прежнее положение курсора
			mov AH, 02h					;меняем положение курсора на первоначальное
			int 10h
			
		pop DI
		pop SI
		pop BP
		pop SP
		pop ES
		pop BX
		pop CX
		pop DX
		pop AX
		
		ret
	printSignature endp
	
	
	showHelp proc
		push CS
		pop ES
		mov SI, 80h   				;SI=смещение командной строки.
		lodsb        					;Получим кол-во символов.
		or AL, AL     				;Если 0 символов введено, 
		jz Got_cmd   					;то все в порядке. 
		cmp AL, 3     				;Иначе ввели не 3 символа? (пробел + /X)
		jne No_string 				;Да - на метку No_string 

		inc SI       					;Теперь SI указывает на первый символ строки.

		Next_char:
			lodsw       				;Получаем два символа
			cmp AX, '?/' 				;Это '/?' ? Данные будут наоборот!
			je _question 				;Да - на выход... 
			cmp AX, 'u/'
			je _finishTSR
			
			jmp No_string
			;mov AL, 1    			;Сигнал того,  что пора удалять программу из памяти
			ret

		Got_cmd:
			xor AL, AL 				;Сигнал того, что ничего не ввели в командной строке
			ret  					;Выходим из процедуры

		No_string:
			mov AL, 3 				;Сигнал неверного ввода командной строки
			ret
	   
		_question:
			; вывод строки помощи
				mov AH,03
				int 10h	
				lea BP, CS:helpMsg
				mov CX, helpMsg_length
				mov BL, 0111b
				mov AX, 1301h
				int 10h
			; конец вывода строки помощи
			jmp Next_char
		
		_finishTSR:
			; do something smart
			; вывод строки
				mov AH,03
				int 10h	
				lea BP, CS:tmpMsg
				mov CX, tmpMsg_length
				mov BL, 0111b
				mov AX, 1301h
				int 10h
			; конец вывода строки
			jmp Next_char
		
		
		
		jmp exitHelp

		errorParam:
			;вывод строки
				mov AH,03
				int 10h	
				lea BP, CS:errorParamMsg
				mov CX, errorParamMsg_length
				mov BL, 0111b
				mov AX, 1301h
				int 10h
			;конец вывода строки
		exitHelp:
		ret
	showHelp endp

		
	_loadTSR:
		;---------------Проверка загрузки программы в ОП--
		mov AX, 0FF00h      
		int 2Fh
		cmp AL, 0AAh
		je already_load             

		;---------------Установка текстового режима-------
		mov AH,03
		int 10h	
		
		mov AH,00h
		mov AL,83h
		int 10h
		
		mov AH,02
		int 10h	
		
		call showHelp
		
		;===== int 09h loading =====;
		mov AX, 3509h
		int 21h
		mov WORD ptr CS:old_09h, BX
		mov WORD ptr CS:old_09h + 2, ES
		mov AX, 2509h
		lea DX, new_09h
		int 21h
		
		;===== int 1Ch loading =====;
		mov AX, 351Ch
		int 21h
		mov WORD ptr CS:old_1Ch, BX
		mov WORD ptr CS:old_1Ch + 2, ES
		mov AX, 251Ch
		lea DX, new_1Ch
		int 21h
		
		;===== Terminate and stay resident =====;	
		mov AH, 09h
		mov DX, offset msg2
		int 21h
		
		mov DX, (_loadTSR - _start + 10Fh) / 16
		mov AX, 3100h
		int 21h
		jmp _exit
		
		already_load:                            
			mov AH, 09h
			mov DX, offset mess_load     
			int 21h
		
		_exit:
			mov AX, 4C00h
			int 21h
	

IgorPart ends					 	 ; конец кодового сегмента
end _start							 ; конец программы