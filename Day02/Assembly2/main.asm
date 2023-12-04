section .data 
    filename db 'file.txt', 0 ; we assume the data is in a file named file.txt
    read_flags dd 0 ; read flags
    file_mode dd 0 ;  read options/ not needed
section .bss
    red resd 1
    blue resd 1
    green resd 1
    char_buffer  resb 1024 ; allowing 1024 characters per line ; yes, breaks if more chars per line but oh well...
section .text 
    global _start ; our main

printnum: ; I made this in day01 it needs the number to be in eax register
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
    mov esp, ebp
    pop ebp
    ret

_getNum: ;this gets ascii from string and makes it to a num, it requires the start of the string position to be in esi and returns the number in eax and incriments ecx for the index counter
    push ecx ;stores ecx since it gets used for indexs counter
    push ebp 
    mov ebp, esp
    
    sub esp, 4 ; int a
    xor eax, eax ; eax to 0
    xor ebx, ebx ; ebx to 0
    xor ecx, ecx ; ecx to 0
    mov [esp], ecx ; a = 0
    jmp _getNum_loop
_getNum_init:
    inc ecx ; incriments ecx
_getNum_loop:
    movzx ebx, byte [edi + ecx] ;moves current character to ebx
    cmp ebx, '0'
    jl _getNum_ret ; if ( ebx < '0')
    cmp ebx, '9'
    jg _getNum_ret ; if (ebx > '9')
_getNum_add:
    sub ebx, '0'
    mov [esp], ebx ; a = char
    mov ebx, 10
    xor edx, edx ; clear edx to hold overflow
    mul ebx ; multiply eax by eax
    mov ebx, [esp]
    add eax, ebx ; add the new digit to eax
    jmp _getNum_init
_getNum_ret: ;returns to caller and pops and incriments ecx
    mov ebx, ecx ; stores index
    mov esp, ebp ; restores stack pointer
    pop ebp
    pop ecx ; brings old counter back to ecx
    add ecx, ebx ; adds new incriment
    ret

check_possible: ; this requires that edi holds the index we want to check and it assumes no typos and no bad text, it returns 0 on ebx if the value is okay or 1 if it is not. if okay then eax holds how many characters to skip for next index
    movzx eax, byte [edi] ; loads char to eax
    cmp eax, 'r'
    je _check_red
    cmp eax, 'b'
    je _check_blue
    cmp eax, 'g'
    je _check_green
    mov eax, 1
    jmp _check_possible_ret ; jmps in case of error (but god bless if there is an error lol)
_check_red:
    mov edx, dword [red] ; moves max_red_value to ebx
    mov eax, 3 ; skip 3 chars
    cmp ebx, edx 
    jl _check_possible_ret
    mov [red], ebx
    jmp _check_possible_ret
_check_blue:
    mov edx, dword [blue] ; moves max_blue_value to ebx
    mov eax, 4 ; skip 4 chars
    cmp ebx, edx
    jl _check_possible_ret
    mov [blue], ebx
    jmp _check_possible_ret
_check_green:
    mov edx, dword [green]; moves max_green_value to ebx
    mov eax, 5 ; skip 5 chars
    cmp ebx, edx
    jl _check_possible_ret
    mov [green], ebx
_check_possible_ret:
    mov ebx, 0
    ret
_start:
    ;prologue
    push ebp
    mov ebp, esp

    sub esp, 32 ; 7 ints,  char[2], 1 byte for check and 1 extra for alignment
    mov eax, 0
    mov [esp + 4], eax ; initializes current sum to zero
    mov [esp + 12], eax ; initilizes current line to 0 
    mov eax, 14
    mov eax, 0
    mov [esp + 28] , eax ; initialize holder (int a)
    mov eax, -1
    mov [esp + 8], eax ; initilizes fd to -1
    ; First this program assumes you have a file named "file.txt" that contains for your data so it tries to open it using the open syscall
    mov eax, 5 ; syscall to open file
    mov ebx, filename ; first argument const char *
    mov ecx, [read_flags]
    mov edx, [file_mode]
    int 0x80
    mov [esp + 8], eax
    cmp eax, 0
    jl _exit ; if fd is broken we exit, else we go to readline loop

_readline_init: ;this the function I made for day01 to read a line either delimeted by \n or NUL
    mov esi, char_buffer
    xor ecx, ecx
    mov [red], dword 0
    mov [blue], dword 0
    mov [green], dword 0
    mov [esp], dword 0 ;reset holder
    mov [esp + 12], dword 0 ;reset index
    mov [char_buffer], dword 0 ; makes first chars 0s of the buffer
_readline_loop:
    lea esi, [char_buffer + ecx]
    mov eax, 3 ; syscall to read
    mov ebx, [esp + 8]
    lea ecx, [esi]
    mov edx, 1
    int 0x80
    mov [esi + 1], byte 0
    cmp eax, 0
    je _line_logic
    movzx eax, byte [esi] ; zero extend move one byte from where esi points to eax
    cmp eax , 10 ; test for new lines
    je _line_logic
    mov ecx, dword [esp + 12] ; index into ecx
    inc ecx ;index++
    mov [esp + 12], ecx 
    jmp _readline_loop

_line_logic:
    xor ecx, ecx
    mov [esp + 12], dword 0 ;reset current line
    lea edi, [char_buffer + ecx]
    movzx eax, byte [edi]
    cmp eax, 0
    je _close_file
    add ecx, 5 ; here we are skipping "Game " we just assume the file is correct xd...
    lea edi, [char_buffer + ecx]
    call _getNum
    mov [esp + 12], eax ;update line counter
_line_get_game:
    add ecx, 2 ; skips the ": " or "; " after the game number
_line_get_values:
    mov [esp + 28], dword 0 ; a = 0
    lea edi, [char_buffer + ecx]
    call _getNum
    mov [esp + 28], eax ; a = getNum(char *str)
    inc ecx ; skip the space after
    lea edi, [char_buffer + ecx] ; move ahead
    mov ebx, [esp + 28]
    call check_possible
    cmp ebx, 0
    jne _line_logic_exit
    add ecx, eax
    lea edi, [char_buffer + ecx] ; move ahead
    movzx eax, byte [edi]
    cmp eax, 10
    je _line_logic_add
    cmp eax, 0
    je _line_logic_add
    jmp _line_get_game
_line_logic_exit:
    jmp _readline_init
_line_logic_add:
    mov ecx, eax
    mov ebx, dword [red] ; load the sum value
    mov eax, dword [blue] ; load current line number
    xor edx, edx
    mul ebx
    mov ebx, dword[green]
    xor edx, edx
    mul ebx
    mov ebx, dword [esp+4]
    add ebx, eax
    mov [esp+4] , ebx ; store new sum
    mov eax, ecx
    cmp eax, 0
    jne _line_logic_exit
_close_file:
    mov eax, 6 ; syscall to close
    mov ebx, [esp + 8]
    int 0x80
_exit:
    mov eax, [esp + 4]
    call printnum
    mov eax, 1 ; syscall to exit
    mov ebx, [esp + 4]
    mov esp, ebp
    pop ebp
    int 0x80

