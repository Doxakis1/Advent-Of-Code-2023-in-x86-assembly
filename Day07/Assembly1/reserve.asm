%define RESERVE_SIZE_INITIAL 524288 ; 2^19
%define sys_brk 45
section .bss
    brk_vals resd 2
    head_chunck resd 2
section .text
    global reserve_init
    global reserve
    global free

reserve_init: ; returns 0 on success and -1 for errors
    push ebp
    mov ebp, esp

_get_original_brk:
    mov eax, sys_brk
    mov ebx, 0
    int 0x80
    jc _reserve_init_error ; if error occurs carry flag is set
    lea esi, [brk_vals]
    mov [esi], eax ; original brk
_reserve_init_block:
    add eax, dword RESERVE_SIZE_INITIAL
    mov ebx, eax
    mov eax, sys_brk
    int 0x80
    jc _reserve_init_error
    lea esi, [brk_vals + 4]
    mov [esi], ebx
    lea esi, [head_chunck + 4]
    mov [esi], dword RESERVE_SIZE_INITIAL
    sub esi, 4
    mov eax, dword [brk_vals]
    mov [esi], eax
    mov eax, dword 0
    jmp _reserve_init_ret
_reserve_init_error:
    mov eax, dword -1
_reserve_init_ret:
    mov esp, ebp
    pop ebp
    ret
