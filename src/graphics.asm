; Graphics mode with mouse support - (c) Ayano4ka1338, 2026
m_x:    dw 160
m_y:    dw 100

gui_text1:  db "YabroOS Graphics v1.0", 0
gui_text2:  db "WASD - move, SPC - draw", 0
gui_text3:  db "ESC - exit", 0
msg_no_mouse_gfx: db "No mouse - using keyboard", 0

; Enter VGA 320x200 mode
graphics_mode:
    pusha
    
    mov ax, 0x0013
    int 0x10
    
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000
    mov al, 1
    rep stosb
    
    mov si, gui_text1
    mov cx, 50
    mov dx, 50
    call draw_text
    
    mov si, gui_text2
    mov cx, 50
    mov dx, 70
    call draw_text
    
    mov si, gui_text3
    mov cx, 50
    mov dx, 90
    call draw_text
    
    call init_mouse
    
    cmp word [mouse_found], 0
    je .no_mouse
    
    mov word [m_x], 160
    mov word [m_y], 100
    call draw_cursor_gfx
    
.gloop:
    call update_mouse
    
    cmp word [mouse_moved], 1
    jne .skip_cursor
    
    call erase_cursor_gfx
    call draw_cursor_gfx
    mov word [mouse_moved], 0
    
.skip_cursor:
    mov ah, 0x01
    int 0x16
    jz .gloop
    
    mov ah, 0x00
    int 0x16
    
    cmp al, 27
    je .exit
    
    cmp al, 'w'
    je .move_up
    cmp al, 'W'
    je .move_up
    cmp al, 's'
    je .move_down
    cmp al, 'S'
    je .move_down
    cmp al, 'a'
    je .move_left
    cmp al, 'A'
    je .move_left
    cmp al, 'd'
    je .move_right
    cmp al, 'D'
    je .move_right
    
    cmp al, 0x20
    je .draw_pixel
    
    jmp .gloop

.move_up:
    cmp word [m_y], 5
    jle .gloop
    call erase_cursor_gfx
    dec word [m_y]
    call draw_cursor_gfx
    jmp .gloop

.move_down:
    cmp word [m_y], 194
    jge .gloop
    call erase_cursor_gfx
    inc word [m_y]
    call draw_cursor_gfx
    jmp .gloop

.move_left:
    cmp word [m_x], 5
    jle .gloop
    call erase_cursor_gfx
    dec word [m_x]
    call draw_cursor_gfx
    jmp .gloop

.move_right:
    cmp word [m_x], 314
    jge .gloop
    call erase_cursor_gfx
    inc word [m_x]
    call draw_cursor_gfx
    jmp .gloop

.draw_pixel:
    mov cx, word [m_x]
    mov dx, word [m_y]
    mov al, 14
    call put_pixel
    jmp .gloop

.no_mouse:
    mov si, msg_no_mouse_gfx
    call print_string
    
    mov word [m_x], 160
    mov word [m_y], 100
    call draw_cursor_gfx
    
.gloop_no_mouse:
    mov ah, 0x01
    int 0x16
    jz .gloop_no_mouse
    
    mov ah, 0x00
    int 0x16
    
    cmp al, 27
    je .exit
    
    cmp al, 'w'
    je .move_up_no
    cmp al, 'W'
    je .move_up_no
    cmp al, 's'
    je .move_down_no
    cmp al, 'S'
    je .move_down_no
    cmp al, 'a'
    je .move_left_no
    cmp al, 'A'
    je .move_left_no
    cmp al, 'd'
    je .move_right_no
    cmp al, 'D'
    je .move_right_no
    
    cmp al, 0x20
    je .draw_pixel_no
    
    jmp .gloop_no_mouse

.move_up_no:
    cmp word [m_y], 5
    jle .gloop_no_mouse
    call erase_cursor_gfx
    dec word [m_y]
    call draw_cursor_gfx
    jmp .gloop_no_mouse

.move_down_no:
    cmp word [m_y], 194
    jge .gloop_no_mouse
    call erase_cursor_gfx
    inc word [m_y]
    call draw_cursor_gfx
    jmp .gloop_no_mouse

.move_left_no:
    cmp word [m_x], 5
    jle .gloop_no_mouse
    call erase_cursor_gfx
    dec word [m_x]
    call draw_cursor_gfx
    jmp .gloop_no_mouse

.move_right_no:
    cmp word [m_x], 314
    jge .gloop_no_mouse
    call erase_cursor_gfx
    inc word [m_x]
    call draw_cursor_gfx
    jmp .gloop_no_mouse

.draw_pixel_no:
    mov cx, word [m_x]
    mov dx, word [m_y]
    mov al, 14
    call put_pixel
    jmp .gloop_no_mouse

.exit:
    call restore_mouse_irq
    mov ax, 0x0003
    int 0x10
    popa
    ret

; Draw cursor at current position
draw_cursor_gfx:
    pusha
    cmp word [m_x], 0
    jl .done
    cmp word [m_x], 319
    jg .done
    cmp word [m_y], 0
    jl .done
    cmp word [m_y], 199
    jg .done
    
    mov cx, [m_x]
    mov dx, [m_y]
    mov al, 15
    
    call put_pixel
    inc cx
    call put_pixel
    inc cx
    call put_pixel
    inc cx
    call put_pixel
    inc cx
    call put_pixel
    
    mov cx, [m_x]
    inc dx
    call put_pixel
    mov cx, [m_x]
    add cx, 4
    call put_pixel
    
    mov cx, [m_x]
    add dx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 4
    call put_pixel
    
    mov cx, [m_x]
    add dx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 3
    call put_pixel
    
    mov cx, [m_x]
    add dx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 2
    call put_pixel
    
.done:
    popa
    ret

; Erase cursor
erase_cursor_gfx:
    pusha
    cmp word [m_x], 0
    jl .done
    cmp word [m_x], 319
    jg .done
    cmp word [m_y], 0
    jl .done
    cmp word [m_y], 199
    jg .done
    
    mov cx, [m_x]
    mov dx, [m_y]
    mov al, 1
    
    call put_pixel
    inc cx
    call put_pixel
    inc cx
    call put_pixel
    inc cx
    call put_pixel
    inc cx
    call put_pixel
    
    mov cx, [m_x]
    inc dx
    call put_pixel
    mov cx, [m_x]
    add cx, 4
    call put_pixel
    
    mov cx, [m_x]
    add dx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 4
    call put_pixel
    
    mov cx, [m_x]
    add dx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 3
    call put_pixel
    
    mov cx, [m_x]
    add dx, 1
    call put_pixel
    mov cx, [m_x]
    add cx, 2
    call put_pixel
    
.done:
    popa
    ret

; Put pixel at CX,DX with color AL
put_pixel:
    pusha
    push es
    
    cmp cx, 0
    jl .done
    cmp cx, 319
    jg .done
    cmp dx, 0
    jl .done
    cmp dx, 199
    jg .done
    
    mov bx, 0xA000
    mov es, bx
    
    mov di, dx
    shl di, 6
    mov bx, dx
    shl bx, 8
    add di, bx
    add di, cx
    
    mov [es:di], al
    
.done:
    pop es
    popa
    ret

; Update mouse position
update_mouse:
    pusha
    
    cmp word [mouse_found], 0
    je .done
    
    cmp word [mouse_dos_mode], 1
    je .dos_mode
    
    mov ax, word [mouse_x]
    mov word [m_x], ax
    mov ax, word [mouse_y]
    mov word [m_y], ax
    jmp .done
    
.dos_mode:
    mov ax, 0003h
    int 33h
    
    shr cx, 1
    mov word [m_x], cx
    mov word [m_y], dx
    mov word [mouse_moved], 1
    
.done:
    popa
    ret

; Draw text string at position
draw_text:
    pusha
    mov [.tx], cx
    mov [.ty], dx
.lp:
    lodsb
    or   al, al
    jz   .done
    push si
    mov  cx, [.tx]
    mov  dx, [.ty]
    call draw_char
    pop  si
    add  word [.tx], 8
    jmp  .lp
.done:
    popa
    ret
.tx: dw 0
.ty: dw 0

; Draw single character at position
draw_char:
    pusha
    sub al, 32
    mov bl, 8
    mul bl
    mov bx, ax
    mov si, font_data
    add si, bx
    mov [.xs], cx
    mov [.ys], dx
    mov word [.row], 0
.crow:
    cmp word [.row], 8
    je .cdone
    mov al, [si]
    mov [.bits], al
    mov word [.col], 0
.ccol:
    cmp word [.col], 8
    je .crow_next
    mov al, [.bits]
    shl al, 1
    mov [.bits], al
    test al, 0x80
    jz .nopix
    mov cx, [.xs]
    add cx, [.col]
    mov dx, [.ys]
    add dx, [.row]
    pusha
    mov ax, 0xA000
    mov es, ax
    mov di, dx
    shl di, 6
    mov bx, dx
    shl bx, 8
    add di, bx
    add di, cx
    mov al, 15
    mov [es:di], al
    popa
.nopix:
    inc word [.col]
    jmp .ccol
.crow_next:
    inc si
    inc word [.row]
    jmp .crow
.cdone:
    popa
    ret
.xs: dw 0
.ys: dw 0
.row: dw 0
.col: dw 0
.bits: db 0
