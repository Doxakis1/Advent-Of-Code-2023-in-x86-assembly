; This day looks intimidating but actually might not be that bad
; My idea is to do the following logic

; Read one line of the file and get an array of all the seeds numbers

; Read into 3 buffers the all the numbers found on the maps such that number is as it is, number 2 is as it is and number 3 is number3 + number2 (upper limit of range),
; if I meet a line with no numbers I place a -1 on all numbers lists to signify map is over. If I run out of file I put -2 on all lists
; after I got all the numbers, for each number in the seeds I check it against the all numbers in numbers2 list, if seed number is above it, and below the number3, seed number will become number1+seed
; if I see an -1 I continue. However if I find a range and perform seed += number1, I will skip until the next -1 or -2. if I find -2, that seed is as its final form

; once all seeds have been found, I return the smallest one

%define exit 1
%define read 3
%define write 4
%define open 5
%define close 6
%define open_flags 0
%define open_mode 0
%define BUFFER_SIZE 1024

extern get_next_line
extern get_number
extern fd_printnum

section .data
    filename db 'file.txt', 0
section .bss
    fd    resd 1
    s_index resd 1
    index resd 1
    nums1 resd BUFFER_SIZE
    nums2 resd BUFFER_SIZE
    nums3 resd BUFFER_SIZE
    seeds resd BUFFER_SIZE
    buffer resb BUFFER_SIZE
section .text
    global _start

_start:
    push ebp
    mov ebp, esp
    sub esp, 4 ; index counter
    
    mov [esp], dword 0
    mov [fd], dword -1
    mov [index], dword  0
    mov [s_index], dword  0
_open_file:
    mov eax, open
    mov ebx, filename
    mov ecx, open_flags
    mov edx, open_mode
    int 0x80
    cmp eax, 0
    jl _exit
    mov [fd], eax
    lea ebx, [buffer]
    call get_next_line
    cmp eax, dword 0
    je _close_file ; error case
    mov [esp], dword 7 ; skip until the seed numbers
_get_all_seeds:
    mov ecx, dword [esp]
    lea eax, [buffer + ecx]
    call get_number
    cmp ecx, 1
    je _get_maps
    mov edx, dword [s_index]
    lea edi, [seeds + edx * 4]
    mov [edi], eax
    inc edx
    mov [s_index], edx
    mov ecx, dword [esp]
    add ecx, ebx
    inc ecx
    mov [esp], ecx
    jmp _get_all_seeds
_get_maps:
    mov edx, [s_index]
    lea edi, [seeds + edx * 4]
    mov [edi], dword -1
    mov [s_index], dword 0
    mov eax, dword [fd]
    lea ebx, [buffer]
    call get_next_line
    cmp eax, 0
    je _close_file ; error case
_get_next_map:
    mov eax, dword [fd]
    lea ebx, [buffer]
    call get_next_line
    cmp eax, 0
    je _got_maps ; done
_get_next_map_loop:
    mov eax, dword [fd]
    lea ebx, [buffer]
    call get_next_line
    cmp eax, 1 ; found only line so we are done with this
    jle _get_next_map_end
    mov [esp], dword 0
_get_next_map_numbers:
    mov ecx, dword [esp]
    lea eax, [buffer + ecx]
    call get_number
    cmp ecx, 1
    je _close_file ; error
    mov edx, dword [index]
    lea edi, [nums1 + edx * 4]
    mov [edi], eax
    mov ecx, dword [esp]
    add ecx, ebx
    inc ecx
    mov [esp], ecx
    lea eax, [buffer + ecx]
    call get_number
    cmp ecx, 1
    je _close_file ; error
    mov edx, dword [index]
    lea edi, [nums2 + edx * 4]
    mov [edi], eax
    mov ecx, dword [esp]
    add ecx, ebx
    inc ecx
    mov [esp], ecx
    lea eax, [buffer + ecx]
    call get_number
    cmp ecx, 1
    je _close_file ; error
    mov ebx, dword [edi]
    mov edx, dword [index]
    lea edi, [nums3 + edx * 4]
    add eax, ebx
    mov [edi], eax
    inc edx
    mov [index], edx
    jmp _get_next_map_loop
_get_next_map_end:
    mov edx, dword [index]
    lea edi, [nums1 + edx * 4]
    mov [edi], dword -1
    lea edi, [nums2 + edx * 4]
    mov [edi], dword -1
    lea edi, [nums3 + edx * 4]
    mov [edi], dword -1
    inc edx
    mov [index], edx
    jmp _get_next_map

_got_maps:
    mov edx, dword [index]
    lea edi, [nums1 + edx * 4]
    mov [edi], dword -2
    lea edi, [nums2 + edx * 4]
    mov [edi], dword -2
    lea edi, [nums3 + edx * 4]
    mov [edi], dword -2
    mov [index], dword 0
    jmp _transform_seeds

_transform_seeds:
    mov edx, dword [s_index]
    lea edi, [seeds+edx * 4]
    mov eax, dword [edi]
    cmp eax, dword -1
    je _find_smallest
    mov [index], dword  0
    mov [esp], eax
_transform_per_map:
    mov edx, [index]
    lea edi, [nums2 + edx * 4]
    mov eax, dword [edi]
    cmp eax, dword -2
    jne _continue
    mov ebx, dword [esp]
    mov edx, dword [s_index]
    lea edi, [seeds+edx*4]
    mov [edi], ebx
    inc edx
    mov [s_index], edx
    jmp _transform_seeds
_continue:
    cmp eax, dword -1
    je _transform_loop_next_iter
    mov ebx, dword [esp]
    cmp ebx, eax
    jl _transform_loop_next_iter
    mov edx, dword [index]
    lea edi, [nums3 + edx * 4]
    mov eax, dword [edi]
    cmp ebx, eax
    jg _transform_loop_next_iter
    jmp _found_place

_transform_loop_next_iter:
    mov edx, dword [index]
    inc edx
    mov [index], edx
    jmp _transform_per_map

_found_place:
    mov edx, dword [index]
    lea edi, [nums2 + edx * 4]
    mov ebx, dword [esp]
    mov eax, dword [edi]
    sub ebx, eax
    lea edi, [nums1 + edx * 4]
    mov eax, dword [edi]
    add eax, ebx
    mov [esp], eax
_find_end:
    lea edi, [nums1 + edx * 4]
    mov eax, dword [edi]
    cmp eax, 0
    jl _found_end
    inc edx
    jmp _find_end
_found_end:
    mov [index], edx
    jmp _transform_per_map

_find_smallest:
    mov [esp], dword 2147483647 ; int max
    mov ecx, dword 0
_find_smallest_loop:
    lea edi, [seeds + ecx * 4]
    mov eax, dword [edi]
    cmp eax, -1
    je _close_file
    inc ecx
    mov ebx, dword [esp]
    cmp eax, ebx
    jge _find_smallest_loop
    mov [esp], eax
    jmp _find_smallest_loop

_close_file:
    mov eax, dword [esp]
    mov ebx, dword 1
    call fd_printnum
    lea esi, [seeds]
    mov eax, close
    mov ebx, [fd]
    int 0x80
_exit:
    mov esp, ebp
    pop ebp
    mov eax, exit
    mov ebx, 0
    int 0x80
    

