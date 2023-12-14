section .bss
    list_ptr resd 1
    list_size resd 1
section .text
    global _start

_start:
    mov eax, 45 ;
    mov ebx, dword 1000000000
    int 0x80

    cmp eax, -1
    jle _error
    mov [list_ptr], eax
    lea ebx, [eax]
_loop:
    mov [ebx], byte 'a'
    dec ebx
    cmp ebx, 0
    jg _loop
    jmp _finish
_error:
    mov eax, 1
    mov ebx, 42
    int 0x80
_finish:
     mov eax, 1
     mov ebx, 0
     int 0x80
