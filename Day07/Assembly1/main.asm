127extern fd_printnum
extern get_next_line
extern get_number
extern uint32_min
extern reserve
extern free
extern reserve_init
extern reserve_clear

; TODO: Learn vim replace text operations

%define exit 1
%define write 4
%define read 3
%define open 5
%define close 6
%define hand_node_size 16 ; hand rank (2 ints), hand value 4 bytes (int), 32bit ptr to next = 14 bytes and 2 for allignment = 12

section .bss
    fd resd 1
section .data
    filename db 'file.txt', 0
section .text
    global _start

; example hand: AAAKK 145
; 23456789TJQKA

; hand ranks:
; QUADS TRIPS TWOPAIRS ONEPAIR + HIGHEST_CARD * 4 but in reverse to put it into int
; so if I get quads += 8
; if trips += 4
; if pair += 1
; then bitshift by 4 to the left and add the highest card

get_hand_rank: ; char *str needed on eax
    push ebp
    mov ebp, esp
    sub esp, 21 ; char *str && 13 bytes for each possible card value
    mov [esp+17], dword 0 
    mov [esp+13], eax
    mov [esp+12], byte 0
    mov [esp+8], dword 0
    mov [esp+4], dword 0
    mov [esp], dword 0
    mov ecx, 0
_get_next_card:
    cmp ecx, dword 5
    jge _get_hand_rank_done
    mov eax, [esp+13]
    add eax, ecx
    movzx ebx, byte [eax]
    cmp ebx, byte '9'
    jg _get_next_card_ace
    sub ebx, '0'
    sub ebx, 2
    jmp _get_next_card_inc
_get_next_card_ace:
    cmp ebx, 'A'
    jne _get_next_card_king
    mov ebx, dword 12
    jmp _get_next_card_inc
_get_next_card_king:
    cmp ebx, 'K'
    jne _get_next_card_queen
    mov ebx, dword 11
    jmp _get_next_card_inc
_get_next_card_queen:
    cmp ebx, 'Q'
    jne _get_next_card_jack
    mov ebx, dword 10
    jmp _get_next_card_inc
_get_next_card_jack:
    cmp ebx, 'J'
    jne _get_next_card_ten
    mov ebx, dword 9
    jmp _get_next_card_inc
_get_next_card_ten:
    mov ebx, dword 8
_get_next_card_inc:
    add ebx, esp
    movzx eax, byte [ebx]
    inc eax
    mov [ebx], al
    inc ecx
    jmp _get_next_card
_get_hand_rank_done:
    mov ecx, dword 0
_get_hand_rank_evaluate:
    cmp ecx, dword 13
    jg _get_hand_rank_highest_card
    mov ebx, ecx
    add ebx, esp
    movzx eax, byte [ebx]
    cmp eax, dword 4
    jne _check_trips
    mov eax, dword 8
    jmp _get_hand_evaluate_inc
_check_trips:
    cmp eax, dword 3
    jne _check_pair
    mov eax, dword 4
    jmp _get_hand_evaluate_inc
_check_pair:
    cmp eax, dword 2
    jne _no_pairs
    mov eax, dword 1
    jmp _get_hand_evaluate_inc
_no_pairs:
    mov eax, dword 0
_get_hand_evaluate_inc:
    mov ebx, dword [esp+17]
    add ebx, eax
    mov [esp+17], ebx
    inc ecx
    jmp _get_hand_rank_evaluate
_get_hand_rank_highest_card:
    mov ebx, dword [esp+17]
    shl ebx, 4
    mov [esp+17], ebx
    mov ecx, dword 12
_get_hand_highest_card_loop:
    cmp ecx, -1
    mov ebx, dword 0
    jl _add_highest
    mov ebx, esp
    add ebx, ecx
    movzx eax, byte [ebx]
    mov ebx, ecx
    cmp eax, 0
    jne _add_highest
    dec ecx
    jmp _get_hand_highest_card_loop
_add_highest:
    mov eax, dword [esp+17]
    add eax, ebx ; return on eax
_get_hand_rank_ret:
    mov esp, ebp
    pop ebp
    ret

get_hand_value: ; requires the hand line to be on eax, returns on eax the first int, ebx the second  int, on ecx the hand bet value
    push ebp
    mov ebp, esp
    sub esp, 16 ; 3 ints
    mov [esp+12], dword 0 ; hand rank 1
    mov [esp+8], dword 0 ; hand rank 2
    mov [esp+4], dword 0 ; hands bet value as int
    ; since we have endiness, I think in memory I should have the memory like this:
    ; [2][1][0][rank][4][3][0x0][0x0][hand_bet_value]
    ; this will allow me to compare the 2 hands in two cmps as int from 0th index and as int from 4th index
    mov [esp], eax ; char *hand_line
_get_hand_bet_value:
    add eax, dword 6 ; to the hand_bet_value
    call get_number
    mov [esp+4], eax ; got the hand value
_get_hand_rank:
    mov eax, dword [esp]
    call get_hand_rank
    mov [esp+12], eax
_load_cards:
    mov ebx, dword [esp]
    movzx eax, byte [ebx]
    shl eax, 16
    mov edx, dword [esp+12]
    shl edx, 24
    add edx, eax
    inc ebx
    movzx eax, byte [ebx]
    shl eax, 8
    add edx, eax
    inc ebx
    movzx eax, byte [ebx]
    add edx, eax
    mov [esp+12], edx
  ; rest 2
    inc ebx
    movzx eax, byte [ebx]
    mov edx, dword [esp+8]
    shl eax, 8
    add edx, eax
    inc ebx
    movzx eax, byte [ebx]
    add edx, eax
    mov [esp+8], edx
    mov eax, [esp+12]
    mov ebx, [esp+8]
    mov ecx, [esp+4]
_get_hand_value_ret:
    mov ecx, [esp+4]
    mov esp, ebp
    pop ebp
    ret

compare_nodes: ; gets the nodes pointers in eax and ebx retuns on ecx a pointer to the bigger
    push ebp
    mov ebp, esp
    sub esp, 8 ; 2 ints
    mov [esp+4], eax
    mov [esp], ebx
    mov edx, dword [eax]
    mov ecx, dword [ebx]
    cmp ecx, edx
    ja _second_is_bigger
    jb _first_is_bigger
    add eax, 4
    add ebx, 4
    mov edx, dword [eax]
    mov ecx, dword [ebx]
    cmp ecx, edx
    ja _second_is_bigger
_first_is_bigger:
    mov ecx, dword [esp+4]
    jmp _compare_nodes_ret
_second_is_bigger:
    mov ecx, dword [esp]
_compare_nodes_ret:
    mov eax, [esp+4]
    mov ebx, [esp]
    mov esp, ebp
    pop ebp
    ret

_start:
    push ebp
    mov ebp, esp
    sub esp, 28 ; 7 ints
    mov [esp+16], dword 0 ; char *buffer
    mov [esp+12], dword 0 ; current_hand *ptr
    mov [esp+8], dword 0 ; previous_hand *ptr
    mov [esp+4], dword 0 ; hand value
    mov [esp+20], dword 0 ; first_node
    mov [esp+24], dword 0 ; current_biggest ptr
    mov [esp], dword 0
_init_heap:
    call reserve_init
    cmp eax, dword 0
    je _ret ; error getting heap
_open_file:
    lea ebx, [filename]
    mov eax, open
    int 0x80
    cmp eax, dword 0
    jl _ret
    mov [fd], eax

    mov eax, 120 ; buffer size
    call reserve
    cmp eax, dword 0
    je _close_file
    mov [esp+16], eax
_read_lines:
    mov eax, dword [fd]
    mov ebx, dword [esp+16]
    call get_next_line
    cmp eax, dword 0
    je _no_more_data
_get_card_node:
    mov eax, dword hand_node_size
    call reserve
    cmp eax, 0
    je _free_heap ; error getting heap
    mov [esp+12], eax
    mov eax, dword [esp+16]
    call get_hand_value
    mov edx, [esp+12]
    add edx, 8
    push eax
    push ebx
    push ecx
    pop ebx
    mov [edx], ebx
    sub edx, 4
    pop ebx
    mov [edx], ebx
    sub edx, 4
    pop ebx
    mov [edx], ebx
_got_data:
    mov eax, dword [esp+8]
    cmp eax, 0
    jne _add_pointer
    mov eax, dword [esp+12]
    mov [esp+20], eax
    mov [esp+8], eax
    add eax, 12
    mov [eax], dword 0
    jmp _get_next_hand
_add_pointer:
    mov ebx, dword [esp+12]
    mov [esp+8], ebx
    add eax, 12
    mov [eax], ebx
_get_next_hand:
    jmp _read_lines
_no_more_data:
    mov ebx, dword [esp+8]
    add ebx, 12
    mov [ebx], dword 0
    mov eax, dword [esp+20]
_find_biggest_loop:
    mov [
_close_file:
    mov ebx, dword [fd]
    mov eax, close
    int 0x80
_free_heap:
    call reserve_clear
_ret:
    mov esp, ebp
    pop ebp
    mov eax, exit
    mov ebp, 42
    int 0x80
