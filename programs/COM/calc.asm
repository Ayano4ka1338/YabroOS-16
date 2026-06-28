; Extended Calculator for YabroOS - (c) Ayano4ka1338, 2026
[org 0x0100]
[bits 16]

section .text
start:
    mov  ax, cs
    mov  ds, ax
    mov  es, ax
    
    call clear_screen
    
    mov  si, title_msg
    call print_string
    
    mov  si, help_msg
    call print_string

main_loop:
    mov  si, prompt
    call print_string
    
    call get_string
    
    cmp  byte [input_buffer], 0
    je   main_loop
    
    mov  al, byte [input_buffer]
    cmp  al, 'q'
    je   exit_calc
    cmp  al, 'Q'
    je   exit_calc
    
    call parse_expression
    jmp  main_loop

exit_calc:
    call clear_screen
    mov  ah, 0x4C
    mov  al, 0
    int  0x21

; Parse expression: number operator number
parse_expression:
    mov  si, input_buffer
    
    call parse_number
    mov  word [num1], ax
    
    call skip_spaces
    
    mov  al, [si]
    cmp  al, '+'
    je   .add
    cmp  al, '-'
    je   .sub
    cmp  al, '*'
    je   .mul
    cmp  al, '/'
    je   .div
    cmp  al, '%'
    je   .mod
    cmp  al, '^'
    je   .pow
    
    mov  si, invalid_op_msg
    call print_string
    ret
    
.add:
    inc  si
    call skip_spaces
    call parse_number
    mov  bx, word [num1]
    add  ax, bx
    jmp  .show_result
    
.sub:
    inc  si
    call skip_spaces
    call parse_number
    mov  bx, word [num1]
    sub  bx, ax
    mov  ax, bx
    jmp  .show_signed
    
.mul:
    inc  si
    call skip_spaces
    call parse_number
    mov  bx, word [num1]
    mul  bx
    jmp  .show_result
    
.div:
    inc  si
    call skip_spaces
    call parse_number
    cmp  ax, 0
    je   .div_zero
    mov  bx, ax
    mov  ax, word [num1]
    xor  dx, dx
    div  bx
    jmp  .show_result
    
.mod:
    inc  si
    call skip_spaces
    call parse_number
    cmp  ax, 0
    je   .div_zero
    mov  bx, ax
    mov  ax, word [num1]
    xor  dx, dx
    div  bx
    mov  ax, dx
    jmp  .show_result
    
.pow:
    inc  si
    call skip_spaces
    call parse_number
    mov  cx, ax
    mov  ax, 1
    mov  bx, word [num1]
    
.pow_loop:
    cmp  cx, 0
    je   .pow_done
    mul  bx
    dec  cx
    jmp  .pow_loop
    
.pow_done:
    jmp  .show_result
    
.div_zero:
    mov  si, div_zero_msg
    call print_string
    ret

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
    mov  si, result_msg
    call print_string
    call print_ax
    mov  si, newline
    call print_string
    ret

; Parse number from [SI] -> AX
parse_number:
    push bx
    push cx
    
    cmp  byte [si], '$'
    je   .hex_pascal
    
    cmp  byte [si], '0'
    jne  .decimal
    cmp  byte [si+1], 'x'
    je   .hex_c
    cmp  byte [si+1], 'X'
    je   .hex_c
    
.decimal:
    xor  bx, bx
.dec_loop:
    mov  al, [si]
    cmp  al, '0'
    jb   .dec_done
    cmp  al, '9'
    ja   .dec_done
    sub  al, '0'
    xor  ah, ah
    push ax
    mov  ax, bx
    mov  cx, 10
    mul  cx
    mov  bx, ax
    pop  ax
    add  bx, ax
    inc  si
    jmp  .dec_loop
.dec_done:
    mov  ax, bx
    pop  cx
    pop  bx
    ret

.hex_pascal:
    inc  si
    jmp  .hex_start

.hex_c:
    add  si, 2

.hex_start:
    xor  bx, bx
.hex_loop:
    mov  al, [si]
    
    cmp  al, 'a'
    jb   .not_lowercase
    cmp  al, 'f'
    ja   .not_lowercase
    sub  al, 0x20
    
.not_lowercase:
    cmp  al, '0'
    jb   .hex_done
    cmp  al, '9'
    jbe  .hex_digit
    cmp  al, 'A'
    jb   .hex_done
    cmp  al, 'F'
    ja   .hex_done

.hex_letter:
    sub  al, 'A' - 10
    jmp  .hex_store

.hex_digit:
    sub  al, '0'

.hex_store:
    shl  bx, 4
    xor  ah, ah
    add  bx, ax
    inc  si
    jmp  .hex_loop
    
.hex_done:
    mov  ax, bx
    pop  cx
    pop  bx
    ret

; Skip spaces
skip_spaces:
    cmp  byte [si], ' '
    jne  .done
    inc  si
    jmp  skip_spaces
.done:
    ret

; Print string
print_string:
    pusha
    mov  ah, 0x0E
.lp:
    lodsb
    or   al, al
    jz   .done
    int  0x10
    jmp  .lp
.done:
    popa
    ret

; Print AX as decimal
print_ax:
    pusha
    xor  cx, cx
    mov  bx, 10
    test ax, ax
    jnz  .div
    mov  ah, 0x0E
    mov  al, '0'
    int  0x10
    jmp  .end
.div:
    xor  dx, dx
    div  bx
    push dx
    inc  cx
    test ax, ax
    jnz  .div
.pr:
    pop  dx
    add  dl, '0'
    mov  ah, 0x0E
    mov  al, dl
    int  0x10
    loop .pr
.end:
    popa
    ret

; Print AX as hex
print_hex:
    pusha
    mov  bx, ax
    mov  cx, 4
.lp:
    rol  bx, 4
    mov  al, bl
    and  al, 0x0F
    cmp  al, 10
    jb   .digit
    add  al, 'A' - 10
    jmp  .out
.digit:
    add  al, '0'
.out:
    mov  ah, 0x0E
    int  0x10
    loop .lp
    popa
    ret

; Clear screen
clear_screen:
    pusha
    mov  ax, 0x0003
    int  0x10
    popa
    ret

; Get string from keyboard
get_string:
    push di
    push ax
    mov  di, input_buffer
.lp:
    xor  ah, ah
    int  0x16
    cmp  al, 0x0D
    je   .done
    cmp  al, 0x08
    je   .bs
    mov  ah, 0x0E
    int  0x10
    stosb
    jmp  .lp
.bs:
    cmp  di, input_buffer
    je   .lp
    dec  di
    mov  ah, 0x0E
    mov  al, 8
    int  0x10
    mov  al, ' '
    int  0x10
    mov  al, 8
    int  0x10
    jmp  .lp
.done:
    mov  byte [di], 0
    mov  ah, 0x0E
    mov  al, 13
    int  0x10
    mov  al, 10
    int  0x10
    pop  ax
    pop  di
    ret

; Data
title_msg:      db 13, 10, "=== YabroOS Calculator ===", 13, 10, 0
help_msg:       db "Format: num op num", 13, 10
                db "Ops: + - * / % ^", 13, 10
                db "Hex: 0xFF or $FF", 13, 10
                db "q = quit", 13, 10, 0
prompt:         db "calc> ", 0
result_msg:     db "= ", 0
invalid_op_msg: db "Invalid operator!", 13, 10, 0
div_zero_msg:   db "Division by zero!", 13, 10, 0
newline:        db 13, 10, 0

section .bss
input_buffer:   resb 256
num1:           resw 1
num2:           resw 1
