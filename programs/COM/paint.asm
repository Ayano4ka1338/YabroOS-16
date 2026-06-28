; YabroOS Paint - (c) Ayano4ka1338, 2026

org 100h

start:
    ; Switch to VGA 320x200 256 colors
    mov ax, 0013h
    int 10h
    
    ; Draw top bar and labels
    call draw_top_bar
    
    ; Init mouse
    mov ax, 0000h
    int 33h
    cmp ax, 0
    je no_mouse
    
    ; Show mouse cursor
    mov ax, 0001h
    int 33h
    
    ; Default color white (15)
    mov byte [color], 15
    call show_color          
    
main_loop:
    ; Get mouse status
    mov ax, 0003h
    int 33h
    
    ; Save button state to SI
    mov si, bx
    
    ; Check keyboard (ESC and color keys)
    mov ah, 01h
    int 16h
    jz .check_mouse
    mov ah, 00h
    int 16h
    
    ; ESC to exit
    cmp al, 27
    je exit
    
    ; Color keys (1-9, 0)
    cmp al, '1'
    je col_white
    cmp al, '2'
    je col1
    cmp al, '3'
    je col2
    cmp al, '4'
    je col3
    cmp al, '5'
    je col4
    cmp al, '6'
    je col5
    cmp al, '7'
    je col6
    cmp al, '8'
    je col7
    cmp al, '9'
    je col8
    cmp al, '0'
    je col9
    
.check_mouse:
    ; Restore mouse button state
    mov bx, si
    
    ; Check if any button pressed (LMB=1, RMB=2)
    test bx, 3
    jz main_loop
    
    ; X coordinate in mode 13h is doubled, divide it
    shr cx, 1
    mov [mx], cx
    mov [my], dx
    
    ; Don't draw on top bar (height 12 + margin)
    cmp dx, 16
    jl main_loop
    
    ; Hide mouse cursor while drawing
    mov ax, 0002h
    int 33h
    
    ; Check which button
    test bx, 2
    jnz .right_button_click  ; RMB = eraser
    
    ; LMB = color brush
    call draw_brush_color
    jmp .draw_done

.right_button_click:
    ; RMB = black eraser
    call draw_brush_eraser

.draw_done:
    ; Show mouse cursor again
    mov ax, 0001h
    int 33h
    
    jmp main_loop

; Color brush (3x3 square)
draw_brush_color:
    pusha
    mov cx, [mx]
    mov dx, [my]
    mov si, 3
.loop_y_norm:
    push cx
    mov di, 3
.loop_x_norm:
    mov ah, 0Ch
    mov al, [color]
    xor bh, bh
    int 10h
    inc cx
    dec di
    jnz .loop_x_norm
    pop cx
    inc dx
    dec si
    jnz .loop_y_norm
    popa
    ret

; Black eraser (6x6 square)
draw_brush_eraser:
    pusha
    mov cx, [mx]
    mov dx, [my]
    mov si, 6
.loop_y_black:
    push cx
    mov di, 6
.loop_x_black:
    mov ah, 0Ch
    mov al, 0
    xor bh, bh
    int 10h
    inc cx
    dec di
    jnz .loop_x_black
    pop cx
    inc dx
    dec si
    jnz .loop_y_black
    popa
    ret

; Draw top bar
draw_top_bar:
    pusha
    mov dx, 0
.line:
    mov cx, 0
.pixel:
    mov ah, 0Ch
    mov al, 0
    xor bh, bh
    int 10h
    inc cx
    cmp cx, 320
    jl .pixel
    inc dx
    cmp dx, 12
    jl .line
    
    ; Print title
    mov ah, 02h
    xor bh, bh
    mov dh, 0
    mov dl, 1
    int 10h
    
    mov si, title_msg
    call print_string_fix
    
    ; Print "Color: "
    mov ah, 02h
    xor bh, bh
    mov dh, 0
    mov dl, 20
    int 10h
    
    mov si, color_msg
    call print_string_fix
    popa
    ret

; Update and show current color
show_color:
    pusha
    mov ax, 0002h
    int 33h

    mov ah, 02h
    xor bh, bh
    mov dh, 0
    mov dl, 27
    int 10h
    
    ; Convert color code to ASCII
    mov al, [color]
    cmp al, 15
    je .print_w
    cmp al, 10
    jl .digit
    sub al, 10
    add al, 'A'
    jmp .print
.digit:
    add al, '0'
    jmp .print
.print_w:
    mov al, 'W'
.print:
    mov ah, 09h
    mov cx, 1
    mov bh, 0
    mov bl, 15
    int 10h
    
    mov ax, 0001h
    int 33h
    popa
    ret

; Print string in graphics mode
print_string_fix:
    lodsb
    cmp al, '$'
    je .done
    
    push si
    mov ah, 09h
    mov cx, 1
    mov bh, 0
    mov bl, 15
    int 10h
    pop si
    
    push si
    mov ah, 03h
    xor bh, bh
    int 10h
    inc dl
    mov ah, 02h
    int 10h
    pop si
    
    jmp print_string_fix
.done:
    ret

; Color handlers
col_white: mov byte [color], 15
    call show_color
    jmp main_loop
col1: mov byte [color], 1
    call show_color
    jmp main_loop
col2: mov byte [color], 10
    call show_color
    jmp main_loop
col3: mov byte [color], 3
    call show_color
    jmp main_loop
col4: mov byte [color], 4
    call show_color
    jmp main_loop
col5: mov byte [color], 5
    call show_color
    jmp main_loop
col6: mov byte [color], 6
    call show_color
    jmp main_loop
col7: mov byte [color], 7
    call show_color
    jmp main_loop
col8: mov byte [color], 13
    call show_color
    jmp main_loop
col9: mov byte [color], 14
    call show_color
    jmp main_loop

no_mouse:
    jmp exit

exit:
    mov ax, 0002h
    int 33h
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h

title_msg: db "YabroOS Paint$", 0
color_msg: db "Color: $", 0

mx: dw 0
my: dw 0
color: db 15
