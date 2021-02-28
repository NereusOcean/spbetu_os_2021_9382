testpc segment
    assume cs:testpc,ds:testpc,es:nothing,ss:nothing
    org 100h

start: jmp main

env_addr        db  'Environment address:', '$'
unavailable     db  'Unavailable memory:', '$'
ax_register     db  '      ', 0dh,0ah,'$'
ENV             db  'Environment content: ', '$'
NEW_LINE        db  0dh,0ah,'$'
PATH            db 'PATH is: ', '$'
ZERO_ARGUMENTS  db  ' nothing!', 0dh,0ah, 0dh,0ah,'$'
TAIL_ARGUMENTS  db  'Argument/tail is: ', '$'

tetr_to_hex proc near
    and al,0fh
    cmp al,09
    jbe next
    add al,07

next:
    add al,30h
    ret
tetr_to_hex endp

byte_to_hex proc near
    push cx
    mov ah,al
    call tetr_to_hex
    xchg al,ah
    mov cl,4
    shr al,cl
    call tetr_to_hex
    pop cx
    ret
byte_to_hex endp

wrd_to_hex proc near
    push bx
    mov bh,ah
    call byte_to_hex
    mov [di],ah
    dec di
    mov [di],al
    dec di
    mov al,bh
    call byte_to_hex
    mov [di],ah
    dec di
    mov [di],al
    pop bx
    ret
wrd_to_hex endp

Byte_to_dec proc near
    push si
    push cx
    push dx
    xor ah,ah
    xor dx,dx
    mov cx,10

loop_bd:
    div cx
    or dl,30h
    mov [si],dl
    dec si
    xor dx,dx
    cmp ax,10
    jae loop_bd
    cmp al,00h
    je end_l
    or al,30h
    mov [si],al

end_l:
    pop dx
    pop cx
    pop si
    ret
Byte_to_dec endp
;///////////////////////////////
;/////////_Code_///////////////
;//////////////////////////////
Writestring proc near
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
Writestring endp


NULLString proc near
    push si
    push cx

    xor si,si
    mov cx,5

Clear:
    mov [offset ax_register+si],0ff20h
    inc si
    loop Clear

    mov [offset ax_register+si],0ff20h
    pop cx
    pop si
    ret
NULLString endp


Display_info proc near
    call writestring
    mov di,offset ax_register
    add di,5
    call wrd_to_hex
    mov dx,offset ax_register
    call writestring
    call NULLString
    ret
Display_info endp


Display_UnMem proc near
    mov dx,offset unavailable
    mov ax,ds:[02h]
    call Display_info
    ret
Display_UnMem endp


Print_env_addr proc near
    mov dx,offset env_addr
    mov ax,ds:[2ch]
    call Display_info
    ret
Print_env_addr endp


Display_command_tail proc near
    push cx
    push ax
    xor cx,cx

    mov dx,offset TAIL_ARGUMENTS
    call writestring

   
    mov cl,ds:[80h]
    cmp cl,0
    je _empty_tail

    mov si,0

Display_tail_symbol:
    mov dl,ds:[81h+si]
    mov ah,02h
    int 21h
    inc si
    loop Display_tail_symbol

    mov dx,offset NEW_LINE
    call writestring

    jmp _exit_tail_print

_Empty_tail:
    mov dx,offset ZERO_ARGUMENTS
    call writestring


_Exit_tail_print:
    pop ax
    pop cx
    ret
Display_command_tail endp


Print_environment proc near
    push dx
    push ax
    push si
    push ds

    xor si,si

    mov dx,offset ENV
    call writestring

    mov ds,ds:[2ch]

_Read_env:
    mov dl,[si]
    cmp dl,0
    je _eof

    mov ah,02h
    int 21h

    inc si
    jmp _read_env

_Eof:
    inc si
    mov dl,[si]
    cmp dl,0
    je _end_reading_env

    pop ds
    mov dx,offset NEW_LINE
    call writestring
    push ds
    mov ds,ds:[2ch]

    jmp _read_env

_End_reading_env:
    pop ds
    mov dx,offset NEW_LINE
    call writestring

    mov dx,offset PATH
    call writestring
    push ds
    mov ds,ds:[2ch]

    add si,3

_Reading_path:
    mov dl,[si]
    cmp dl,0
    je _exit_print_env

    mov ah,02h
    int 21h
    inc si
    jmp _reading_path


_Exit_print_env:
    pop ds
    pop si
    pop ax
    pop dx
    ret
Print_environment endp


main:
    call Display_UnMem
    call print_env_addr
    call Display_command_tail
    call print_environment
    xor al,al
    mov ah,4ch
    int 21h


testpc ends
end start