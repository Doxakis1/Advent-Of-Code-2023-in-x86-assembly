extern fd_printnum

section .data
    filename db 'file.txt'
section .bss
    original_brk resd 1
section .text
    global _start


_start:
    mov eax, 45
    mov ebx, 0
    int 0x80
    
    mov [original_brk], eax
    add eax, 45
    mov ebx, eax
    mov eax, 45
    int 0x80
    mov ebx, 1
    call fd_printnum
    mov eax, dword [original_brk]
    lea esi, [eax]
    mov [esi], dword 1
    
_exit:
    mov eax, 1
    mov ebx, 0
    int 0x80
