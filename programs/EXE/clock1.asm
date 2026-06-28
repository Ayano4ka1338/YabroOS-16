; YabroOS clock - (c) Ayano4ka1338, 2026
format MZ
entry main_seg:start
stack 200h

segment main_seg
start:
    mov ax, cs
    mov ds, ax

.loop:
    ; Read hours from CMOS reg 4
    mov al, 4
    out 0x70, al
    in al, 0x71
    mov [hours], al

    ; Read minutes from CMOS reg 2
    mov al, 2
    out 0x70, al
    in al, 0x71
    mov [minutes], al

    ; Read seconds from CMOS reg 0
    mov al, 0
    out 0x70, al
    in al, 0x71
    mov [seconds], al
    
    ; Convert BCD to binary, add 3 hours (UTC to MSK)
    mov al, [hours]
    
    mov bl, al
    shr bl, 4
    mov bh, 10
    mov al, bl
    mul bh
    mov bl, [hours]
    and bl, 0x0F
    add al, bl

    add al, 3
    cmp al, 24
    jb .no_day_overflow
    sub al, 24

.no_day_overflow:
    xor ah, ah
    mov bl, 10
    div bl
    shl al, 4
    or al, ah
    mov [hours], al

    ; Move cursor to top right (row 0, col 70)
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 70
    int 0x10

    ; Print hours
    mov al, [hours]
    call print_bcd_byte

    mov al, ':'
    call print_char

    ; Print minutes
    mov al, [minutes]
    call print_bcd_byte

    mov al, ':'
    call print_char

    ; Print seconds
    mov al, [seconds]
    call print_bcd_byte

    ; Wait for BIOS tick to avoid spamming
    push es
    mov ax, 0x0040
    mov es, ax
    mov ax, [es:0x006C]
.wait_tick:
    cmp ax, [es:0x006C]
    je .wait_tick
    pop es

    ; Check if key pressed to exit
    mov ah, 0x01
    int 0x16
    jz .loop

    ; Flush keyboard buffer
    xor ah, ah
    int 0x16

    ; Return to YabroOS
    mov ax, 0x4C00
    int 0x21

; Print BCD byte as two ASCII digits
print_bcd_byte:
    push ax
    shr al, 4
    add al, '0'
    call print_char
    pop ax
    and al, 0x0F
    add al, '0'
    call print_char
    ret

; Print single character via BIOS
print_char:
    pusha
    mov ah, 0x0E
    int 0x10
    popa
    ret

; Time storage
hours:   db 0
minutes: db 0
seconds: db 0
