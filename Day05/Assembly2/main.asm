%define BUFFER_SIZE 1024
%define exit 1
%define read 3
%define write 4
%define open 5
%define close 6

extern get_next_line
extern get_number
extern fd_printnum
extern uint32_min
extern uint32_max

section .data
    filename db 'file.txt', 0
    newline db 10, 0
section .bss
    answer resd 1
    maps   resd 8
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

transform_seeds: 
    push ebp
    mov ebp, esp
    sub esp, 28 ; 7 ints
    mov [esp], dword 0
    mov [esp + 4], dword 0
    mov [esp + 8], dword 0
_get_next_range:
    mov ecx,dword [esp+4]
    mov edx,dword [s_num]
    cmp ecx, edx
    jae _transform_ret
    lea esi, [seeds + ecx * 4] ; lower limit
    inc ecx
    lea edi, [seeds + ecx * 4] ; upper limit
    mov eax, dword [esi]
    mov [esp+8], eax ; lower limit
    mov ebx, dword [edi]
    add eax, ebx
    mov [esp+12], eax ;upperlimit
    mov [esp+20], dword 0
    mov [esp+24], dword 4294967295
_get_next_value:
    mov eax, dword [esp+24]
    mov ebx, dword [answer]
    call uint32_min
    mov [answer], eax
    mov eax, dword  [esp+8]
    mov edx, dword [esp+20]
    add eax, edx
    mov edx, dword [esp+12]
    cmp eax, edx
    ja _inc_range
    mov [esp+8], eax
    mov [esp+24], eax
    mov [esp+16], dword 0
    mov [esp+20], dword 4294967295
_transform_loop:
    mov ebx, dword [esp+16]
    cmp ebx, 7
    ja _get_next_value
    mov eax, dword [esp+24]
    call pass_through_range
    mov [esp+24], eax
    mov ebx, dword [esp+16]
    inc ebx
    mov [esp+16], ebx
    mov ebx, ecx
    mov eax, dword [esp+20]
    call uint32_min
    mov [esp+20], eax
    jmp _transform_loop

_inc_range:
    mov ecx, dword [esp+4]
    add ecx, 2
    mov [esp+4], ecx
    jmp _get_next_range
_transform_ret:
    mov esp, ebp
    pop ebp
    ret

pass_through_range: ; this function needs the eax to hold the number we are testing and ebx to hold my array number
    push ebp
    mov ebp, esp
    sub esp, 16 ; 4 ints
    mov [esp], eax
    lea edx, [maps + ebx * 4]
    mov ecx, dword [edx]
    mov [esp+4], ecx ; holds start
    inc ebx
    lea edx, [maps + ebx * 4]
    mov ecx, dword [edx]
    mov [esp+8], ecx ; holds upperlimit
    mov [esp+12], dword 4294967295
_transform_num:
    mov ecx, dword [esp + 4]
    mov ebx, dword [esp + 8]
    cmp ecx, ebx
    jge _pass_through_range_ret
_try_ranges:
    mov ecx, dword [esp+4]
    lea edi, [array2 + ecx * 4]
    mov eax, dword [esp]
    mov ebx, dword [edi]
    cmp eax, ebx
    jae _passed_first
    sub ebx, eax
    mov eax, dword [esp+12]
    call uint32_min
    mov [esp+12], eax
    jmp _try_range_inc
_passed_first:
    sub eax, ebx
    lea edi, [array3 + ecx * 4]
    mov ebx, dword [edi]
    cmp eax, ebx
    ja _try_range_inc
    sub ebx, eax
    mov [esp+12], ebx
    lea edi, [array1 + ecx * 4]
    mov ebx, dword [edi]
    add eax, ebx
    mov [esp], eax
    jmp _pass_through_range_ret
_try_range_inc:
    mov ecx, [esp+4]
    inc ecx
    mov [esp+4], ecx
    jmp _transform_num
_pass_through_range_ret:
    mov ecx, dword [esp+12]
    cmp ecx, 0
    jne _not_zero
    inc ecx
_not_zero:
    mov eax, dword [esp]
    mov esp, ebp
    pop ebp
    ret

_start:
    pop ebp
    mov ebp, esp
    mov eax, dword -1
    mov [fd], eax
    sub esp, 16 ; 4 ints
    mov [esp+12], dword 1 ; holds curr map number
    mov [esp+8], dword 0
    mov [esp+4], dword 0
    mov [esp], dword 0
    mov [maps], dword 0
    mov [answer], dword 4294967295 ; unsigned int max
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
_map_done:
    jmp _get_next_map
_done:
    call transform_seeds
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
