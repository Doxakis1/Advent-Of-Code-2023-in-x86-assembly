; prints the number held by eax, to the fd held by ebx
; in case of error, returns a value less or equal to 0 on eax
; otherwise returns 1

%define write 4

section .text
    global fd_printnum

fd_printnum:
    push ebp
    mov ebp, esp
    sub esp, 16 ; 3 ints, 1 byte to check if I should print, 2 useless and one to store char c
    mov [esp], eax ; num
    mov [esp+4], dword 1000000000 ; max significant 32bit int
    mov [esp+8], ebx ; fd

    cmp eax, 0
    jge _find_first_digit
    mov [esp + 12], dword '-'
    add eax, dword 1 ; takes care of int_min case
    imul eax, dword -1
    inc eax
    mov [esp], eax
    jmp _write_digit
_find_first_digit:
    mov eax, dword [esp]
    mov ecx, dword [esp+4]
    cmp ecx, dword 1
    jle _get_next_digit ; in case number is 1 digit
    xor edx, edx
    div ecx
    cmp eax, 0
    jg _get_next_digit ; ready to print
    mov eax, ecx
    xor edx, edx
    mov ecx, 10
    div ecx
    mov [esp+4], eax ;next divisor
    jmp _find_first_digit
_get_next_digit:
    mov eax, dword [esp]
    mov ecx, dword [esp+4]
    cmp ecx, dword 0
    jle _success
    xor edx, edx
    div ecx
    mov [esp], edx ; remainder
    add eax, dword '0'
    mov [esp+12], eax
    mov eax, ecx
    xor edx, edx
    mov ecx, 10
    div ecx
    mov [esp+4], eax ; next divider
_write_digit:
    mov eax, write
    mov ebx, dword [esp+8]
    lea ecx, [esp+12]
    mov edx, dword 1
    int 0x80
    cmp eax, 0
    jle _ret
    mov ebx, dword [esp+12]
    cmp ebx, '-'
    je _find_first_digit
    jmp _get_next_digit
_success:
    mov eax, dword 1
_ret:
    mov esp, ebp
    pop ebp
    ret
