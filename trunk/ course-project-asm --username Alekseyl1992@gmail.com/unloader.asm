;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unloader.asm
;
; Сборка:
;  tasm.exe /l unloader.asm
;  tlink /t /x unloader.obj
;
; Программа для выгрузки TSR из памяти
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

code segment	'code'
	assume	CS:code, DS:code
	org	100h
	_start:
	
	mov AH, 0FFh
	mov AL, 1
	int 2Fh ; наше прерывание
	int 20h	; выходим
	
code ends
end _start