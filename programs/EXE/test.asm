; fasm code
format MZ

entry code_seg:start
stack 400h

segment code_seg
start:
    mov ax, data_seg
    mov ds, ax
    mov ah, 0x09
    mov dx, hello_msg
    int 0x21
    mov ax, 0x4C00
    int 0x21

segment data_seg
    hello_msg db "Hello from true MZ EXE!", 13, 10, "$"
    db 512 dup (0) 
