; This days part one looks simple
;
; My strategy:
; Read the line until '|' and store every number I meet in an array of numbers
; after that every number after '|' I check if it exists in the array
; if yes I incrementi/double the counter of hits for that scratch. if I meet 'n' I add 
; to the sum the number of the line and reset everything

%define BUFFER_SIZE 1024
%define NUM_ARRAY_SIZE 100

section .data
    filename db 'file.txt', 0
section .bss
    fd      resd 1
    numbers resd NUM_ARRAY_SIZE ; I can use more if I see fit
    sum     resd 1
    g_sum   resd 1 ; game sum
    buffer  resb BUFFER_SIZE ; I can increase if needed
section .text
    global _start

_getNum: ;requires correct index on esi, returns the number on eax if it is a number else -1, and returns on ebx the index incriment
    push ebp
    mov ebp, esp
    sub esp, 12 ; three dwords
    
    xor eax, eax
    mov [esp+8], esi ; start index
    mov eax, -1
    mov [esp+4], eax ; number
    xor ecx, ecx
    mov [esp], ecx ; index
_check_ifnum:
    mov ecx, [esp]
    movzx ebx, byte [esi]
    cmp ebx, '0'
    jl _notNum
    cmp ebx, '0'
    jg _notNum
_isNum:
    mov ecx, [esp]
    mov edx, [esp+8]
    lea esi, [ecx + edx]
    movzx ebx, byte [esi]
    cmp ebx, '0'
    jl _getNum_ret
    cmp ebx, '9'
    jg _getNum_ret
    inc ecx
    mov [esp], ecx
    mov eax, [esp+4]
    mov ecx, 10
    xor edx, edx
    mul ecx
    sub ebx, '0'
    add eax, ebx
    mov [esp+4], eax
    jmp _isNum
_notNum:
    mov [esp], dword 1
_getNum_ret:
    mov ebx, [esp]
    mov eax, [esp+4]
    mov esp, ebp
    pop ebp
    ret
_start:
    pop ebp
    mov ebp, esp
    sub esp, 8 ; int index, char holder[4]

_open_file:
    mov eax, 5 ; sys_call open
    mov ebx, filename ; char *
    mov ecx, 0 ; readonly
    mov edx, 0 ; optional mode flag 
    int 0x80
    cmp eax, 0
    jl _exit ; failed to open
    mov [fd], eax

_init:
    mov [esp], dword 0
    mov [esp + 4] , dword 0
_init_buffer:
    mov ecx, [esp + 4]
_initialize_buffer_loop:
    cmp ecx, BUFFER_SIZE
    jge _init_numbers
    lea esi, [buffer + ecx]
    mov [esi], dword 0
    add ecx, 4
    jmp _initialize_buffer_loop
_init_numbers:
    xor ecx, ecx
_init_numbers_loop:
    cmp ecx, NUM_ARRAY_SIZE
    jge _find_start
    lea esi, [numbers + ecx]
    mov [esi], dword -1
    add ecx, 4
    jmp _init_numbers_loop
_find_start:
    mov eax, 3 ; sys_call read
    mov ebx, [fd] ; int fd
    mov ecx, esp ; char *buf
    mov edx, 1 ; readsize
    cmp eax, 0 ; at the end of file
    jle _close_file
    movzx eax, byte [esp]
_check_eax:
    cmp eax, ':'
    je _get_nums ; found start
    jmp _find_start
_get_nums:
    xor ecx, ecx
    mov [esp + 4], ecx
_get_nums_loop:
    mov ecx, [esp+4]
    lea esi, [buffer + ecx]
    mov eax, 3 ; sys_call read
    mov ebx, [fd] ; int fd
    mov ecx, esi
    mov edx, 1 ; readsize
    cmp eax, 0 ; at the end of file/error
    jle _close_file
    cmp eax, '|' ; end of nums
    jmp _get_num_array
    mov ecx, [esp+4]
    inc ecx
    mov [esp+4], ecx
    jmp _get_nums_loop
_get_num_array:
    mov ecx, ecx
    mov [esp+4], ecx ; number counter
    mov [esp], ecx ; index counter
_get_next_num:
    mov ecx, dword [esp]
    lea esi, [buffer + ecx]
    movzx ebx, byte [esi]
    cmp ebx, 0 
    je _close_file ; end of scratch line now get numbers next
    getNum
    add ecx, ebx
    mov [esp], ecx
    cmp eax, -1
    je _get_next_num
    mov ecx, dword [esp+4]
    lea esi, [numbers + ecx * 4] 
    mov [esi], eax
    inc ecx
    mov [esp+4], ecx
    jmp _get_next_num

_close_file:
    mov edx, dword [esp+4]
    mov eax, 6 ; sys_call close
    mov ebx, [fd] ; close arg
    int 0x80

_exit:
    mov esp, ebp
    pop ebp
    mov eax, 1 ; sys_exit
    mov ebx, edx ; exit_code
    int 0x80
