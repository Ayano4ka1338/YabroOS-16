; DOS INT 21h handler - (c) Ayano4ka1338, 2026
cmd_args_len:        db 0
cmd_args_buf:        times 128 db 0
file_handle_counter: dw 5
dos_dta:             dw 0, 0
kernel_ss:           dw 0
kernel_sp:           dw 0

dos_int_21:
    cmp ah, 0x4C
    je .exit
    cmp ah, 0x00
    je .exit

    push ds
    push es
    push bx
    push cx
    push dx
    push si
    push di

    mov bp, sp
    mov bl, ah
    mov ax, KERNEL_SEG
    mov ds, ax
    mov es, ax
    mov ah, bl

    ; Console I/O
    cmp ah, 0x01
    je .read_char_echo
    cmp ah, 0x02
    je .putchar
    cmp ah, 0x06
    je .raw_io
    cmp ah, 0x07
    je .raw_input
    cmp ah, 0x08
    je .read_no_echo
    cmp ah, 0x09
    je .puts
    cmp ah, 0x0A
    je .readline
    cmp ah, 0x0B
    je .check_input
    cmp ah, 0x0C
    je .clear_input
    
    ; Disk
    cmp ah, 0x0D
    je .disk_reset
    cmp ah, 0x0E
    je .select_disk
    cmp ah, 0x19
    je .current_disk
    cmp ah, 0x1A
    je .set_dta
    cmp ah, 0x1B
    je .get_fat_info
    cmp ah, 0x1C
    je .get_drive_data
    cmp ah, 0x36
    je .get_disk_space
    
    ; Date/Time
    cmp ah, 0x2A
    je .get_sys_date
    cmp ah, 0x2B
    je .set_sys_date
    cmp ah, 0x2C
    je .get_sys_time
    cmp ah, 0x2D
    je .set_sys_time
    
    ; Vectors
    cmp ah, 0x25
    je .set_int_vector
    cmp ah, 0x35
    je .get_int_vector
    
    ; File system
    cmp ah, 0x39
    je .mkdir
    cmp ah, 0x3A
    je .rmdir
    cmp ah, 0x3B
    je .chdir
    cmp ah, 0x3C
    je .create_file
    cmp ah, 0x3D
    je .file_open
    cmp ah, 0x3E
    je .file_close
    cmp ah, 0x3F
    je .file_read
    cmp ah, 0x40
    je .file_write
    cmp ah, 0x41
    je .unlink
    cmp ah, 0x42
    je .file_seek
    cmp ah, 0x43
    je .file_attr
    cmp ah, 0x44
    je .ioctl
    cmp ah, 0x45
    je .dup_handle
    cmp ah, 0x46
    je .redir_handle
    cmp ah, 0x47
    je .get_cwd
    cmp ah, 0x48
    je .alloc_mem
    cmp ah, 0x49
    je .free_mem
    cmp ah, 0x4A
    je .resize_mem
    cmp ah, 0x4B
    je .exec_prog
    cmp ah, 0x4D
    je .get_return_code
    cmp ah, 0x4E
    je .find_first
    cmp ah, 0x4F
    je .find_next
    cmp ah, 0x50
    je .set_psp
    cmp ah, 0x51
    je .get_psp_old
    cmp ah, 0x56
    je .rename
    cmp ah, 0x57
    je .get_file_time
    cmp ah, 0x62
    je .get_psp

.default_ret:
    pushf
    pop ax
    and ax, 0xFFFE
    push ax
    popf
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop es
    pop ds
    iret

.exit:
    cli
    mov ax, KERNEL_SEG
    mov ds, ax
    mov es, ax
    mov ss, word [kernel_ss]
    mov sp, word [kernel_sp]
    sti
    jmp main_loop

.read_char_echo:
    xor ah, ah
    int 0x16
    jmp .default_ret

.putchar:
    mov ah, 0x0E
    mov al, dl
    int 0x10
    jmp .default_ret

.raw_io:
    test dl, dl
    jnz .raw_out
    xor ah, ah
    int 0x16
    jmp .default_ret
.raw_out:
    mov ah, 0x0E
    mov al, dl
    int 0x10
    jmp .default_ret

.raw_input:
    xor ah, ah
    int 0x16
    jmp .default_ret

.read_no_echo:
    xor ah, ah
    int 0x16
    jmp .default_ret

.puts:
    mov ax, [bp + 12]
    push ds
    mov ds, ax
    mov si, dx
.puts_l:
    lodsb
    cmp al, '$'
    je .puts_done
    mov ah, 0x0E
    int 0x10
    jmp .puts_l
.puts_done:
    pop ds
    jmp .default_ret

.readline:
    mov ax, [bp + 12]
    push es
    mov es, ax
    mov di, dx
    mov cl, [es:di]
    xor ch, ch
    inc di
.rl_l:
    xor ah, ah
    int 0x16
    cmp al, 0x0D
    je .rl_done
    cmp al, 0x08
    je .rl_bs
    or cx, cx
    jz .rl_l
    mov [es:di], al
    inc di
    dec cx
    mov ah, 0x0E
    int 0x10
    jmp .rl_l
.rl_bs:
    mov ax, dx
    inc ax
    cmp di, ax
    je .rl_l
    dec di
    inc cx
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .rl_l
.rl_done:
    mov ax, di
    sub ax, dx
    dec ax
    mov si, dx
    mov [es:si + 1], al
    mov byte [es:di], 0x0D
    pop es
    jmp .default_ret

.check_input:
    mov ah, 0x01
    int 0x16
    jz .no_input
    mov ax, 0xFFFF
    jmp .check_done
.no_input:
    xor ax, ax
.check_done:
    jmp .default_ret

.clear_input:
    jmp .default_ret

.disk_reset:
    jmp .default_ret

.select_disk:
    xor ax, ax
    jmp .default_ret

.current_disk:
    xor al, al
    jmp .default_ret

.set_dta:
    mov word [dos_dta], dx
    mov ax, [bp + 12]
    mov word [dos_dta+2], ax
    jmp .default_ret

.get_fat_info:
    mov ax, word [dos_dta]
    mov bx, 0x0200
    mov cl, 0x09
    mov dl, byte [boot_drive]
    jmp .default_ret

.get_drive_data:
    mov ax, word [dos_dta]
    jmp .default_ret

.get_disk_space:
    mov ax, 1
    mov bx, 2847
    mov cx, 512
    mov dx, 2847
    jmp .default_ret

.get_sys_date:
    xor ax, ax
    mov cx, 0x0720
    xor dx, dx
    jmp .default_ret

.set_sys_date:
    jmp .default_ret

.get_sys_time:
    xor ax, ax
    xor cx, cx
    xor dx, dx
    jmp .default_ret

.set_sys_time:
    jmp .default_ret

.set_int_vector:
    push bp
    mov bp, sp
    pusha
    push es
    xor ax, ax
    mov es, ax
    mov ax, bx
    shl ax, 1
    shl ax, 1
    mov bx, ax
    mov [es:bx], dx
    mov ax, [bp + 14]
    mov [es:bx+2], ax
    pop es
    popa
    pop bp
    jmp .default_ret

.get_int_vector:
    xor ax, ax
    mov es, ax
    push bx
    shl bx, 1
    shl bx, 1
    mov ax, [es:bx]
    mov dx, ax
    mov ax, [es:bx+2]
    pop bx
    jmp .default_ret

.create_file:
    inc word [file_handle_counter]
    mov ax, word [file_handle_counter]
    mov bx, bp
    mov [bx + 8], ax
    jmp .default_ret

.file_open:
    mov ax, [bp + 12]
    push ds
    mov ds, ax
    mov si, dx
    mov ax, KERNEL_SEG
    mov es, ax
    call copy_str_to_temp
    call convert_name_si
    pop ds
    call find_file
    jnc .file_open_err
    inc word [file_handle_counter]
    mov ax, word [file_handle_counter]
    mov bx, bp
    mov [bx + 8], ax
    jmp .default_ret
.file_open_err:
    mov ax, 0x0002
    mov bx, bp
    mov [bx + 8], ax
    or word [bp + 18], 0x0001
    jmp .default_ret

.file_read:
    push ds
    push es
    call load_file_by_cluster
    mov ax, KERNEL_SEG
    mov ds, ax
    mov si, file_buffer
    mov ax, [bp + 12]
    mov es, ax
    mov di, dx
    mov cx, word [current_file_size]
    cld
    rep movsb
    mov ax, word [current_file_size]
    mov bx, bp
    mov [bx + 8], ax
    pop es
    pop ds
    jmp .default_ret

.file_close:
    jmp .default_ret

.file_seek:
    jmp .default_ret

.file_write:
    push es
    mov ax, [bp + 12]
    mov es, ax
    mov di, dx
    mov ax, cx
    mov bx, KERNEL_SEG
    mov ds, bx
    mov si, temp_data
    cld
    rep movsb
    mov ax, word [current_file_cluster]
    cmp ax, 2
    jae .fw_have_cluster
    call find_free_cluster
    cmp ax, 0
    je .fw_disk_full
    push ax
    mov dx, 0x0FFF
    call set_fat12_entry
    pop ax
    mov word [current_file_cluster], ax
.fw_have_cluster:
    mov ax, word [current_file_cluster]
    call cluster_to_sector
    call lba_to_chs
    mov bx, temp_data
    mov ah, 0x03
    mov al, CLUSTER_SIZE
    mov dl, byte [boot_drive]
    int 0x13
    mov ax, cx
    mov bx, bp
    mov [bx + 8], ax
    pop es
    jmp .default_ret
.fw_disk_full:
    xor ax, ax
    mov bx, bp
    mov [bx + 8], ax
    or word [bp + 18], 0x0001
    pop es
    jmp .default_ret

.unlink:
    jmp .default_ret

.file_attr:
    xor ax, ax
    mov bx, bp
    mov [bx + 8], ax
    jmp .default_ret

.ioctl:
    jmp .default_ret

.dup_handle:
    mov ax, bx
    jmp .default_ret

.redir_handle:
    jmp .default_ret

.get_cwd:
    push bx
    mov bx, dx
    mov byte [bx], 'C'
    mov byte [bx+1], ':'
    mov byte [bx+2], 0
    pop bx
    jmp .default_ret

.alloc_mem:
    mov ax, 0x8000
    jmp .default_ret

.free_mem:
    jmp .default_ret

.resize_mem:
    jmp .default_ret

.exec_prog:
    jmp .default_ret

.get_return_code:
    xor ax, ax
    xor cx, cx
    jmp .default_ret

.find_first:
    xor ax, ax
    mov bx, bp
    mov [bx + 8], ax
    jmp .default_ret

.find_next:
    xor ax, ax
    mov bx, bp
    mov [bx + 8], ax
    jmp .default_ret

.set_psp:
    jmp .default_ret

.get_psp_old:
.get_psp:
    mov ax, PROG_SEG
    jmp .default_ret

.rename:
    jmp .default_ret

.get_file_time:
    xor ax, ax
    xor cx, cx
    xor dx, dx
    jmp .default_ret

.mkdir:
.rmdir:
.chdir:
    jmp .default_ret

install_dos_hooks:
    pusha
    push es
    xor  ax, ax
    mov  es, ax
    mov  word [es:0x21*4],   dos_int_21
    mov  word [es:0x21*4+2], KERNEL_SEG
    pop  es
    popa
    ret
