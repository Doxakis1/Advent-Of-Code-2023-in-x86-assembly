; My idea for this one is pretty simple, read all the file into a huge buffer. Find out what is the length of the lines, and then start going over the numbers 1 by 1. For a number to be valid, I can go from the numbers first index and last index forward and backwords to check all directions

; so for every number character:
; check index + linelength, index + linelength + 1, index + linelength - 1, index - linelength,
; index - linelength + 1, index - linelength -1
; if any index has a symbol I add it to a stack location. At the end of all indexes I check
; if the stack location has a value other than number, linebreak, dot or 0. If it does, the number is valid and is added to the sum

; Today I will rewrite my entire code without borrowing from previous days because my code was getting messy
%define exit dword 1
%define read dword 3
%define write dword 4
%define open dword 5
%define close dword 6
%define stdout dword 1


section .data
    filename db'file.txt', 0
    readflags dd 0
    readmode  dd 0
section .bss
    checker resd 1 ; for the checker function, to make life easier
    linelength resd 1 ; holds linelength
    num_a   resd 1 ; general purpose global int
    above resd 1 ; directions for check
    below resd 1 ; directions for check
    behind resd 1 ; directions for check
    infront resd 1 ; directions for check
    sum     resd 1 ; I learned from previous days that globals are much easier to use than stack
    fd      resd 1
    ; albeit it is a bad practice I will do it
    buffer resb 32800 ; this should be enough for the entire file, but I can make it bigger as needed
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
isNum: ; requires the digit to be on ebx, returns on ecx 1 or 0 based on is it or is it not
    xor ecx, ecx
    cmp ebx, '0'
    jl _isDigit_not
    cmp ebx, '9'
    jg _isDigit_not
    mov ecx, 1
    ret
_isDigit_not:
    mov ecx, 0
    ret
getNum: ; requires that the esi holds string[current_index] returns the number in eax and length in ebx
    push ebp
    mov ebp, esp

    sub esp, 8 ; 2 dwords
    mov [esp], dword 0 ; initilizes current number
    mov [esp + 4], dword 0  ; initializes current index
_getNum_next_digit:
    mov ecx, [esp + 4]
    movzx ebx, byte [esi + ecx] 
    cmp ebx, '0'
    jge _getNum_b1
    mov eax, [esp]
    mov ebx, [esp + 4]
    jmp _getNum_ret
_getNum_b1:
    cmp ebx, '9'
    jle _getNum_isnum
    mov eax, [esp]
    mov ebx, [esp + 4]
    jmp _getNum_ret
_getNum_isnum:
    sub ebx, '0'
    mov eax, [esp]
    xor edx, edx
    mov ecx, 10
    mul ecx
    add eax, ebx
    mov [esp], eax
    mov ecx, [esp + 4]
    inc ecx
    mov [esp + 4], ecx ; increase index
    jmp _getNum_next_digit
_getNum_ret:
    mov eax, [esp]
    mov ebx, [esp + 4]
    mov esp, ebp
    pop ebp
    ret
check_index: ;this returns the ammount of characters to skip to ebx and if we found a valid number eax stores that number otherwise it stores -1
    push ebp
    mov ebp, esp
    sub esp, 16 ; 4 dwords
    
    mov [esp], esi ; store string[current_index]
    mov ebx, -1
    mov [esp + 4], ebx ;initialize number
    mov ebx, 1
    mov [esp + 8], ebx ; initialize skip index
    cmp eax, '0'
    jge _check_index_b1
    jmp _check_index_ret
_check_index_b1:
    cmp eax, '9'
    jle _check_index_isnum
    jmp _check_index_ret
_check_index_isnum: ; we only come here if index is number
    call getNum
    mov [esp + 4], eax ; store number
    mov [esp + 8], ebx ; store length
    ;call printnum
_check_qualifiesi_init:
    xor ecx, ecx
    mov [esp + 12], ecx
_check_valid_loop:
    mov eax, [esp]
    mov edx, [esp + 8]
    cmp ecx, edx
    jge _check_not_valid
    lea esi, [eax + ecx]

_check_behind:
    mov ebx, [behind]
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_infront
    cmp ebx, 0
    je _check_infront
    cmp ebx, '.'
    je _check_infront
    cmp ebx, 10
    je _check_infront
    jmp _check_index_ret ; if we reach this, this is a valid number!

_check_infront:
    mov ebx, [infront]
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_backdiag1
    cmp ebx, 0
    je _check_backdiag1
    cmp ebx, '.'
    je _check_backdiag1
    cmp ebx, 10
    je _check_next
    jmp _check_index_ret ; if we reach this, this is a valid number!

_check_backdiag1:
    mov ebx, [above]
    dec ebx
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_backdiag2
    cmp ebx, 0
    je _check_backdiag2
    cmp ebx, '.'
    je _check_backdiag2
    cmp ebx, 10
    je _check_frontdiag2
    jmp _check_index_ret ; if we reach this, this is a valid number!

_check_backdiag2:
    mov ebx, [above]
    inc ebx
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_frontdiag1
    cmp ebx, 0
    je _check_frontdiag1
    cmp ebx, '.'
    je _check_frontdiag1
    cmp ebx, 10
    je _check_next
    jmp _check_index_ret ; if we reach this, this is a valid number!


_check_frontdiag1:
    mov ebx, [below]
    dec ebx
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_frontdiag2
    cmp ebx, 0
    je _check_frontdiag2
    cmp ebx, '.'
    je _check_frontdiag2
    cmp ebx, 10
    je _check_frontdiag2
    jmp _check_index_ret ; if we reach this, this is a valid number!

_check_frontdiag2:
    mov ebx, [below]
    inc ebx
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_above
    cmp ebx, 0
    je _check_above
    cmp ebx, '.'
    je _check_above
    cmp ebx, 10
    je _check_above
    jmp _check_index_ret ; if we reach this, this is a valid number!

_check_above:
    mov ebx, [above]
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_below
    cmp ebx, 0
    je _check_below
    cmp ebx, '.'
    je _check_below
    cmp ebx, 10
    je _check_below
    jmp _check_index_ret ; if we reach this, this is a valid number!

_check_below:
    mov ebx, [below]
    lea edi, [esi + ebx]
    movzx ebx, byte [edi]
    call isNum
    cmp ecx, 0
    jg _check_next
    cmp ebx, 0
    je _check_next
    cmp ebx, '.'
    je _check_next
    cmp ebx, 10
    je _check_next
    jmp _check_index_ret ; if we reach this, this is a valid number!

_check_next:
    mov ecx, [esp + 12]
    inc ecx
    mov [esp + 12], ecx
    jmp _check_valid_loop

_check_not_valid:
    mov eax, [esp + 4]
    ;call printnum
    mov eax, -1
    mov [esp + 4], eax
_check_index_ret:
    mov eax, [esp + 4]
    mov ebx, [esp + 8]
    mov esp, ebp
    pop ebp
    ret
_start:
    ;prologue
    push ebp
    mov ebp, esp

    ; initialize globals and registers
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    mov esi, eax
    mov edi, eax
    mov [checker], eax
    mov [linelength], eax
    mov [num_a], eax
    mov [sum], eax
    mov [fd], eax
    ;bzero(buffer, 3000)
_bzero_loop:
    lea esi, [buffer + ecx]
    mov [esi] , byte 0
    inc ecx
    cmp ecx, 32800
    jl _bzero_loop
_loop_out:
    dec ecx
    lea esi, [buffer + ecx]
    mov [esi], byte 0 ; NUL terminate

    ;open ("file.txt", O_RDONLY)
    mov eax, open
    mov ebx, filename
    mov ecx, [readflags]
    mov edx, [readmode]
    int 0x80
    cmp eax, -1
    je _end
    mov [fd], eax

; the first and last 1400 characters are padding. Because I do not know the size of the lines yet
; and since I will be doing line indexing, I dont want to go out of bounds. And checking manually is an extra branch    
_get_linelenght_init:
    mov ecx, 1400
    mov [num_a], ecx
_get_linelength: ; we read 1 by 1 until we find the linebreak
    mov ecx, dword [num_a]
    lea esi, [buffer + ecx]
    mov eax, read
    mov ebx, [fd]
    lea ecx, [esi]
    mov edx, 1
    int 0x80
_read:
    cmp eax, 0
    jl _close_file ; we should not reach EOF in this step. if we do exit
    movzx eax, byte [esi]
_test:
    mov ecx, dword [num_a]
    cmp eax, 10
    je _got_line_length
    inc ecx
    mov [num_a], ecx
    jmp _get_linelength
_got_line_length:
    sub ecx, 1400
    inc ecx
    mov [linelength], ecx ; stored the line length
    mov [below], ecx ; initializes below
    imul ecx, -1
    mov [above], ecx ; init above
    mov ecx, 1
    mov [infront], ecx
    mov ecx, -1
    mov [behind], ecx
    mov ecx, [linelength]
    add ecx, 1400
    mov [num_a], ecx
_read_all_lines:
    mov ecx, [num_a]
    mov edx, [linelength]
    mov eax, read
    mov ebx, [fd]
    lea esi, [buffer + ecx]
    mov ecx, esi
    int 0x80
    cmp eax, edx
    jl _done_reading
    mov ecx, [num_a]
    add ecx, eax
    mov [num_a], ecx
    jmp _read_all_lines
_done_reading:
    mov [esi], byte 0 ; NUL terminate the strings
_find_nums_init:
    mov ecx, 1400
    mov [num_a], ecx
_find_nums_loop:
    mov ecx, [num_a] ; load next offset
    lea esi, [buffer + ecx]
    movzx eax, byte [esi]
    cmp eax, 0
    je _done
    cmp eax, 10
    je _find_nums_loop_break
    call check_index
    cmp eax, -1
    jg _add_number
_find_nums_loop_break:
    mov ecx, [num_a]
    add ecx, ebx
    mov [num_a], ecx
    jmp _find_nums_loop
_add_number:
    mov ecx, [sum]
    add ecx, eax
    mov [sum], ecx
    jmp _find_nums_loop_break
_done:
    mov eax, [sum]
    call printnum
_close_file:
    mov eax, close
    mov ebx, dword [fd]
    int 0x80
_end:    ;epilogue
    mov esp, ebp
    pop ebp
    mov eax, exit
    mov ebx, 0
    int 0x80
