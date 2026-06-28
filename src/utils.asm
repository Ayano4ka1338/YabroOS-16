; Utility functions - (c) Ayano4ka1338, 2026

; Clear screen
clear_screen:
    pusha
    mov ax, 0x0003
    int 0x10
    popa
    ret

; Print null-terminated string
print_string:
    pusha
    mov ah, 0x0E
.lp:
    lodsb
    or al, al
    jz .done
    int 0x10
    jmp .lp
.done:
    popa
    ret

; Get string from keyboard into input_buffer
get_string:
    push bx
    push cx
    push di
    push si
    mov di, input_buffer
    mov cx, 0
.get_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .enter
    cmp al, 0x08
    je .backspace
    cmp cx, 254
    jge .get_loop
    mov ah, 0x0E
    int 0x10
    stosb
    inc cx
    jmp .get_loop
.backspace:
    cmp cx, 0
    je .get_loop
    dec cx
    dec di
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .get_loop
.enter:
    mov byte [di], 0
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    pop si
    pop di
    pop cx
    pop bx
    ret

; Print AX as decimal
print_ax:
    pusha
    xor cx, cx
    mov bx, 10
    test ax, ax
    jnz .div
    mov ah, 0x0E
    mov al, '0'
    int 0x10
    jmp .end
.div:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .div
.pr:
    pop dx
    add dl, '0'
    mov ah, 0x0E
    mov al, dl
    int 0x10
    loop .pr
.end:
    popa
    ret

; Print byte as hex
print_hex_byte:
    pusha
    mov bl, al
    shr al, 4
    call .nib
    mov al, bl
    and al, 0x0F
    call .nib
    popa
    ret
.nib:
    cmp al, 10
    jb .dec
    add al, 'A' - 10
    jmp .out
.dec:
    add al, '0'
.out:
    mov ah, 0x0E
    int 0x10
    ret

; Compare two strings
strcmp:
    pusha
.lp:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .ne
    or al, al
    jz .eq
    inc si
    inc di
    jmp .lp
.eq:
    popa
    stc
    ret
.ne:
    popa
    clc
    ret

; Convert input to lowercase
to_lowercase:
    pusha
    mov si, input_buffer
.lp:
    lodsb
    or al, al
    jz .done
    cmp al, 'A'
    jb .next
    cmp al, 'Z'
    ja .next
    add byte [si-1], 0x20
.next:
    jmp .lp
.done:
    popa
    ret

; Skip spaces in SI
skip_spaces:
    cmp byte [si], ' '
    jne .done
    inc si
    jmp skip_spaces
.done:
    ret

; Show cursor
draw_cursor:
    pusha
    mov ah, 0x03
    xor bh, bh
    int 0x10
    mov ah, 0x01
    mov cx, 0x0007
    int 0x10
    popa
    ret

; Hide cursor
hide_cursor:
    pusha
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10
    popa
    ret

; Get password (echo *)
get_password:
    push bx
    push cx
    push di
    mov di, pwd_buffer
    xor cx, cx
.pwd_get_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0D
    je .pwd_enter
    cmp al, 0x08
    je .pwd_backspace
    cmp cx, 31
    jge .pwd_get_loop
    
    mov [di], al
    inc di
    inc cx
    
    mov ah, 0x0E
    mov al, '*'
    int 0x10
    jmp .pwd_get_loop
    
.pwd_backspace:
    cmp cx, 0
    je .pwd_get_loop
    dec cx
    dec di
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .pwd_get_loop
    
.pwd_enter:
    mov byte [di], 0
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    
    pop di
    pop cx
    pop bx
    ret

; Verify password (always OK for now)
verify_password:
    mov al, 1
    ret

; Read decimal number from keyboard
read_number:
    push bx
    push cx
    xor bx, bx
    xor cx, cx
.lp:
    xor ah, ah
    int 0x16
    cmp al, 0x0D
    je .done
    cmp al, 0x08
    je .bs    
    cmp al, '0'
    jb .lp
    cmp al, '9'
    ja .lp
    mov ah, 0x0E
    int 0x10
    sub al, '0'
    xor ah, ah
    push ax
    mov ax, bx
    mov dx, 10
    mul dx
    mov bx, ax
    pop ax
    add bx, ax
    inc cx
    jmp .lp
.bs:
    or cx, cx
    jz .lp
    dec cx
    xor dx, dx
    mov ax, bx
    push cx
    mov cx, 10
    div cx
    pop cx
    mov bx, ax
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .lp
.done:
    mov si, newline
    call print_string
    mov ax, bx
    pop cx
    pop bx
    ret

; Parse unsigned integer from string
parse_uint:
    push bx
    push cx
    xor bx, bx
.lp:
    mov al, [si]
    cmp al, '0'
    jb .done
    cmp al, '9'
    ja .done
    sub al, '0'
    xor ah, ah
    push ax
    mov ax, bx
    mov cx, 10
    mul cx
    mov bx, ax
    pop ax
    add bx, ax
    inc si
    jmp .lp
.done:
    mov ax, bx
    pop cx
    pop bx
    ret
