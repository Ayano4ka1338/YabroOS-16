; File commands - (c) Ayano4ka1338, 2026
cmd_create_handler:
    pusha
    mov  si, input_buffer + 7
    call skip_spaces
    mov  di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov  si, temp_name_83
    call find_file
    jc   .exists
    call find_free_entry
    jnc  .full
    call create_root_entry
    mov  si, file_created_msg
    call print_string
    popa
    ret
.exists:
    mov  si, file_exists_msg
    call print_string
    popa
    ret
.full:
    mov  si, fs_full_msg
    call print_string
    popa
    ret

cmd_write_handler:
    pusha
    mov  si, input_buffer + 6
    call skip_spaces
    mov  di, temp_name
.cp_name:
    mov  al, [si]
    or   al, al
    jz   .no_content
    cmp  al, ' '
    je   .name_done
    mov  [di], al
    inc  si
    inc  di
    jmp  .cp_name
.name_done:
    mov  byte [di], 0
    call skip_spaces
    call convert_name_si
    mov  bx, si
    mov  si, temp_name_83
    call find_file
    jnc  .not_found
    push bx
    pop  si
    mov  di, temp_data
    xor  cx, cx
.wcp:
    lodsb
    or   al, al
    jz   .wcp_done
    mov  [di], al
    inc  di
    inc  cx
    cmp  cx, 512 * CLUSTER_SIZE
    je   .wcp_done
    jmp  .wcp
.wcp_done:
    mov  ax, word [current_file_cluster]
    cmp  ax, 2
    jae  .have_cluster
    call find_free_cluster
    cmp  ax, 0
    je   .disk_full
    push ax
    mov  dx, 0x0FFF
    call set_fat12_entry
    pop  ax
    mov  word [current_file_cluster], ax
.have_cluster:
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  ax, word [current_file_cluster]
    call cluster_to_sector
    call lba_to_chs
    mov  bx, temp_data
    mov  ah, 0x03
    mov  al, CLUSTER_SIZE
    mov  dl, byte [boot_drive]
    int  0x13
    pop  es
    mov  di, word [current_file_entry]
    mov  word [di + 28], cx
    mov  word [di + 30], 0
    call save_directory
    call save_fat
    mov  si, file_written_msg
    call print_string
    popa
    ret
.no_content:
    mov  byte [di], 0
    call convert_name_si
.not_found:
    mov  si, file_not_found_msg
    call print_string
    popa
    ret
.disk_full:
    mov  si, fs_full_msg
    call print_string
    popa
    ret

cmd_type_handler:
    pusha
    mov  si, input_buffer + 5
    call skip_spaces
    mov  di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov  si, temp_name_83
    call find_file
    jnc  .not_found
    call load_file_by_cluster
    mov  si, file_buffer
    mov  cx, word [current_file_size]
    cmp  cx, 8192
    jbe  .pr
    mov  cx, 8192
.pr:
    or   cx, cx
    jz   .done
    lodsb
    cmp  al, 0x0A
    je   .nl
    cmp  al, 0x0D
    je   .cr
    cmp  al, 0x20
    jb   .skip
    cmp  al, 0x7E
    ja   .skip
    mov  ah, 0x0E
    int  0x10
    jmp  .next
.nl:
    mov  ah, 0x0E
    int  0x10
    jmp  .next
.cr:
    mov  ah, 0x0E
    int  0x10
    jmp  .next
.skip:
.next:
    dec  cx
    jnz  .pr
.done:
    mov  si, newline
    call print_string
    popa
    ret
.not_found:
    mov  si, file_not_found_msg
    call print_string
    popa
    ret

cmd_del_handler:
    pusha
    mov  si, input_buffer + 4
    call skip_spaces
    mov  di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov  si, temp_name_83
    call find_file
    jnc  .not_found
    mov  ax, word [current_file_cluster]
.free_chain:
    cmp  ax, 2
    jb   .chain_done
    cmp  ax, 0xFF8
    jae  .chain_done
    push ax
    call get_fat12_entry
    mov  bx, ax
    pop  ax
    push bx
    xor  dx, dx
    call set_fat12_entry
    pop  ax
    jmp  .free_chain
.chain_done:
    mov  di, word [current_file_entry]
    mov  byte [di], 0xE5
    call save_directory
    call save_fat
    mov  si, file_deleted_msg
    call print_string
    popa
    ret
.not_found:
    mov  si, file_not_found_msg
    call print_string
    popa
    ret

cmd_rename_handler:
    pusha
    mov  si, input_buffer + 7
    call skip_spaces
    mov  di, temp_name
.cp_old:
    mov  al, [si]
    or   al, al
    jz   .not_found
    cmp  al, ' '
    je   .old_done
    mov  [di], al
    inc  si
    inc  di
    jmp  .cp_old
.old_done:
    mov  byte [di], 0
    call convert_name_si
    mov  bx, si
    push bx
    mov  si, temp_name_83
    call find_file
    pop  si
    jnc  .not_found
    push word [current_file_entry]
    call skip_spaces    
    mov  di, temp_name
.cp_new:
    mov  al, [si]
    or   al, al
    jz   .rename_done
    cmp  al, ' '
    je   .rename_done
    mov  [di], al
    inc  si
    inc  di
    jmp  .cp_new
.rename_done:
    mov  byte [di], 0
    call convert_name_si
    pop  di
    mov  si, temp_name_83
    mov  cx, 11
    rep  movsb
    call save_directory
    mov  si, file_renamed_msg
    call print_string
    popa
    ret
.not_found:
    mov  si, file_not_found_msg
    call print_string
    popa
    ret

cmd_runf_handler:
    pusha
    mov  si, input_buffer + 5
    call skip_spaces
    mov  di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov  si, temp_name_83
    call find_file
    jnc  .not_found
    call load_file_by_cluster
    mov  al, byte [current_file_type]
    cmp  al, 1
    je   .com
    cmp  al, 2
    je   .exe
    cmp  al, 3
    je   .bin
    mov  si, unknown_type_msg
    call print_string
    popa
    ret
.com:
    call run_com_file
    popa
    ret
.exe:
    call run_exe_file
    popa
    ret
.bin:
    call run_bin_file
    popa
    ret
.not_found:
    mov  si, file_not_found_msg
    call print_string
    popa
    ret

; COM program runner
run_com_file:
    pusha
    push es
    mov  ax, PROG_SEG
    mov  es, ax
    mov  word [es:0x0000], 0x20CD
    mov  word [es:0x0002], PROG_SEG + 0x1000
    xor  di, di
    mov  di, 0x0081
    xor  cx, cx
    mov  byte [es:0x0080], cl
    pop  es
    push es
    mov  ax, PROG_SEG
    mov  es, ax
    mov  si, file_buffer
    mov  di, PROG_OFF
    mov  cx, word [current_file_size]
    cmp  cx, 0xFF00
    jbe  .sz_ok
    mov  cx, 0xFF00
.sz_ok:
    rep  movsb
    pop  es
    call print_string
    mov  ax, PROG_SEG
    mov  ds, ax
    mov  es, ax
    mov  ss, ax
    mov  sp, 0xFFFE
    jmp  PROG_SEG:PROG_OFF

; EXE program runner
run_exe_file:
    pusha
    push es
    mov ax, KERNEL_SEG
    mov ds, ax
    mov es, ax
    mov bx, file_buffer
    cmp word [bx], 0x5A4D
    je .signature_ok
    cmp word [bx], 0x4D5A
    je .signature_ok
    mov si, exe_err_msg
    call print_string
    pop es
    popa
    ret
.signature_ok:
    mov bp, word [bx + 0x08]
    mov si, file_buffer
    mov ax, PROG_SEG
    mov es, ax
    xor di, di
    mov cx, word [current_file_size]
    cld
    rep movsb
    mov ax, PROG_SEG
    mov ds, ax
    mov bx, 0
    mov dx, word [bx + 0x06]
    cmp dx, 0
    je .no_reloc
    mov di, word [bx + 0x18]
.reloc_loop:
    push dx
    mov si, word [ds:di]
    mov ax, word [ds:di + 2]
    add ax, PROG_SEG
    add ax, bp
    mov es, ax
    mov cx, PROG_SEG
    add cx, bp
    add word [es:si], cx
    add di, 4
    pop dx
    dec dx
    jnz .reloc_loop
.no_reloc:
    mov ax, word [bx + 0x16]
    add ax, PROG_SEG
    add ax, bp
    mov word [cs:.target_cs], ax
    mov ax, word [bx + 0x14]
    mov word [cs:.target_ip], ax
    mov ax, KERNEL_SEG
    mov ds, ax
    mov word [kernel_ss], ss
    mov word [kernel_sp], sp
    mov ax, PROG_SEG
    add ax, bp
    mov ds, ax
    mov es, ax
    push word [cs:.target_cs]
    push word [cs:.target_ip]
    retf
.target_cs: dw 0
.target_ip: dw 0

; BIN program runner
run_bin_file:
    pusha
    push es
    mov ax, word [current_file_size]
    cmp ax, 0xFF00
    ja .file_too_big
    mov ax, PROG_SEG
    mov es, ax
    xor di, di
    push ds
    mov ax, KERNEL_SEG
    mov ds, ax
    mov si, file_buffer
    mov cx, word [current_file_size]
    cld
    rep movsb
    pop ds
    mov ax, KERNEL_SEG
    mov word [kernel_ss], ss
    mov word [kernel_sp], sp
    call print_string
    mov ax, PROG_SEG
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE
    jmp PROG_SEG:0x0000
.file_too_big:
    mov si, file_too_big_msg
    call print_string
    pop es
    popa
    ret
