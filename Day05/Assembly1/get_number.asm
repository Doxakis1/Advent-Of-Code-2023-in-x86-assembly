; THis function needs eax to contain the address of the index of the string/buffer we want the number from
; returns on eax the number read and on ebx the number char length, on ecx 0 is return for success 1 for error
; does not affect esi

section .text
    global get_number

get_number:
    push ebp
    push esi
    mov ebp, esp
    sub esp, 16 ; original address, index, the number, the sign
    
    mov [esp], eax
    mov [esp+4], dword 0
    mov [esp+8], dword 0
    mov [esp+12], dword 1
    
check_negative:
    mov eax, [esp]
    lea esi, [eax]
    movzx ebx, byte  [esi]
    cmp ebx, '-'
    jne _get_first_digit
    mov [esp+12], dword -1
    mov [esp+4] , dword 1
_get_first_digit:
    mov ecx, [esp+4] ; index
    mov eax, [esp]
    lea esi, [eax + ecx]
    movzx ebx, byte [esi]
    cmp ebx, '0'
    jl _error
    cmp ebx, '9'
    jg _error
    sub ebx, '0'
    mov [esp+8], ebx
    inc ecx
    mov [esp+4], ecx
_get_number_loop:
    mov ecx, dword [esp+4]
    mov ebx, dword [esp]
    lea esi, [ebx + ecx]
    movzx ebx, byte [esi]
    cmp ebx, '0'
    jl _load_num
    cmp ebx, '9'
    jg _load_num
    sub ebx, '0'
    mov eax, [esp+8]
    imul eax, dword 10
    add eax, ebx
    mov [esp+8], eax
    inc ecx
    mov [esp+4], ecx
    jmp _get_number_loop
_load_num:
    mov eax, [esp+8]
    mov ecx, [esp+12]
    imul eax, ecx
    mov ecx, dword 0
    mov ebx, dword [esp+4]
    jmp _ret
_error:
    mov ecx, 1
_ret:
    mov esp, ebp
    pop esi
    pop ebp
    ret
