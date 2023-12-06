; This function reads the next line of an fd into a buffer provided by the caller
; Fd is passed by eax and location of buffer by ebx
; It inserts the NUL terminated string on the buffer and returns on eax the string length

%define read 3

section .text
    global get_next_line

get_next_line:
    push ebp
    mov ebp, esp
    sub esp, 16 ; fd, index,  char *dst

    mov [esp], eax
    mov [esp+4], dword 0
    mov [esp+8], ebx
_read_loop:
    mov eax, read
    mov ebx, dword [esp+8]
    mov edx, dword [esp+4]
    lea ecx, [ebx + edx] ; buffer + index
    mov ebx, [esp] ; fd 
    mov edx, dword 1
    int 0x80
    cmp eax, 0
    je _ret
    movzx ebx, byte [ecx]
    mov edx, dword [esp+4]
    inc edx
    mov [esp+4], edx
    cmp ebx, 10
    je _ret
    jmp _read_loop
_ret:
    mov edx, [esp+4]
    mov ebx, [esp+8]
    lea esi, [edx + ebx]
    mov [esi], byte 0
    mov eax, edx
    mov esp, ebp
    pop ebp
    ret
