; Shared utility functions - (c) Ayano4ka1338, 2026

; Compare string prefix
strcmp_prefix:
    pusha
.lp:
    mov al, [di]
    or al, al
    jz .match
    mov bl, [si]
    cmp al, bl
    jne .no
    inc si
    inc di
    jmp .lp
.match:
    popa
    stc
    ret
.no:
    popa
    clc
    ret

; Skip spaces in SI
skip_spaces_si:
    cmp byte [si], ' '
    jne .done
    inc si
    jmp skip_spaces_si
.done:
    ret

; Get string to custom buffer
get_string_to:
    push ax
    push cx
    push di
    push si
    push bx
    mov word [.dst], di
    xor cx, cx
.lp:
    xor ah, ah
    int 0x16
    cmp al, 0x0D
    je .done
    cmp al, 0x08
    je .bs
    cmp cx, 62
    je .lp
    mov ah, 0x0E
    int 0x10
    mov di, word [.dst]
    add di, cx
    mov [di], al
    inc cx
    jmp .lp
.bs:
    or cx, cx
    jz .lp
    dec cx
    mov ah, 0x0E
    mov al, 8
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 8
    int 0x10
    jmp .lp
.done:
    mov di, word [.dst]
    add di, cx
    mov byte [di], 0
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    pop bx
    pop si
    pop di
    pop cx
    pop ax
    ret
.dst: dw 0

; Create directory
cmd_mkdir_handler:
    pusha
    mov si, input_buffer + 6
    call skip_spaces
    mov di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov si, temp_name_83
    call find_file
    jc .exists
    
    call find_free_entry
    jnc .full
    
    call find_free_cluster
    cmp ax, 0
    je .full
    
    push ax
    mov dx, 0x0FFF
    call set_fat12_entry
    pop ax
    
    mov di, word [current_file_entry]
    mov si, temp_name_83
    mov cx, 11
    rep movsb
    
    mov di, word [current_file_entry]
    mov byte [di + 11], 0x10
    mov word [di + 26], ax
    mov word [di + 28], 0
    mov word [di + 30], 0
    
    push ax
    call init_directory
    pop ax
    
    call save_directory
    call save_fat
    
    mov si, mkdir_ok_msg
    call print_string
    popa
    ret
.exists:
    mov si, file_exists_msg
    call print_string
    popa
    ret
.full:
    mov si, fs_full_msg
    call print_string
    popa
    ret

; Initialize empty directory with . and ..
init_directory:
    pusha
    push es
    
    mov ax, KERNEL_SEG
    mov es, ax
    
    mov di, temp_data
    mov cx, 512 * CLUSTER_SIZE
    xor al, al
    rep stosb
    
    pop ax
    push ax
    
    mov di, temp_data
    mov byte [di], '.'
    mov byte [di+1], ' '
    mov byte [di+2], ' '
    mov byte [di+3], ' '
    mov byte [di+4], ' '
    mov byte [di+5], ' '
    mov byte [di+6], ' '
    mov byte [di+7], ' '
    mov byte [di+8], ' '
    mov byte [di+9], ' '
    mov byte [di+10], ' '
    mov byte [di+11], 0x10
    mov word [di+26], ax
    
    add di, 32
    mov byte [di], '.'
    mov byte [di+1], '.'
    mov byte [di+2], ' '
    mov byte [di+3], ' '
    mov byte [di+4], ' '
    mov byte [di+5], ' '
    mov byte [di+6], ' '
    mov byte [di+7], ' '
    mov byte [di+8], ' '
    mov byte [di+9], ' '
    mov byte [di+10], ' '
    mov byte [di+11], 0x10
    
    mov bx, word [parent_dir_cluster]
    mov word [di+26], bx
    
    pop es
    popa
    ret

; Change directory
cmd_cd_handler:
    pusha
    mov si, input_buffer + 2
    call skip_spaces
    cmp byte [si], 0
    jne .not_root
    
    mov byte [current_directory], 0
    mov word [current_dir_cluster], 0
    mov word [parent_dir_cluster], 0
    call load_root
    mov si, cd_ok_msg
    call print_string
    popa
    ret
    
.not_root:
    cmp byte [si], '.'
    jne .check_dir
    cmp byte [si+1], '.'
    jne .check_dir
    cmp byte [si+2], 0
    je .go_up
    cmp byte [si+2], ' '
    je .go_up
    jmp .check_dir
    
.go_up:
    cmp word [current_dir_cluster], 0
    je .already_root
    
    mov ax, word [parent_dir_cluster]
    mov word [current_dir_cluster], ax
    call load_directory
    
    mov di, root_buffer
    mov cx, 224
.find_parent:
    mov al, [di]
    cmp al, 0xE5
    je .skip_parent
    cmp al, 0
    je .parent_root
    
    cmp byte [di], '.'
    jne .skip_parent
    cmp byte [di+1], '.'
    jne .skip_parent
    cmp byte [di+2], ' '
    jne .skip_parent
    
    mov ax, word [di + 26]
    mov word [parent_dir_cluster], ax
    jmp .cd_done
    
.skip_parent:
    add di, 32
    loop .find_parent
    
.parent_root:
    mov word [parent_dir_cluster], 0
    
.cd_done:
    mov si, cd_ok_msg
    call print_string
    popa
    ret
    
.already_root:
    mov si, already_root_msg
    call print_string
    popa
    ret
    
.check_dir:
    mov di, temp_name
    call copy_str_to_temp
    call convert_name_si
    
    mov si, temp_name_83
    call find_file
    jnc .not_found
    
    mov di, word [current_file_entry]
    mov al, [di + 11]
    test al, 0x10
    jz .not_dir
    
    mov ax, word [current_dir_cluster]
    mov word [parent_dir_cluster], ax
    
    mov byte [current_directory], 1
    mov ax, word [current_file_cluster]
    mov word [current_dir_cluster], ax
    call load_directory
    
    mov si, cd_ok_msg
    call print_string
    popa
    ret
    
.not_dir:
    mov si, not_dir_msg
    call print_string
    popa
    ret
    
.not_found:
    mov si, file_not_found_msg
    call print_string
    popa
    ret

; Copy file
cmd_cp_handler:
    pusha
    mov si, input_buffer + 3
    call skip_spaces
    mov di, temp_name
.copy_src:
    mov al, [si]
    cmp al, ' '
    je .src_done
    or al, al
    jz .no_dst
    mov [di], al
    inc si
    inc di
    jmp .copy_src
.src_done:
    mov byte [di], 0
    call skip_spaces
    mov di, temp_name_dst
.copy_dst:
    mov al, [si]
    or al, al
    jz .dst_done
    mov [di], al
    inc si
    inc di
    jmp .copy_dst
.dst_done:
    mov byte [di], 0
    
    mov si, temp_name
    mov di, temp_name_83
    call copy_str_to_temp
    call convert_name_si
    
    mov si, temp_name_83
    call find_file
    jnc .src_not_found
    
    mov ax, word [current_file_cluster]
    mov word [.src_cluster], ax
    mov ax, word [current_file_size]
    mov word [.src_size], ax
    
    call load_file_by_cluster
    
    mov si, temp_name_dst
    mov di, temp_name
    call copy_str_to_temp
    call convert_name_si
    
    mov si, temp_name_83
    call find_file
    jc .dst_exists
    
    call find_free_entry
    jnc .full
    
    call find_free_cluster
    cmp ax, 0
    je .full
    
    push ax
    mov dx, 0x0FFF
    call set_fat12_entry
    pop ax
    
    mov di, word [current_file_entry]
    mov si, temp_name_83
    mov cx, 11
    rep movsb
    
    mov di, word [current_file_entry]
    mov byte [di + 11], 0x20
    mov word [di + 26], ax
    mov bx, word [.src_size]
    mov word [di + 28], bx
    
    mov word [current_file_cluster], ax
    mov ax, word [.src_size]
    mov word [current_file_size], ax
    call save_file_by_cluster
    call save_directory
    call save_fat
    
    mov si, cp_ok_msg
    call print_string
    popa
    ret
    
.src_not_found:
    mov si, file_not_found_msg
    call print_string
    popa
    ret
    
.dst_exists:
    mov si, file_exists_msg
    call print_string
    popa
    ret
    
.full:
    mov si, fs_full_msg
    call print_string
    popa
    ret
    
.no_dst:
    mov si, invalid_cmd_msg
    call print_string
    popa
    ret

.src_cluster: dw 0
.src_size: dw 0

; Try to run input as file
try_run_as_file:
    push ax
    push si
    push di
    mov si, input_buffer
    mov di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov si, temp_name_83
    call find_file
    jnc .not_found
    call load_file_by_cluster
    mov al, byte [current_file_type]
    cmp al, 1
    je .is_com
    cmp al, 2
    je .is_exe
    cmp al, 3
    je .is_bin
    pop di
    pop si
    pop ax
    clc
    ret
.is_com:
    call run_com_file
    pop di
    pop si
    pop ax
    stc
    ret
.is_exe:
    call run_exe_file
    pop di
    pop si
    pop ax
    stc
    ret
.is_bin:
    call run_bin_file
    pop di
    pop si
    pop ax
    stc
    ret
.not_found:
    pop di
    pop si
    pop ax
    clc
    ret

; List files in current directory
list_files:
    pusha
    call load_directory
    
    mov si, list_header
    call print_string
    mov di, root_buffer
    mov cx, 224
    xor bx, bx
.loop:
    mov al, [di]
    or al, al
    jz .done
    cmp al, 0xE5
    je .next
    cmp al, 0x0F
    je .next
    
    mov al, [di + 11]
    test al, 0x08
    jnz .next
    test al, 0x04
    jnz .next
    
    inc bx
    mov ax, bx
    call print_ax
    mov ah, 0x0E
    mov al, '.'
    int 0x10
    mov al, ' '
    int 0x10
    
    push di
    mov cx, 8
.name:
    mov al, [di]
    cmp al, ' '
    je .nsp
    cmp al, 0
    je .nsp
    mov ah, 0x0E
    int 0x10
.nsp:
    inc di
    loop .name
    pop di
    
    push di
    add di, 8
    mov al, [di]
    cmp al, ' '
    je .noext
    cmp al, 0
    je .noext
    
    mov ah, 0x0E
    mov al, '.'
    int 0x10
    
    mov cx, 3
.ext:
    mov al, [di]
    cmp al, ' '
    je .esp
    cmp al, 0
    je .esp
    mov ah, 0x0E
    int 0x10
.esp:
    inc di
    loop .ext
.noext:
    pop di
    
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    mov al, ' '
    int 0x10
    mov al, ' '
    int 0x10
    mov al, ' '
    int 0x10
    mov al, ' '
    int 0x10
    
    mov al, [di + 11]
    test al, 0x10
    jz .show_size
    
    mov ah, 0x0E
    mov al, '['
    int 0x10
    mov al, 'D'
    int 0x10
    mov al, 'I'
    int 0x10
    mov al, 'R'
    int 0x10
    mov al, ']'
    int 0x10
    jmp .next

.show_size:
    mov ax, word [di + 28]
    call print_ax
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    mov al, 'B'
    int 0x10
    
.next:
    mov si, newline
    call print_string
    add di, 32
    dec cx
    jnz .loop
.done:
    cmp bx, 0
    jne .exit
    mov si, no_files_msg
    call print_string
.exit:
    popa
    ret

; Dump sector in hex
dump_sector:
    pusha
    mov si, dump_prompt
    call print_string
    call read_number
    push es
    mov ax, KERNEL_SEG
    mov es, ax
    call lba_to_chs
    mov bx, temp_data
    mov ah, 0x02
    mov al, 1
    mov dl, byte [boot_drive]
    int 0x13
    pop es
    jnc .ok
    mov si, disk_error_msg
    call print_string
    popa
    ret
.ok:
    mov si, temp_data
    mov cx, 32
.lp:
    lodsb
    call print_hex_byte
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    loop .lp
    mov si, newline
    call print_string
    popa
    ret

; Run raw sector
run_sector:
    pusha
    mov si, run_prompt
    call print_string
    call read_number
    cmp ax, TOTAL_SECTORS
    ja .invalid
    push es
    mov bx, PROG_SEG
    mov es, bx
    xor bx, bx
    call lba_to_chs
    mov ah, 0x02
    mov al, 1
    mov dl, byte [boot_drive]
    int 0x13
    pop es
    jc .derr
    mov si, running_msg
    call print_string
    push PROG_SEG
    push 0x0000
    retf
.invalid:
    mov si, invalid_sector_msg
    call print_string
    popa
    ret
.derr:
    mov si, disk_error_msg
    call print_string
    popa
    ret

; Reboot system
system_reboot:
    mov si, reboot_msg
    call print_string
    xor ah, ah
    int 0x16
    jmp 0xFFFF:0x0000

; Shutdown system
do_shutdown:
    pusha
    mov si, shutdown_msg
    call print_string
    mov ax, 0x5300
    xor bx, bx
    int 0x15
    jc .try_qemu
    mov ax, 0x5301
    xor bx, bx
    int 0x15
    jc .try_qemu
    mov ax, 0x530E
    xor bx, bx
    mov cx, 0x0102
    int 0x15
    jc .try_qemu
    mov ax, 0x5308
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    jc .try_qemu
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    jnc .halt
.try_qemu:
    mov ax, 0x2000
    mov dx, 0x604
    out dx, ax
.halt:
    cli
    hlt
    jmp .halt

; Tone command handler
cmd_tone_handler:
    pusha
    mov si, input_buffer + 5
    call skip_spaces
    call parse_uint
    mov word [play_tone.freq], ax
    mov word [play_tone.duration], 200
    call play_tone
    popa
    ret

show_help:
    mov si, help_text
    call print_string
    ret
