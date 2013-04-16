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
	printPos	DW	0 ;0 - верх, 1 - центр, 2 - низ
	
	new_09h proc
		push AX
		push DX
		
		in AL,60h
		cmp AL,3Bh
		jne _no
		
		mov AX, 1
		mov isPrintingSignature, AX
		
		mov AH, 0Ah
		mov AL, '&'
		mov CX, 1
		int 10h
		
		mov AH, 03h
		int 10h
		add DL, 1
		mov AH, 02h
		int 10h
		
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
		
		cmp isPrintingSignature, 0
		je _notToPrint
		
			mov AH, 0Ah
			mov AL, '.'
			mov CX, 1
			int 10h
			
			mov AH, 03h
			int 10h
			add DL, 1
			mov AH, 02h
			int 10h
		
		
			cmp counter, 91;printDelay*1000/55 + 1
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

		xor AX, AX
		xor DX, DX
		
		mov AH, 0Ah
		mov AL, '!'
		mov CX, 5
		int 10h
		
		mov AH, 03h
		int 10h
		add DL, 5
		mov AH, 02h
		int 10h
			
		pop CX
		pop DX
		pop AX
		
		ret
	printSignature endp

		
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