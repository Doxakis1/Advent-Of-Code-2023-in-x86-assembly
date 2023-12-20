; takes two numbers on eax, and ebx
; returns value on eax

section .text
    global uint32_min

uint32_min:
    cmp eax, ebx
    jbe _uint32_min_ret
    mov eax, ebx
_uint32_min_ret:
    ret

uint32_max:
    cmp eax, ebx
    jae _uint32_max_ret
    mov eax, ebx
_uint32_max_ret:
    ret

int32_min:
    cmp eax, ebx
    jle _uint32_min_ret
    mov eax, ebx
_int32_min_ret:
    ret

int32_max:
    cmp eax, ebx
    jge _uint32_min_ret
    mov eax, ebx
_int32_max_ret:
    ret
