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
    answer resd 1
    race   resd 1
    time   resd ARRAY_SIZE
    distance resd ARRAY_SIZE
    buffer resb BUFFER_SIZE
section .data
    filename db 'file.txt', 0

section .text
    global _start

update_answer:
    push ebp
    mov ebp, esp
    sub esp, 16 ; int[4]
    mov [esp+12], dword 0 ; winners
    mov [esp + 8], eax ; time
    mov [esp + 4], ebx ; current record
    mov [esp], dword 0 ; starting time
    
_update_answer_loop:
    mov eax, dword [esp]
    mov ebx, dword [esp+8]
    sub ebx, eax ; travel time
    cmp ebx, dword 0
    je _update_answer_ret
    xor edx, edx
    mul ebx
    mov edx, dword [esp+4]
    cmp eax, edx
    jle _inc_update_answer
    mov edx, dword [esp+12]
    inc edx
    mov [esp+12], edx
_inc_update_answer:
    mov ebx, dword [esp]
    inc ebx
    mov [esp], ebx
    jmp _update_answer_loop
_update_answer_ret:
    mov eax, dword [answer]
    xor edx, edx
    mov ecx, dword [esp+12]
    mul ecx
    mov [answer], eax
    mov esp, ebp
    pop ebp
    ret

_start:
    sub esp, 8 ; int[2]
    mov [fd], dword -1
    
_open_file:
    mov eax, open
    mov ebx, filename
    mov ecx, 0
    mov edx, 0
    int 0x80
    cmp eax, 0
    jl  _exit
    mov [fd], eax

_get_times:
    mov eax, dword [fd]
    mov ebx, buffer
    call get_next_line
    mov [esp], dword 5
    mov [esp+4], dword 0
_get_time_loop:
    mov ecx, dword [esp]
    lea esi, [buffer + ecx]
    movzx eax, byte [esi]
    cmp eax, dword ' '
    je _inc_get_times
    cmp eax, dword 0
    je _got_times
    mov eax, esi
    call get_number
    mov ecx, dword [esp]
    add ecx, ebx
    mov [esp], ecx
    mov ecx, dword [esp+4]
    lea edi, [time + ecx * 4]
    mov [edi], eax
    inc ecx
    mov [esp+4], ecx
_inc_get_times:
    mov ecx, dword [esp]
    inc ecx
    mov [esp], ecx
    jmp _get_time_loop 
_got_times:
    mov ecx, [esp+4]
    lea esi, [time + ecx *4]
    mov [esi], dword -1
_get_distances:
    mov eax, dword [fd]
    mov ebx, buffer
    call get_next_line
    mov [esp], dword 10
    mov [esp+4], dword 0
_get_distance_loop:
    mov ecx, dword [esp]
    lea esi, [buffer + ecx]
    movzx eax, byte [esi]
    cmp eax, dword ' '
    je _inc_get_distances
    cmp eax, dword 0
    je _got_distances
    mov eax, esi
    call get_number
    mov ecx, dword [esp]
    add ecx, ebx
    mov [esp], ecx
    mov ecx, dword [esp+4]
    lea edi, [distance + ecx * 4]
    mov [edi], eax
    inc ecx
    mov [esp+4], ecx
_inc_get_distances:
    mov ecx, dword [esp]
    inc ecx
    mov [esp], ecx
    jmp _get_distance_loop 
_got_distances:
    mov ecx, [esp+4]
    lea esi, [distance + ecx *4]
    mov [esi], dword -1

_calc_winners:
    mov [esp], dword 0
    mov [answer], dword 1
_calc_loop:
    mov ecx, dword [esp]
    lea esi, [time + ecx *4]
    mov eax, dword [esi]
    cmp eax, dword -1
    je _done
    lea edi, [distance + ecx *4]
    mov ebx, dword [edi]
    cmp ebx, dword -1
    je _done
    call update_answer
    mov ecx, dword [esp]
    inc ecx
    mov [esp], ecx
    jmp _calc_loop
_done:
    mov eax, dword [answer]
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
