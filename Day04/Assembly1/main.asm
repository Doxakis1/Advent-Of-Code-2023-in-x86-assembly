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
printnum: ; Number inside eax register
    ;prologue
    push ebp
    mov ebp, esp
    sub esp, 16 ; int array[4]
    mov [esp + 12],dword eax ; move the number we want to print to array[3]
    mov [esp + 8], dword 1000000000 ; array[2] = 1000000000 (this is biggest printed signed decimal significant)
    mov [esp + 4], dword 0 ; array[1] = 0;
    mov [esp],dword 0 ; array[0] = 0
    
_printnum_loop:
    mov eax, [esp + 4]
    cmp eax, -1
    je _exit_printnum
    xor edx, edx ; zero the remainder
    mov ebx, [esp + 8] ; load divisor array[2] to ebx
    cmp ebx, 1
    je print_last
    mov eax, [esp + 12] ; load array[3] to eax
    mov ebx, [esp + 8]
    div ebx ; devide eax by ebx
    mov [esp + 12], edx ; move remainder to array[3]
    mov [esp], eax ; load significant digit to array[0]
    mov eax, [esp + 8] ; move the divisor to eax
    xor edx, edx
    mov ebx, 10
    div ebx
    mov [esp + 8], eax
    mov eax, [esp] ; load the number to eax
    add [esp + 4], eax ;using this to check that we never just print zeros
    mov eax, [esp + 4]
    test eax, eax
    jne print_num
    jmp _printnum_loop
print_last:    
    mov eax, [esp+12] ; move number to eax
    mov [esp], eax ; move to array[0] our num
    mov [esp + 4], dword -1
print_num:
    add [esp], dword '0'

    mov eax, 4 ; syscall to write
    mov ebx, 1 ; stdout
    lea ecx, [esp] ; load array[0]
    mov edx, 1 ; one char
    int 0x80

    jmp _printnum_loop
    ;epilogue
_exit_printnum:
    mov [esp], dword 10

    mov eax, 4 ; syscall to write
    mov ebx, 1 ; stdout
    lea ecx, [esp] ; load array[0]
    mov edx, 1 ; one char
    int 0x80

    mov esp, ebp
    pop ebp
    ret
_getNum: ;requires correct index on esi, returns the number on eax if it is a number else -1, and returns on ebx the index incriment
    push ebp
    mov ebp, esp
    sub esp, 12 ; three dwords
    
    xor eax, eax
    mov [esp+8], esi ; start index
    xor ecx, ecx
    mov [esp], ecx ; index
_check_ifnum:
    mov ecx, [esp]
    movzx ebx, byte [esi]
    cmp ebx, '0'
    jl _notNum
    cmp ebx, '9'
    jg _notNum
    mov [esp+4], dword 0
_isNum:
    mov ecx, [esp]
    mov edx, [esp+8]
    lea esi, [ecx + edx]
    movsx ebx, byte [esi]
_check_ebx:
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
added:
    jmp _isNum
_notNum:
    mov [esp], dword 1
    mov eax, -1
    mov [esp+4], eax
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
    mov [sum], dword 0
    mov [esp], dword 0
    mov [esp + 4] , dword 0
_repeat:
    mov ecx, [esp + 4]
_initialize_buffer_loop:
    cmp ecx, BUFFER_SIZE
    jge _init_numbers
    lea esi, [buffer + ecx]
    mov [esi], byte 0
    inc ecx
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
    int 0x80
    cmp eax, 0 ; at the end of file
    jle _close_file
    movzx eax, byte [esp]
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
    int 0x80
    cmp eax, 0 ; at the end of file/error
    jle _close_file
    movzx eax, byte [esi]
    cmp eax, '|' ; end of nums
    je _get_num_array
    mov ecx, [esp+4]
    inc ecx
    mov [esp+4], ecx
    jmp _get_nums_loop
_get_num_array:
    xor ecx, ecx
    mov [esp+4], ecx ; number counter
    mov [esp], ecx ; index counter
_get_next_num:
    mov ecx, dword [esp]
    lea esi, [buffer + ecx]
    movzx ebx, byte [esi]
    cmp ebx, 0 
    je _check_wins ; end of scratch line now get numbers next
    push ecx
    call _getNum
    pop ecx
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
_check_wins:
    xor ecx, ecx
    mov [esp + 4], ecx
_get_win_loop:
    mov ecx, [esp+4]
    lea esi, [buffer + ecx]
    mov eax, 3 ; sys_call read
    mov ebx, [fd] ; int fd
    mov ecx, esi
    mov edx, 1 ; readsize
    int 0x80
    cmp eax, 0 ; at the end of file/error
    jle _get_win_array
    movzx eax, byte [esi]
    cmp eax, 10 ; end of winnums
    je _get_win_array
    mov ecx, [esp+4]
    inc ecx
    mov [esp+4], ecx
    jmp _get_win_loop
_get_win_array:
    xor ecx, ecx
    mov [esp+4], ecx ; wins counter
    mov [esp], ecx ; index counter
_get_win_num:
    mov ecx, dword [esp]
    lea esi, [buffer + ecx]
    movzx ebx, byte [esi]
    cmp ebx, 0 
    je _add_wins ; end of scratch line now get numbers next
    push ecx
    call _getNum
    pop ecx
    add ecx, ebx
    mov [esp], ecx
    cmp eax, -1
    je _get_win_num
_check_exist:
    push ecx
    call _check_winner
    pop ecx
    cmp eax, 1
    jne _not_exist
    mov ecx, dword [esp+4]
    inc ecx
    mov [esp+4], ecx
_not_exist:
    jmp _get_win_num
_add_wins:
    mov ebx, [esp + 4]
    cmp ebx, 0
    jle _repeat
    mov eax, 1
    dec ebx
    mov cl, bl
    shl eax, cl
shifted:
    mov ebx, dword [sum]
    add ebx, eax
    mov [sum], ebx
    jmp _repeat

_close_file:
    mov eax, dword [sum]
    call printnum
    mov eax, 6 ; sys_call close
    mov ebx, [fd] ; close arg
    int 0x80

_exit:
    mov esp, ebp
    pop ebp
    mov eax, 1 ; sys_exit
    mov ebx, edx ; exit_code
    int 0x80

_check_winner: ; needs number on eax
    push ebp
    mov ebp, esp
    xor ecx, ecx

_loop_winner:
    lea esi, [numbers + ecx]
    mov ebx, dword [esi]
    cmp ebx, dword -1
    je _no_winner
    cmp ebx, eax
    je _winner
    add ecx, 4
    jmp _loop_winner
_winner:
    mov eax, 1
    jmp _winner_end
_no_winner:
    mov eax, 0
_winner_end:
    mov esp, ebp
    pop ebp
    ret
