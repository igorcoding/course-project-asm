;тестировочный проект (igor)

.model small
.data

.code
org 100h
igorMain:

	call exit


	exit proc c uses AX
		mov AH, 4Ch
		int 21h
		int 20h
		ret
	exit endp
	
end igorMain