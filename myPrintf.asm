;:=============================================================:
;[ MyPrintf.asm (masm + link + WinAPI + LibC)	made by Temo4ka]
;:=============================================================:
; ml /c "myPrintf.asm" /Fl /Sa /Cp /Zi
; link  "myPrintf.obj" kernel32.lib user32.lib libcmt.lib /subsystem:console
;-------------------------------------------------              

.model flat, stdcall
option casemap: none


;includelib kernel32.lib
GetStdHandle  proto :dword
WriteConsoleA proto :dword, :dword, :dword, :dword, :dword
ExitProcess   proto :dword

strlen proto C: dword

;-------------------------------------------------              
PutS proto: dword
Format_Basis proto: word
print_minus proto: dword
;-------------------------------------------------              

STD_OUTPUT_HANDLE equ -11d

LOWEST_BIN 		equ    001b
LOWEST_OCT 		equ    007d
LOWEST_HEX 		equ    00Fh
TABLE_SIZE 		equ    030d
B_NUM			equ    004d
C_NUM			equ    008d
D_NUM			equ    012d
O_NUM			equ    056d
S_NUM			equ    072d
X_NUM			equ    092d
BUFFER_SIZE	 	equ    100d
SIGN_BYTE		equ 080000000h ; ~(-1 >> 1)s

.data
	  Char			db         0, 0
	 Buffer 	    db      130 dup(0)
	HexTable        db "0123456789ABCDEF", 0
	 Love			db	     "LOVE", 0
	 format  	    db     "%c %d %c (%P), %d %s %x %d%%%c%b", 0
;-------------------------------------------------              
.code
Start:

	push 127d
	push 33d
	push 100d
	push 3802d
	push offset Love
	push -1d

	push 33d
	push -10d
	push 33d

	push offset format
	call MyPrintf

    invoke ExitProcess, 0

;---------------------------------------------------

;---------------------------------------------------
; PutS
;===================================================
; Input  :  offset to the msg
;
; Output :  None
;
;Destroys:  EAX
;---------------------------------------------------

.code
PutS proc msg: dword

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	push eax

	invoke strlen, msg

	pop edx
	invoke WriteConsoleA, edx, msg, eax, 0, 0

	ret
PutS endp
;---------------------------------------------------
; MyPrintf: prints string according to format
;===================================================
; Input  :				Stack
;		    /__VA_ARGS__|_format_string_|_fd_\ 
;			         				     	 ^									
;									        top
;
; Output :  None
;
;Destroys:  EDX, EAX, EDI, ECX, EBX, ESI
;---------------------------------------------------
.code
MyPrintf proc
	pop ebp
	pop ebx

	xor ecx, ecx

	l5:
	cmp byte ptr [ebx + ecx], 0
	je end_of_printf

		cmp byte ptr[ebx + ecx], '%'
		jne next_symbol

		mov byte ptr[ebx + ecx], 0

		pusha
		invoke PutS, ebx
		popa

		inc ecx

		lea ebx, [ebx + ecx]
		xor ecx,     ecx

		xor edx, edx
		mov dl, byte ptr[ebx]
		lea si, [offset Buffer + BUFFER_SIZE - 1d]

		cmp dl,     '%'
		je default_printf

		lea edx, [edx - 'a']

		cmp dl, 26d
		ja default_printf

		cmp dl, 0d
		jb default_printf

		jmp [offset JumpTable + edx * 4]
		
	next_symbol:
	inc ecx
	continue:
	jmp l5

	end_of_printf:

	pusha
	invoke PutS, ebx
	popa

	push ebp
	ret

;-------------------------------------------------------
; Makes bin conversation of the number and prints it
;=======================================================
; Input  :  SI = offset to the end buffer
;
; Output :  SI = offset to the first string symbol
;
;Destroys: EAX
;---------------------------------------------------
.code
B_printf:	
	pop edi
	inc ebx

	pusha
	invoke print_minus, offset Char
	invoke Format_Basis, 1d
	popa

jmp continue
;-------------------------------------------------

;-----------------------------------------------------
; Makes oct conversation of the number and prints it
;=====================================================
; Input  :  SI = offset to the first string symbol
;
; Output :  SI = offset to the first string symbol
;
;Destroys: DX, SE, SI
;-------------------------------------------------
.code
O_printf:	
	pop edi
	inc ebx

	pusha
	invoke print_minus, offset Char
	invoke Format_Basis, 3d
	popa

jmp continue

;-------------------------------------------------   

;------------------------------------------------------
; Makes hex conversation of the number and prints it
;======================================================
; Input  :  EBX = number
;           EDX = offset to the end of the buffer
;
; Output :  SI = offset to the first string symbol
;
;Destroys: DX, SE, SI
;----------------------------------------
.code
X_printf:	
	pop edi
	inc ebx

	pusha
	invoke print_minus, offset Char
	invoke Format_Basis, 4d
	popa

jmp continue

;-------------------------------------------------

;----------------------------------------------------
; Makes dec conversation of the number and prints it
;====================================================
; Input  :  SI = offset to the end of the buffer
;
; Output :  SI = offset to the first string symbol
;
;Destroys: DX, SE, SI
;-------------------------------------------------
.code
D_printf:
	pop edi
	
	invoke print_minus, offset Char

    mov eax, edi
    mov edi, 10d
    
	l4:
		xor edx, edx
		div edi
		
		add dl, '0'	
		mov byte ptr [esi], dl
		dec esi 
		
	cmp ax, 0h
	jne l4

	inc ebx
	inc esi
	
	pusha
	invoke PutS, esi
	popa

jmp continue
;-------------------------------------------------

;-------------------------------------------------
; String to buffer
;=================================================
; Input  :  EDI = number
;           SI  = offset to the end of the buffer
;
; Output :  SI = offset to the first string symbol
;
;Destroys: DX, SE, SI
;----------------------------------------
.code
S_printf:
	pop edi

	inc esi
	inc ebx

	pusha
	invoke PutS, edi
	popa

jmp continue
;-------------------------------------------------

;-------------------------------------------------
; Char to buffer
;=================================================
; Input  :  EDI = number
;           SI  = offset to the end of the buffer
;
; Output :  SI = offset to the first string symbol
;
;Destroys: DX, SE, SI
;----------------------------------------
.code
C_printf:
	pop edx
	
	lea eax, [Char]
	mov byte ptr [eax], dl

	inc ebx

	pusha
	invoke PutS, offset Char
	popa

jmp continue
;-------------------------------------------------

;-------------------------------------------------
; Prints next symbol after '%'
;=================================================
; Input  :  EBX = 			number
;           SI  = offset to the end of the buffer
;
; Output :  SI = offset to the first string symbol
;
;Destroys: EAX, EBX, EDX, ESI
;-------------------------------------------------
.code
default_printf:

	mov al, [ebx]
	mov byte ptr [esi], al
	inc ebx

	pusha
	invoke PutS, esi
	popa

jmp continue
;-------------------------------------------------

JumpTable        dd offset default_printf, offset B_printf, offset C_printf, offset D_printf, 
				  10 dup(offset default_printf), offset O_printf, 3 dup(offset default_printf),  
				offset S_printf, 4 dup(offset default_printf), X_printf, 2 dup(offset default_printf)

MyPrintf endp

;-------------------------------------------------
; converts and prints numbers
;=================================================
; Input  :  basis = basis of the system
;			 EDI  =       number  
;
; Output :  SI = offset to the first string symbol
;
;Destroys: DX, SE, SI
;-------------------------------------------------
.code
Format_Basis proc basis: word

	mov cx,    basis
	mov edx,    1d
	shl edx,    cl   
	lea edx, [edx - 1]

	l3:
		mov eax,  edi
		and eax,  edx
		shr edi,  cl
		
		mov al, byte ptr [offset HexTable + eax]
        mov byte ptr [esi], al
        dec esi
		
	cmp edi, 0h
	jne l3	

	inc ebx
	inc esi

	invoke PutS, esi

	ret
Format_Basis endp

;-------------------------------------------------
; converts and prints numbers
;=================================================
; Input  :  basis = basis of the system
;			 EDI  =       number  
;
; Output :  SI = offset to the first string symbol
;
;Destroys: DX, SE, SI
;-------------------------------------------------
.code
print_minus proc buffer: dword

	test edi, SIGN_BYTE

	jz skip
		xor eax, eax
		sub eax, edi
		mov edi, eax

		lea eax, [offset Char]
		mov byte ptr [eax], '-'

		pusha
		invoke PutS,  eax
		popa

	skip:

	ret
print_minus endp


end Start
