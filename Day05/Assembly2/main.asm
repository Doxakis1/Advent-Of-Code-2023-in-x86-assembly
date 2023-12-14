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
    newline db 10, 0
section .bss
    maps   resd 7
    fd     resd 1
    buffer resb BUFFER_SIZE
    s_num  resd 1
    seeds  resd BUFFER_SIZE
    s_arr  resd 1
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
    sub esp, 16 ; 4 ints
    mov [esp+12], dword 0 ; holds curr map number
    mov [esp+8], dword 0
    mov [esp+4], dword 0
    mov [esp], dword 0
_open_file:
    mov eax, open
    mov ebx, filename
    mov ecx, dword 0
    mov edx, dword 0
    int 0x80
    cmp eax, 0
    jl _exit
    mov [fd], eax
_get_seeds:
    mov eax, dword [fd]
    lea ebx, [buffer]
    call get_next_line
    cmp eax, 8
    jl _close_file ; error since "seeds: n" is atleast 8 chracters
    mov [s_num], dword 0
    mov [esp], dword 7 ; index = 7 to skip the "seeds: "
_get_next_num_loop:
    mov ecx, dword [esp]
    lea eax, [buffer + ecx]
    call get_number
    cmp ecx, dword 1
    je _close_file ; error since this means we found a character other than number
_found_seed:
    mov ecx, dword [s_num]
    lea edi, [seeds + ecx * 4]
    mov [edi], eax
    inc ecx
    mov [s_num], ecx
_move_cursor:
    mov ecx, dword [esp]
    add ecx, ebx
    inc ecx
    mov [esp], ecx
    lea eax, [buffer + ecx]
    movzx ebx, byte [eax]
    cmp ebx, dword 0
    jne _get_next_num_loop
_got_seeds:
    mov eax, dword [fd]
    lea ebx, [buffer]
    call get_next_line
    cmp eax, 1
    jne _close_file ; this line should only have a \n char


_get_next_map:
    mov eax, dword [fd]
    lea ebx, [buffer]
    call get_next_line
    cmp eax, 1
    jle _done ; this line should only have the map key
    ; mov [s_arr], dword 0
_get_next_map_line:
    mov eax, dword [fd]
    lea ebx, [buffer]
    call get_next_line
    cmp eax, 1
    jle _got_map
_get_map_values:
    mov edx, dword 0
    lea eax, [buffer + edx]
    call get_number
    cmp ecx, 1
    je _close_file ; error case
    mov ecx, dword [s_arr]
    lea edi, [array1 + ecx * 4]
    mov [edi], eax
    add edx, ebx
    inc edx
    lea eax, [buffer + edx]
    call get_number
    cmp ecx, 1
    je _close_file ; error case
    mov ecx, dword [s_arr]
    lea edi, [array2 + ecx * 4]
    mov [edi], eax
    add edx, ebx
    inc edx
    lea eax, [buffer + edx]
    call get_number
    cmp ecx, 1
    je _close_file ; error case
    mov ecx, dword [s_arr]
    lea edi, [array3 + ecx * 4]
    mov [edi], eax
    inc ecx
    mov [s_arr], ecx
    jmp _get_next_map_line
_got_map:
    mov eax, dword [s_arr]
    mov ecx, dword [esp+12]
    lea edi, [maps + ecx * 4]
    mov [edi], eax
    inc ecx
    mov [esp+12], ecx
    ;mov [esp], dword 0
;_tranform_nums:
;   mov ecx, dword [esp]
;    mov ebx, dword [s_num]
;    cmp ecx, ebx
;    jge _map_done
;    lea edi, [seeds + ecx * 4]
;    mov eax, dword [edi]
;    mov [esp+4], eax
;    mov [esp+8], dword 0
;_try_ranges: 
;    mov ecx, dword [esp+8]
;    mov ebx, dword [s_arr]
;    cmp ecx, ebx
;    jge _got_map_loop_inc
;    lea edi, [array2 + ecx * 4]
;    mov eax, dword [edi]
;    mov ebx, dword [esp+4]
;    cmp ebx, eax
;    jb _try_range_inc
;    sub ebx, eax
;    lea edi, [array3 + ecx * 4]
;    mov eax, dword [edi]
;    cmp ebx, eax
;    ja _try_range_inc
;    lea edi, [array1 + ecx * 4]
;    mov eax, dword [edi]
;    mov ecx, [esp]
;    lea esi, [seeds + ecx * 4]
;    add ebx, eax
;    mov [esi], ebx
;    jmp _got_map_loop_inc
;_try_range_inc:
;    mov ecx, dword [esp+8]
;    inc ecx
;    mov [esp+8], ecx
;    jmp _try_ranges
;_got_map_loop_inc:
;    mov ecx, dword [esp]
;    inc ecx
;    mov [esp], ecx
;    jmp _tranform_nums
_map_done:
    jmp _get_next_map
_done:
    mov eax, [esp+12]
    mov ebx, dword 1 
    call fd_printnum
    mov eax, dword  4
    mov ebx, dword 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    xor ecx, ecx
_print_loop:
    lea esi, dword[maps + ecx * 4]
    mov eax, dword  [esi]
    mov ebx, 1
    push ecx
    call fd_printnum
    mov eax, dword  4
    mov ebx, dword 1
    mov ecx, newline
    mov edx, 1
    int 0x80
    pop ecx
    inc ecx
    cmp ecx, 7
    jb _print_loop
;    mov [esp+4], dword 4294967295 ; unsigned int max
;    mov [esp], dword 0
;    lea esi, [seeds]
;_find_smallest:
;    mov ecx, dword [esp]
;    mov ebx, dword [s_num]
;    cmp ecx, ebx
;    jge _found_smallest
;    inc ecx
;    mov [esp], ecx
;    dec ecx
;    lea esi, [seeds + ecx * 4]
;    mov eax, dword [esi]
;    mov ebx, dword [esp+4]
;    cmp eax, ebx
;    ja _find_smallest
;    mov [esp+4], eax
;    jmp _find_smallest
;_found_smallest:
;    mov eax, [esp+4]
;    mov ebx, 1
;    call fd_printnum
_close_file:
    mov eax, close
    mov ebx, dword [fd]
    int 0x80
_exit:
    mov eax, exit
    mov ebx, 0
    int 0x80
