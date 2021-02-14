AStack    SEGMENT  STACK
          DW 128 DUP(?)   
AStack    ENDS

DATA  SEGMENT
   T_PC db  'Type: PC', 0DH, 0AH,'$'
   T_XT db 'Type: PC/XT', 0DH, 0AH,'$'
   T_AR db  'Type: AT', 0DH, 0AH,'$'
   TPS2_30 db 'Type: PS2 модель 30', 0DH, 0AH,'$'
   TPS2_80 db 'Type: PS2 модель 80', 0DH, 0AH,'$'
   T_JR db 'Type: PСjr',0DH,0AH,'$'
   T_CONV db 'Type: PC Convertible', 0DH, 0AH,'$'

   VERSIONS db 'Version MS-DOS:  .  ', 0DH, 0AH,'$'
    N_SERIAL db  'Serial number OEM:  ', 0DH, 0AH,'$'
   N_USER db  'User serial number:       H $'

DATA ENDS

CODE SEGMENT
   ASSUME CS:CODE,DS:DATA,SS:AStack
   ; Процедуры
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL, 0Fh
   cmp AL, 09
   jbe next
   add AL, 07
next:
   add AL, 30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шест. числа в AX
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младшая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
   push CX
   push DX
   push SI
   xor AH,AH
   xor DX,DX
   mov CX,10
   
loop_bd:
   div CX
   or DL,30h
   mov [SI],DL
   dec SI									
   xor DX,DX
   cmp AX,10
   jae loop_bd
   cmp AL,00h
   je end_l
   or AL,30h
   mov [SI],AL
end_l:
	pop SI
   pop DX
   pop CX
   
   ret
BYTE_TO_DEC ENDP


;__________________Code____________________

;___Print on display_______
PRINT PROC near
   mov AH,09h
   int 21h
   ret
PRINT ENDP



;____Comparison of data with the table about the version of the computer______
FIND_INFO_PC PROC near
   mov ax, 0f000h ; get information about the computer model
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh ; We start comparing with the data from the table
	je write_t_pc

	cmp al, 0feh
	je write_t_xt

	cmp al, 0fbh
	je write_t_xt

	cmp al, 0fch
	je write_t_at

	cmp al, 0fah
	je write_tps2_m30

	cmp al, 0f8h
	je write_tps2_m80

	cmp al, 0fdh
	je write_t_jr

	cmp al, 0f9h
	je write_t_conv

write_t_pc:
	mov dx, offset T_PC
	jmp writer
write_t_xt:
	mov dx, offset T_XT
	jmp writer
write_t_at:
	mov dx, offset T_AR
	jmp writer
write_tps2_m30:
	mov dx, offset TPS2_30
	jmp writer
write_tps2_m80:
	mov dx, offset TPS2_80
	jmp writer
write_t_jr:
	mov dx, offset T_JR
	jmp writer
write_t_conv:
	mov dx, offset T_CONV
	jmp writer

	;Helps avoid duplication "ret"
writer:
	call PRINT
	ret
FIND_INFO_PC ENDP


;_______We look at the OS version______
FIND_OS_VERSION PROC near
	mov ah, 30h
	int 21h
	push ax
	
	mov si, offset VERSIONS
	add si, 16
	call BYTE_TO_DEC
   pop ax
   mov al, ah
   add si, 2
	call BYTE_TO_DEC
	mov dx, offset VERSIONS
	call PRINT
   
   
	mov si, offset N_SERIAL
	add si, 19
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset N_SERIAL
	call PRINT
	
	mov di, offset N_USER
	add di, 25
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset N_USER
	call PRINT
	ret
FIND_OS_VERSION ENDP

Main PROC FAR
   sub   AX,AX
   push  AX
   mov   AX,DATA
   mov   DS,AX
   call FIND_INFO_PC
   call FIND_OS_VERSION
   xor AL,AL
   mov AH,4Ch
   int 21H

Main ENDP
CODE ENDS
      END Main