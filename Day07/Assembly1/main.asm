extern fd_printnum
extern reserve_init
section .data
    filename db 'file.txt'
section .text
    global _start


_start:
    call reserve_init
_exit:
    mov eax, 1
    mov ebx, 0
    int 0x80
