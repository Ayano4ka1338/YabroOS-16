[org 0x0100]
[bits 16]

start:
    mov ah, 0x0E
    mov si, msg
print:
    lodsb
    cmp al, 0
    je done
    int 0x10
    jmp print
    
done:
    mov ah, 0x4C
    mov al, 0 
    int 0x21

msg db "Hello from COM file!", 13, 10, 0
