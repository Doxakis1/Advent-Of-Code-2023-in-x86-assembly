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

section .data
    filename db 'file.txt', 0
section .bss
    fd    resd 1
    nums1 resd BUFFER_SIZE
    nums2 resd BUFFER_SIZE
    nums3 resd BUFFER_SIZE
    seeds resd BUFFER_SIZE
    buffer resb BUFFER_SIZE
section .text
    global _start

_start:
    mov [fd], dword -1
_open_file:
    mov eax, open
    mov ebx, filename
    mov ecx, open_flags
    mov edx, open_mode
    int 0x80
    cmp eax, 0
    jl _exit
_test:
    mov eax, 1

_close_file:
    mov eax, close
    mov ebx, [fd]
    int 0x80
_exit:
    mov eax, exit
    mov ebx, 0
    int 0x80
    

