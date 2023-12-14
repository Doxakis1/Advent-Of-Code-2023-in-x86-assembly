
%define BUFFER_SIZE 1024
%define exit 1
%define read 3
%define write 4
%define open 5
%define close 6

extern get_next_line
extern get_number
extern fd_printnum


section .data
    filename db 'file.txt', 0
section .bss
    fd     resd 1
    buffer resb BUFFER_SIZE
    array1 resd BUFFER_SIZE
    array2 resd BUFFER_SIZE 
    array3 resd BUFFER_SIZE

section .text
    global _start

_start:
    pop ebp
    mov ebp, esp
    mov eax, dword -1
    mov [fd], eax

_open_file:
    mov eax, open
    mov ebx, filename
    mov ecx, dword 0
    mov edx, dword 0
    int 0x80
    cmp eax, 0
    jl _exit
    mov ebx, 1
    mov [fd], eax
    call fd_printnum


_close_file:
    mov eax, close
    mov ebx, dword [fd]
    int 0x80
_exit:
    mov eax, exit
    mov ebx, 0
    int 0x80
