; YabroOS Bootloader - (c) Ayano4ka1338, 2026
; Loads kernel from FAT12 floppy
[bits 16]
[org 0x7C00]

    jmp short _start
    nop

; BIOS Parameter Block
bpb_oem:        db 'YabroOS '   
bpb_bps:        dw 512
bpb_spc:        db 2
bpb_rsvd:       dw 1
bpb_nfats:      db 2
bpb_rootent:    dw 224
bpb_totsec:     dw 5760
bpb_media:      db 0xF0
bpb_spf:        dw 9
bpb_spt:        dw 36
bpb_heads:      dw 2
bpb_hidden:     dd 0
bpb_bigsec:     dd 0
bpb_drive:      db 0
bpb_rsvd2:      db 0
bpb_sig:        db 0x29
bpb_volid:      dd 0xDEAD1337
bpb_label:      db 'YabroOS    '
bpb_fstype:     db 'FAT12   '

; Memory addresses
FAT_BUF     equ 0x0500
ROOT_BUF    equ 0x1600
KERN_SEG    equ 0x2000

; FAT12 constants
FAT_SECS    equ 9
ROOT_SECS   equ 14
DATA_START  equ 33

_start:
    cli
    xor  ax, ax
    mov  ds, ax
    mov  es, ax
    mov  ss, ax
    mov  sp, 0x7C00
    sti
    mov  [bpb_drive], dl

    ; Reset disk
    xor  ah, ah
    int  0x13
    jc   .boot_err

    ; Load FAT
    mov  ax, 1
    call chs_from_lba
    mov  bx, FAT_BUF
    mov  ax, 0x0209
    mov  dl, [bpb_drive]
    int  0x13
    jc   .boot_err

    ; Load root directory
    mov  ax, 19
    call chs_from_lba
    mov  bx, ROOT_BUF
    mov  ax, 0x020E
    mov  dl, [bpb_drive]
    int  0x13
    jc   .boot_err

    ; Find KERNEL.BIN
    mov  di, ROOT_BUF
    mov  cx, 224
.scan:
    mov  al, [di]
    or   al, al
    jz   .not_found
    cmp  al, 0xE5
    je   .next_ent
    cmp  al, 0x0F
    je   .next_ent
    push cx
    push di
    mov  si, kern_name
    mov  cx, 11
    repe cmpsb
    pop  di
    pop  cx
    je   .found_kern
.next_ent:
    add  di, 32
    loop .scan

.not_found:
    mov  si, msg_nf
    call bputs
    jmp  .hang

.found_kern:
    mov  ax, [di + 26]
    mov  [cur_clust], ax
    xor  bx, bx

    ; Load kernel clusters
.load_loop:
    mov  ax, [cur_clust]
    cmp  ax, 0xFF8
    jae  .kern_done
    cmp  ax, 0
    je   .kern_done
    sub  ax, 2
    shl  ax, 1
    add  ax, DATA_START
    call chs_from_lba
    push es
    mov  ax, KERN_SEG
    mov  es, ax
    mov  ah, 0x02
    mov  al, 2
    mov  dl, [bpb_drive]
    int  0x13
    pop  es
    jc   .boot_err
    add  bx, 1024
    push bx
    mov  ax, [cur_clust]
    call fat12_next
    mov  [cur_clust], ax
    pop  bx
    cmp  ax, 0
    je   .kern_done
    jmp  .load_loop

.kern_done:
    mov  dl, [bpb_drive]
    jmp  KERN_SEG:0x0000

.boot_err:
    mov  si, msg_err
    call bputs
.hang:
    cli
    hlt
    jmp  .hang

; Convert LBA to CHS for 2.88MB (36 sectors/track)
chs_from_lba:
    push bx
    push ax
    mov  bx, 36
    xor  dx, dx
    div  bx
    inc  dx
    mov  cl, dl
    xor  dx, dx
    mov  bx, 2
    div  bx
    mov  ch, al
    mov  dh, dl
    pop  ax
    pop  bx
    ret

; Get next FAT12 cluster
fat12_next:
    push bx
    push dx
    mov  bx, ax
    shr  bx, 1
    add  bx, ax
    add  bx, FAT_BUF
    mov  dx, [bx]
    test ax, 1
    jz   .even
    shr  dx, 4
    jmp  .done
.even:
    and  dx, 0x0FFF
.done:
    mov  ax, dx
    pop  dx
    pop  bx
    ret

; Print string
bputs:
    lodsb
    or   al, al
    jz   .done
    mov  ah, 0x0E
    xor  bh, bh
    int  0x10
    jmp  bputs
.done:
    ret

kern_name:  db 'KERNEL  BIN'
cur_clust:  dw 0
msg_nf:     db 'KERNEL.BIN not found!', 13, 10, 0
msg_err:    db 'Disk error!', 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55
