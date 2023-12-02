section .data
    filename db 'file.txt', 0
    read_flags dd 0, ;O_RDONLY read only flag
    file_mode dd 0 ; we are not creating the file so mode is 0 
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
    jl  _readline_breakpoint1
    mov ebx, 1
    cmp eax, '9'
    jle _readline_breakpoint1
    mov ebx, 0
    jmp _readline_breakpoint1
 
_readline_numfound:
    movzx ebx, byte[esp + 3] ; movzx because we want to zero extend the byte to fit ebx (could have used bl)
    cmp ebx, 0
    jne _first_filled
    mov byte [esp + 3], al ; moves the lower part of eax to char[0]
_first_filled:
    mov byte [esp + 2], al ; moves the lower part of eax to char[1]
    jmp _readline_breakpoint2


_start:
    ;prologue
    push ebp
    mov ebp, esp

    sub esp, 12 ; 2 ints char[2], 1 byte for check and 1 extra for alignment
    mov eax, 0
    mov [esp + 4], eax ; initializes current sum to zero
    mov eax, -1
    mov [esp + 8], eax ; initilizes fd to -1
    mov eax, 5 ; syscall to open file
    mov ebx, filename ; first argument const char *
    mov ecx, [read_flags]
    mov edx, [file_mode]
    int 0x80
    mov [esp + 8], eax
    cmp eax, 0
    jl _exit ; if fd is broken we exit, else we go to readline loop

_readline_init:
    mov eax, 0
    mov [esp], eax ; initalizes the 2 chars, 1 byte and 1 extra to 0 
_readline_loop:
    mov eax, 3 ; syscall to read
    mov ebx, [esp + 8]
    lea ecx, [esp + 1] 
    mov edx, 1
    int 0x80
    cmp eax, 0 ; checks if read happened succesfully
    jle _add_to_sum
    
    movzx eax, byte [esp + 1] ; move the char into eax with zero extend (could have used al)
    cmp eax, 10 ; checks for newline
    je _add_to_sum
    jmp _isNum
_readline_breakpoint1:
    cmp ebx, 1
    je  _readline_numfound
_readline_breakpoint2:
    jmp _readline_loop



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
    ; First this program assumes you have a file named "file.txt" that contains for your data so it tries to open it using the open syscall

