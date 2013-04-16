;тестировочный проект (igor)
IgorPart segment 'code'
assume CS:IgorPart, DS:IgorPart
org 100h


;резидентная часть
_start:
	jmp _loadTSR
	
	msg1	DB	'a key has been pressed', 13, 10, '$'
	msg2	DB	'resident has been loaded', 13, 10, '$'

	old_09h DD 0
	
	new_09h proc
		push AX
		push DX
		
		mov AH, 09h
		mov DX, offset msg1
		int 21h
		
		;pushf
		;call DWORD ptr old_09h
		
		pop DX
		pop AX
		iret
	new_09h endp

		
	_loadTSR:
		push CS
		pop DS
		;===== int 09h loading =====;
		mov AX, 3509h
		int 21h
		mov WORD ptr old_09h, BX
		mov WORD ptr old_09h + 2, ES
		mov AX, 2509h
		lea DX, new_09h
		int 21h
		
		;===== Terminate and stay resident =====;	
		mov AH, 09h
		mov DX, offset msg2
		int 21h
		
		mov DX, (_loadTSR - _start + 10Fh) / 16
		mov AX, 3100h
		int 21h
		
		_exit:
			mov AX, 4C00h
			int 21h
	

IgorPart ends					 	 ; конец кодового сегмента
end _start							 ; конец программы