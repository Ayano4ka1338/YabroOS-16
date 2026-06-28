; Calculator - (c) Ayano4ka1338, 2026
calc_title:  db 13, 10, "=== YabroOS Calculator ===" , 13, 10, 0
calc_help:   db "  Format: num op num  (e.g. 12 + 34)", 13, 10
             db "  Ops: + - * /   |  q = quit", 13, 10, 0
calc_prompt: db "calc> ", 0
calc_result: db "= ", 0
calc_rem:    db " rem ", 0
calc_divz:   db "Division by zero!", 13, 10, 0
calc_unk:    db "Unknown operator", 13, 10, 0

calculator:
    pusha
    call clear_screen
    mov  si, calc_title
    call print_string
    mov  si, calc_help
    call print_string
.calc_loop:
    mov  si, calc_prompt
    call print_string
    call get_string
    cmp  byte [input_buffer], 0
    je   .calc_done
    mov  al, byte [input_buffer]
    cmp  al, 'q'
    je   .calc_done
    cmp  al, 'Q'
    je   .calc_done
    mov  si, input_buffer
    call parse_uint
    mov  word [.num_a], ax
    call skip_spaces_si
    mov  al, [si]
    mov  byte [.op], al
    inc  si
    call skip_spaces_si
    call parse_uint
    mov  word [.num_b], ax
    mov  ax, word [.num_a]
    mov  bx, word [.num_b]
    mov  al, byte [.op]
    cmp  al, '+'
    je   .do_add
    cmp  al, '-'
    je   .do_sub
    cmp  al, '*'
    je   .do_mul
    cmp  al, '/'
    je   .do_div
    mov  si, calc_unk
    call print_string
    jmp  .calc_loop
.do_add:
    mov  ax, word [.num_a]
    add  ax, word [.num_b]
    jmp  .show_result
.do_sub:
    mov  ax, word [.num_a]
    sub  ax, word [.num_b]
    jmp  .show_signed
.do_mul:
    mov  ax, word [.num_a]
    mul  word [.num_b]
    jmp  .show_result
.do_div:
    cmp  word [.num_b], 0
    je   .div_zero
    mov  ax, word [.num_a]
    xor  dx, dx
    div  word [.num_b]
    push dx
    mov  si, calc_result
    call print_string
    call print_ax
    mov  si, calc_rem
    call print_string
    pop  ax
    call print_ax
    mov  si, newline
    call print_string
    jmp  .calc_loop
.div_zero:
    mov  si, calc_divz
    call print_string
    jmp  .calc_loop
.show_signed:
    test ax, 0x8000
    jz   .show_result
    push ax
    mov  ah, 0x0E
    mov  al, '-'
    int  0x10
    pop  ax
    neg  ax
.show_result:
    mov  si, calc_result
    call print_string
    call print_ax
    mov  si, newline
    call print_string
    jmp  .calc_loop
.calc_done:
    call clear_screen
    popa
    ret
.num_a: dw 0
.num_b: dw 0
.op:    db 0
