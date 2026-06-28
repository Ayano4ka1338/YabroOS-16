; PS/2 and DOS mouse driver - (c) Ayano4ka1338, 2026
mouse_status:   db 0
mouse_dx:       db 0
mouse_dy:       db 0
mouse_x:        dw 160
mouse_y:        dw 100
mouse_buttons:  dw 0
mouse_enabled:  dw 0
mouse_moved:    dw 0
old_mouse_int:  dd 0
mouse_irq_installed: db 0
mouse_found:    dw 0
mouse_dos_mode: dw 1
mouse_timeout:  dw 0
mouse_init_retries: db 3

mouse_ok_msg:   db "Mouse detected", 13, 10, 0
mouse_no_msg:   db "No mouse found", 13, 10, 0

; Initialize mouse - try DOS first, then PS/2
init_mouse:
    pusha
    push es
    
    ; DOS mouse (INT 33h)
    mov ax, 0x0000
    int 0x33
    cmp ax, 0xFFFF
    jne .try_ps2
    
    mov word [mouse_enabled], 1
    mov word [mouse_found], 1
    mov word [mouse_dos_mode], 1
    mov ax, 0x0001
    int 0x33
    mov si, mouse_ok_msg
    call print_string
    pop es
    popa
    ret
    
.try_ps2:
    call init_ps2_mouse_safe
    pop es
    popa
    ret

; PS/2 mouse initialization
init_ps2_mouse_safe:
    pusha
    cli
    
    mov byte [.retries], 3
    
.retry_loop:
    ; Disable mouse
    mov al, 0xA7
    out 0x64, al
    call wait_ps2_write_safe
    
    ; Clear buffer
    mov cx, 100
.clear_buf:
    in al, 0x64
    test al, 0x01
    jz .clear_done
    in al, 0x60
    loop .clear_buf
    
.clear_done:
    ; Enable mouse
    mov al, 0xA8
    out 0x64, al
    call wait_ps2_write_safe
    
    ; Read config
    mov al, 0x20
    out 0x64, al
    call wait_ps2_read_safe
    jc .ps2_fail
    
    in al, 0x60
    or al, 0x02
    mov ah, al
    
    ; Write config
    mov al, 0x60
    out 0x64, al
    call wait_ps2_write_safe
    
    mov al, ah
    out 0x60, al
    call wait_ps2_write_safe
    
    ; Reset mouse
    mov al, 0xD4
    out 0x64, al
    call wait_ps2_write_safe
    
    mov al, 0xFF
    out 0x60, al
    call wait_ps2_read_safe
    jc .ps2_fail
    
    in al, 0x60
    cmp al, 0xFA
    jne .ps2_fail
    
    call wait_ps2_read_safe
    jc .ps2_fail
    
    in al, 0x60
    cmp al, 0xAA
    jne .ps2_fail
    
    ; Enable mouse
    mov al, 0xD4
    out 0x64, al
    call wait_ps2_write_safe
    
    mov al, 0xF4
    out 0x60, al
    call wait_ps2_read_safe
    jc .ps2_fail
    
    in al, 0x60
    cmp al, 0xFA
    jne .ps2_fail
    
    call install_mouse_irq
    
    mov word [mouse_enabled], 1
    mov word [mouse_found], 1
    mov word [mouse_dos_mode], 0
    mov si, mouse_ok_msg
    call print_string
    jmp .ps2_done
    
.ps2_fail:
    dec byte [.retries]
    cmp byte [.retries], 0
    je .ps2_complete_fail
    jmp .retry_loop
    
.ps2_complete_fail:
    mov word [mouse_enabled], 0
    mov word [mouse_found], 0
    mov si, mouse_no_msg
    call print_string
    
.ps2_done:
    sti
    popa
    ret

.retries: db 0

; Wait for PS/2 controller ready to write
wait_ps2_write_safe:
    push ax
    push cx
    mov cx, 10000
.wait:
    in al, 0x64
    test al, 0x02
    jz .ready
    loop .wait
    pop cx
    pop ax
    ret
.ready:
    pop cx
    pop ax
    ret

; Wait for PS/2 data ready to read
wait_ps2_read_safe:
    push ax
    push cx
    mov cx, 10000
.wait:
    in al, 0x64
    test al, 0x01
    jnz .ready
    loop .wait
    stc
    pop cx
    pop ax
    ret
.ready:
    clc
    pop cx
    pop ax
    ret

; Install IRQ12 handler for PS/2 mouse
install_mouse_irq:
    pusha
    push es
    cli
    
    xor ax, ax
    mov es, ax
    
    mov ax, [es:0x70*4]
    mov word [old_mouse_int], ax
    mov ax, [es:0x70*4+2]
    mov word [old_mouse_int+2], ax
    
    mov word [es:0x70*4], mouse_handler
    mov word [es:0x70*4+2], KERNEL_SEG
    
    in al, 0x21
    and al, 0xEF
    out 0x21, al
    
    mov byte [mouse_irq_installed], 1
    sti
    
    pop es
    popa
    ret

; Restore original IRQ12 handler
restore_mouse_irq:
    pusha
    push es
    
    cmp byte [mouse_irq_installed], 0
    je .done
    
    cli
    xor ax, ax
    mov es, ax
    
    mov ax, word [old_mouse_int]
    mov [es:0x70*4], ax
    mov ax, word [old_mouse_int+2]
    mov [es:0x70*4+2], ax
    
    mov byte [mouse_irq_installed], 0
    sti
    
.done:
    pop es
    popa
    ret

; PS/2 mouse IRQ handler
mouse_handler:
    pusha
    push ds
    push es
    
    mov ax, KERNEL_SEG
    mov ds, ax
    mov es, ax
    
    in al, 0x60
    mov byte [mouse_status], al
    
    test al, 0x08
    jnz .done
    
    in al, 0x60
    mov byte [mouse_dx], al
    
    in al, 0x60
    mov byte [mouse_dy], al
    
    mov al, byte [mouse_status]
    and al, 0x07
    mov byte [mouse_buttons], al
    
    movsx ax, byte [mouse_dx]
    add word [mouse_x], ax
    
    movsx ax, byte [mouse_dy]
    sub word [mouse_y], ax
    
    ; Clamp X
    cmp word [mouse_x], 0
    jge .x_ok
    mov word [mouse_x], 0
.x_ok:
    cmp word [mouse_x], 319
    jle .x_ok2
    mov word [mouse_x], 319
.x_ok2:
    
    ; Clamp Y
    cmp word [mouse_y], 0
    jge .y_ok
    mov word [mouse_y], 0
.y_ok:
    cmp word [mouse_y], 199
    jle .y_ok2
    mov word [mouse_y], 199
.y_ok2:
    
    mov word [mouse_moved], 1
    
.done:
    mov al, 0x20
    out 0x20, al
    
    pop es
    pop ds
    popa
    iret
