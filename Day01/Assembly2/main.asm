section .data
    filename db 'file.txt', 0
    read_flags dd 0, ;O_RDONLY read only flag
    file_mode dd 0 ; we are not creating the file so mode is 0
    one db 'one', 0
    two db 'two', 0
    three db 'three', 0
    four db 'four' , 0
    five db 'five' , 0
    six db 'six' , 0
    seven db 'seven' , 0
    eight db 'eight' , 0
    nine db 'nine', 0
section .bss
    char_buffer  resb 1024 ; allowing 1024 characters per line
    num_buffer  resd 1024 ; allowing 1024 numbers per line
section .text
    global _start

printnum:
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

_isNum:
    mov ebx, 0
    cmp eax, '0'
    jl _find_nums_b1
    cmp eax, '9'
    jg _find_nums_b1
    mov ebx, 1
    jmp _find_nums_b1

_numFound:
    movzx ebx, byte [esp + 3]
    cmp ebx, 0 ; checks if we had a first number
    jne _first_filled
    mov byte [esp + 3], al ; moves to char[0]
_first_filled:
    mov byte[ esp + 2], al ; moves to char[1]
    jmp _find_nums_end

compare: ; basic string compare, all the check functions have loaded the num string to edi and buffer to esi
    mov eax, 0
    mov ebx, 0
    mov ecx, 0
compare_loop:
    movzx eax,byte  [edi + ecx]
    cmp eax, 0
    je compare_match
    movzx ebx, byte[esi + ecx]
    inc ecx
    sub eax, ebx
    cmp eax, 0
    je compare_loop
    mov ebx, 0
    ret
compare_match:
    mov ebx, 1
    ret


check_one:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, one
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '1'
    jmp _check_ret

check_two:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, two
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '2'
    jmp _check_ret

check_three:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, three
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '3'
    jmp _check_ret

check_four:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, four
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '4'
    jmp _check_ret

check_five:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, five
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '5'
    jmp _check_ret

check_six:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, six
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '6'
    jmp _check_ret


check_seven:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, seven
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '7'
    jmp _check_ret


check_eight:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, eight
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '8'
    jmp _check_ret

check_nine:
    lea esi, [edi + ecx]
    push edi
    push ecx
    mov edi, nine
    call compare
    cmp ebx, 1
    jne _check_ret
    mov eax, dword '9'
    jmp _check_ret

_check_ret:
    pop ecx
    pop edi
    ret
_start:
    ;prologue
    push ebp
    mov ebp, esp

    sub esp, 16 ; 2 ints,  char[2], 1 byte for check and 1 extra for alignment
    mov eax, 0
    mov [esp + 4], eax ; initializes current sum to zero
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

_readline_init:
    mov esi, char_buffer
    mov ecx, 0
    mov [esp + 12], dword 0 ; reset counter
    mov [esp], dword 0 ;reset holder
    mov [char_buffer], dword 0
_readline_loop:
    mov ecx, [esp + 12]
    lea esi, [char_buffer + ecx]
    mov eax, 3 ; syscall to write
    mov ebx, [esp + 8]
    lea ecx, [esi]
    mov edx, 1
    int 0x80
    mov [esi + 1], byte 0
    cmp eax, 0
    je _find_nums
    movzx eax, byte [esi] ; zero extend move one byte from where esi points -1 points to eax
    cmp eax , 10 ; test for new lines
    je _find_nums
    mov ecx, [esp + 12]
    inc ecx
    mov [esp + 12], ecx
    jmp _readline_loop
_find_nums:
    xor ecx, ecx
    mov edi, char_buffer
_find_nums_loop:
    movzx eax, byte [edi + ecx]
    jmp _isNum
_find_nums_b1: ; this is a nastry jump table but simple checks if we either found a num in digits form or from this index we find any of the number words
    cmp ebx, 1
    je _numFound
    call check_one
    cmp ebx, 1
    je _numFound
    call check_two
    cmp ebx, 1
    je _numFound
    call check_three
    cmp ebx, 1
    je _numFound
    call check_four
    cmp ebx, 1
    je _numFound
    call check_five
    cmp ebx, 1
    je _numFound
    call check_six
    cmp ebx, 1
    je _numFound
    call check_seven
    cmp ebx, 1
    je _numFound
    call check_eight
    cmp ebx, 1
    je _numFound
    call check_nine
    cmp ebx, 1
    je _numFound

_find_nums_end:
    movzx eax, byte [edi + ecx]
    inc ecx
    cmp eax, 0;
    je _add_to_sum
    cmp eax, 10
    je _add_to_sum
    jmp _find_nums_loop

_add_to_sum:
    mov edx, [esp + 4] ; get current value from stack
    movzx ecx, byte[esp + 3] ; mov the first digit to ecx with zero extend
    cmp ecx, 0 ; We check if we even found digits on this line, if not we dont need to add anything 
    je _add_to_sum_exit
    sub ecx, '0' ; covert into number
    imul ecx, 10 ; first digit so we multiple by 10
    add edx, ecx ; we add it to the sum
    movzx ecx, byte[esp + 2] ; we move second digit to ecx with zero extend
    sub ecx, '0' ; covert into number
    add edx, ecx ; we add it to the sum and then we are done with this line
    mov [esp + 4], edx ; insert the value back to the stack
_add_to_sum_exit:
    cmp eax, 0
    jg _readline_init ; if we did not find EOF we continue, else we drop to _exit

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

