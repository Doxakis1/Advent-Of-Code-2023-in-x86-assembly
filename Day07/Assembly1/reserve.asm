section .bss
    brk_vals resd 2
    head_chunck resd 2
section .text
    global reserved_init
    global reserve
    global free

reserved_init: ; returns -1 on eax if it fails allocates initial hap
