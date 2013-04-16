;тестировочный проект (igor)
IgorPart segment 'code'
assume CS:IgorPart, DS:IgorPart, SS:IgorPart
org 100h


;резидентная часть
_start:
	jmp _loadTSR
	
	msg1	  DB	'a key has been pressed', 13, 10, '$'
	msg2	  DB	'resident has been loaded', 13, 10, '$'
	mess_load DB    'Program has already loaded !!!','$'
	old_09h   DD	0
	old_1Ch   DD	0
	counter	  DW	0
	isPrintingSignature	DW	0
	printDelay	equ	5 ; в секундах
	printPos	DW	2 ;0 - верх, 1 - центр, 2 - низ
	signatureLine1	DB	'Igor Latkin', 10
	Line1_length 	equ	$-signatureLine1
	signatureLine2	DB	'IU5-44', 10
	Line2_length 	equ	$-signatureLine2
	signatureLine3	DB	'Variant #0', 10
	Line3_length 	equ	$-signatureLine3
	
	
	new_09h proc
		push AX
		push DX
		push CS
		pop DS
		
		in AL,60h
		cmp AL,3Bh
		jne _no
		
		mov AX, 1
		mov isPrintingSignature, AX

		_no:
		pop DX
		pop AX
		pushf
		call CS:old_09h
		iret
	new_09h endp
	
	new_1Ch proc
		push AX
		push CS
		pop DS
		
		cmp isPrintingSignature, 1
		jne _notToPrint		
		
			cmp counter, printDelay*1000/55 + 1
			je _letsPrint
			
			jmp _dontPrint
			
			_letsPrint:
				mov AX, 0
				mov isPrintingSignature, AX
				mov counter, 0
				call printSignature
			
			_dontPrint:
			mov AX, counter
			add AX, 1
			mov counter, AX
			
		_notToPrint:
		
		pop AX
		pushf
		call CS:old_1Ch
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
		
		mov AH, 03h
		int 10h
		push DX
		
		cmp printPos, 0
		je _printTop
		
		cmp printPos, 1
		je _printCenter
		
		cmp printPos, 2
		je _printBottom
		
		_printTop:
			mov DH, 0
			mov DL, 21h
			jmp _actualPrint
		
		_printCenter:
			mov DH, 9
			mov DL, 21h
			jmp _actualPrint
			
		_printBottom:
			mov DH, 20
			mov DL, 21h
			jmp _actualPrint
			
		_actualPrint:	
			call clrscr
			
			mov AH, 0Fh
			int 10h
	
			push CS
			pop ES
			
			lea BP, CS:signatureLine1
			mov CX, Line1_length
			mov BH, 0
			mov BL, 0111b ;the color
			mov AX, 1301h
			int 10h
			
			lea BP, CS:signatureLine2
			mov CX, Line2_length
			mov BH, 0
			mov BL, 0111b ;the color
			sub DL, Line1_length-1
			mov AX, 1301h
			int 10h
			
			lea BP, CS:signatureLine3
			mov CX, Line3_length
			mov BH, 0
			mov BL, 0111b ;the color
			sub DL, Line2_length-1
			mov AX, 1301h
			int 10h
			
			pop DX
			mov AH, 02h
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
	
	
	clrscr proc c uses AX DX
		mov AH, 00h       ;очистка
		mov AL, 02h
		int 10H       
		
		mov AH, 02h       ;функция установки курсора
		mov DX, 00h       ;координаты 0,0
		int 10h        	  ;установка курсора
		ret
	clrscr endp
		
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