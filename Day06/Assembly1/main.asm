%define exit 1
%define read 3
%define write 4
%define open 5
%define close 6
%define BUFFER_SIZE 1024
%define ARRAY_SIZE 4

extern get_next_line
extern get_number
extern fd_printnum

section .bss
    fd     resd 1
    asnwer resd 1
    race   resd 1
    time   resd ARRAY_SIZE
    distance resd ARRAY_SIZE
    buffer resb BUFFER_SIZE
section .data
    filename db 'file.txt', 0

section .text
    global _start

_start:
    mov [fd], dword -1

_open_file:
    mov eax, open
    mov ebx, filename
    mov ecx, 0
    mov edx, 0
    int 0x80
    cmp eax, 0
    jl  _exit

_read_file:
    mov eax, 42
    mov ebx, 1
    call fd_printnum


_close_file:
    mov eax, close
    mov ebx, dword [fd]
    int 0x80
_exit:
    mov eax, exit
    mov ebx, 0
    int 0x80
