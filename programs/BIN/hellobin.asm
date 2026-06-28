[org 0x0000]
[bits 16]

start:
    mov si, msg
    call print
    jmp exit

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

exit:
    mov ax, 0x4C00
    int 0x21

msg: db "Hello from BIN!", 13, 10, 0
