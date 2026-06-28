; FAT12 filesystem - (c) Ayano4ka1338, 2026
lba_to_chs:
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

init_fs:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    call load_fat
    call load_root
    mov  byte [current_directory], 0
    mov  word [current_dir_cluster], 0
    mov  word [current_dir_sector], ROOT_START
    mov  word [parent_dir_cluster], 0
    pop  es
    popa
    ret

load_fat:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  ax, FAT_START
    call lba_to_chs
    mov  bx, fat_buffer
    mov  ah, 0x02
    mov  al, FAT_SECS
    mov  dl, [boot_drive]
    int  0x13
    pop  es
    popa
    ret

load_root:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  ax, ROOT_START
    call lba_to_chs
    mov  bx, root_buffer
    mov  ah, 0x02
    mov  al, ROOT_SECS
    mov  dl, [boot_drive]
    int  0x13
    pop  es
    popa
    ret

save_root:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  ax, ROOT_START
    mov  bx, root_buffer
    mov  word [.cnt], ROOT_SECS
.loop:
    call lba_to_chs
    push ax
    mov  ah, 0x03
    mov  al, 1
    mov  dl, [boot_drive]
    int  0x13
    pop  ax
    inc  ax
    add  bx, 512
    dec  word [.cnt]
    jnz  .loop
    pop  es
    popa
    ret
.cnt: dw 0

save_fat:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  ax, FAT_START
    mov  bx, fat_buffer
    mov  word [.cnt], FAT_SECS
.fat1:
    call lba_to_chs
    push ax
    mov  ah, 0x03
    mov  al, 1
    mov  dl, [boot_drive]
    int  0x13
    pop  ax
    inc  ax
    add  bx, 512
    dec  word [.cnt]
    jnz  .fat1
    mov  ax, FAT_START + FAT_SECS
    mov  bx, fat_buffer
    mov  word [.cnt], FAT_SECS
.fat2:
    call lba_to_chs
    push ax
    mov  ah, 0x03
    mov  al, 1
    mov  dl, [boot_drive]
    int  0x13
    pop  ax
    inc  ax
    add  bx, 512
    dec  word [.cnt]
    jnz  .fat2
    pop  es
    popa
    ret
.cnt: dw 0

get_fat12_entry:
    push bx
    push dx
    mov  bx, ax
    shr  bx, 1
    add  bx, ax
    mov  dx, word [fat_buffer + bx]
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

set_fat12_entry:
    push bx
    push cx
    push dx
    mov  bx, ax
    shr  bx, 1
    add  bx, ax
    test ax, 1
    jz   .even_set
    mov  cx, word [fat_buffer + bx]
    and  cx, 0x000F
    shl  dx, 4
    and  dx, 0xFFF0
    or   cx, dx
    mov  word [fat_buffer + bx], cx
    jmp  .set_done
.even_set:
    mov  cx, word [fat_buffer + bx]
    and  cx, 0xF000
    and  dx, 0x0FFF
    or   cx, dx
    mov  word [fat_buffer + bx], cx
.set_done:
    pop  dx
    pop  cx
    pop  bx
    ret

find_free_cluster:
    push bx
    push cx
    mov  ax, 2
    mov  cx, MAX_CLUSTERS
.ffc_loop:
    push ax
    call get_fat12_entry
    cmp  ax, 0
    pop  ax
    je   .ffc_found
    inc  ax
    loop .ffc_loop
    xor  ax, ax
    pop  cx
    pop  bx
    ret
.ffc_found:
    pop  cx
    pop  bx
    ret

cluster_to_sector:
    push bx
    sub  ax, 2
    mov  bx, CLUSTER_SIZE
    mul  bx
    add  ax, DATA_START
    pop  bx
    ret

load_file_by_cluster:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  bx, file_buffer
    mov  ax, word [current_file_cluster]
    xor  cx, cx
    cmp  ax, 0
    je   .load_done
    cmp  ax, 1
    je   .load_done
.load_chain_loop:
    cmp  ax, 0xFF8
    jge  .load_done
    cmp  ax, 0
    je   .load_done
    cmp  ax, 2
    jb   .load_done
    push ax
    call cluster_to_sector
    call lba_to_chs
    mov  ah, 0x02
    mov  al, CLUSTER_SIZE
    mov  dl, [boot_drive]
    int  0x13
    jc   .load_error
    add  bx, 512 * CLUSTER_SIZE
    add  cx, 512 * CLUSTER_SIZE
    pop  ax
    push ax
    call get_fat12_entry
    mov  ax, ax
    pop  bx
    jmp  .load_chain_loop
.load_error:
    pop  ax
.load_done:
    pop  es
    popa
    ret

save_file_by_cluster:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  bx, file_buffer
    mov  ax, word [current_file_cluster]
    mov  word [.first_cluster], ax
    mov  word [.cur_cluster], ax
    xor  cx, cx
    cmp  ax, 0
    je   .save_done
    cmp  ax, 1
    je   .save_done
.save_chain_loop:
    mov  dx, word [current_file_size]
    cmp  cx, dx
    jge  .save_done
    mov  ax, word [.cur_cluster]
    cmp  ax, 0
    je   .alloc_cluster
    cmp  ax, 1
    je   .alloc_cluster
    cmp  ax, 0xFF8
    jge  .alloc_cluster
.save_cluster:
    push ax
    call cluster_to_sector
    call lba_to_chs
    pop  ax
    mov  word [.cur_cluster], ax
    mov  dx, word [current_file_size]
    sub  dx, cx
    cmp  dx, 512 * CLUSTER_SIZE
    jle  .write_partial
    mov  dx, 512 * CLUSTER_SIZE
.write_partial:
    mov  word [.write_size], dx
    mov  si, bx
    mov  di, temp_data
    mov  cx, word [.write_size]
    rep  movsb
    mov  cx, word [.write_size]
    cmp  cx, 512 * CLUSTER_SIZE
    jge  .no_pad
    mov  cx, 512 * CLUSTER_SIZE
    sub  cx, word [.write_size]
    xor  al, al
    rep  stosb
.no_pad:
    mov  bx, temp_data
    mov  ah, 0x03
    mov  al, CLUSTER_SIZE
    mov  dl, [boot_drive]
    int  0x13
    jc   .save_error
    add  cx, word [.write_size]
    add  bx, 512 * CLUSTER_SIZE
    mov  ax, word [.cur_cluster]
    call get_fat12_entry
    mov  word [.next_cluster], ax
    cmp  ax, 0xFF8
    jge  .chain_ends
    cmp  ax, 0
    je   .chain_ends
    mov  word [.cur_cluster], ax
    jmp  .save_chain_loop
.chain_ends:
    mov  dx, word [current_file_size]
    cmp  cx, dx
    jge  .save_done
    mov  ax, word [.cur_cluster]
.alloc_cluster:
    call find_free_cluster
    cmp  ax, 0
    je   .save_error
    mov  word [.new_cluster], ax
    mov  dx, word [.new_cluster]
    mov  ax, word [.cur_cluster]
    cmp  ax, 0
    je   .first_alloc
    cmp  ax, 1
    je   .first_alloc
    call set_fat12_entry
.first_alloc:
    mov  ax, word [.new_cluster]
    mov  dx, 0x0FFF
    call set_fat12_entry
    cmp  word [.first_cluster], 0
    jne  .continue_write
    cmp  word [.first_cluster], 1
    jne  .continue_write
    mov  word [.first_cluster], ax
.continue_write:
    mov  ax, word [.new_cluster]
    mov  word [.cur_cluster], ax
    jmp  .save_cluster
.save_error:
    mov  si, disk_error_msg
    call print_string
.save_done:
    mov  ax, word [.first_cluster]
    cmp  ax, 0
    je   .no_update
    cmp  ax, 1
    je   .no_update
    mov  word [current_file_cluster], ax
.no_update:
    pop  es
    popa
    ret
.cur_cluster: dw 0
.prev_cluster: dw 0
.next_cluster: dw 0
.new_cluster: dw 0
.first_cluster: dw 0
.write_size: dw 0

convert_name_si:
    pusha
    mov  si, temp_name
    mov  di, temp_name_83
    mov  cx, 11
    mov  al, ' '
    rep  stosb
    mov  di, temp_name_83
    xor  cx, cx
.base:
    mov  al, [si]
    or   al, al
    jz   .done
    cmp  al, '.'
    je   .ext
    cmp  cx, 8
    jge  .skipb
    cmp  al, 'a'
    jb   .storeb
    cmp  al, 'z'
    ja   .storeb
    sub  al, 0x20
.storeb:
    stosb
    inc  cx
.skipb:
    inc  si
    jmp  .base
.ext:
    inc  si
    mov  di, temp_name_83 + 8
    xor  cx, cx
.extl:
    mov  al, [si]
    or   al, al
    jz   .done
    cmp  cx, 3
    jge  .skipe
    cmp  al, 'a'
    jb   .storee
    cmp  al, 'z'
    ja   .storee
    sub  al, 0x20
.storee:
    stosb
    inc  cx
.skipe:
    inc  si
    jmp  .extl
.done:
    popa
    ret

copy_str_to_temp:
    push si
    push di
    mov  di, temp_name
.lp:
    lodsb
    or   al, al
    jz   .done
    stosb
    jmp  .lp
.done:
    mov  byte [di], 0
    pop  di
    pop  si
    ret

determine_file_type:
    push ax
    push si
    mov  si, temp_name_83 + 8
    cmp  byte [si],     'C'
    jne  .chk_exe
    cmp  byte [si + 1], 'O'
    jne  .unknown
    cmp  byte [si + 2], 'M'
    jne  .unknown
    mov  byte [current_file_type], 1
    jmp  .done
.chk_exe:
    cmp  byte [si],     'E'
    jne  .chk_bin
    cmp  byte [si + 1], 'X'
    jne  .unknown
    cmp  byte [si + 2], 'E'
    jne  .unknown
    mov  byte [current_file_type], 2
    jmp  .done
.chk_bin:
    cmp  byte [si],     'B'
    jne  .unknown
    cmp  byte [si + 1], 'I'
    jne  .unknown
    cmp  byte [si + 2], 'N'
    jne  .unknown
    mov  byte [current_file_type], 3
    jmp  .done
.unknown:
    mov  byte [current_file_type], 4
.done:
    pop  si
    pop  ax
    ret

load_directory:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    cmp  word [current_dir_cluster], 0
    je   .is_root
    mov  ax, word [current_dir_cluster]
    mov  word [current_file_cluster], ax
    call load_file_by_cluster
    mov  si, file_buffer
    mov  di, root_buffer
    mov  cx, ROOT_SECS * 512
    rep  movsb
    jmp  .done
.is_root:
    call load_root
.done:
    pop  es
    popa
    ret

save_directory:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    cmp  word [current_dir_cluster], 0
    je   .is_root
    mov  si, root_buffer
    mov  di, file_buffer
    mov  cx, ROOT_SECS * 512
    rep  movsb
    mov  ax, word [current_dir_cluster]
    mov  word [current_file_cluster], ax
    call save_file_by_cluster
    jmp  .done
.is_root:
    call save_root
.done:
    pop  es
    popa
    ret

find_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    call load_directory
    mov  di, root_buffer
    mov  cx, 224
.lp:
    mov  al, [di]
    or   al, al
    jz   .not_found
    cmp  al, 0xE5
    je   .next
    cmp  al, 0x0F
    je   .next
    push si
    push di
    push cx
    mov  cx, 11
    mov  si, temp_name_83
    repe cmpsb
    pop  cx
    pop  di
    pop  si
    je   .found
.next:
    add  di, 32
    loop .lp
.not_found:
    pop  es
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    clc
    ret
.found:
    mov  word [current_file_entry], di
    mov  ax, word [di + 26]
    mov  word [current_file_cluster], ax
    mov  ax, word [di + 28]
    mov  word [current_file_size], ax
    call determine_file_type
    pop  es
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    stc
    ret

find_free_entry:
    push ax
    push cx
    push di
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    call load_directory
    mov  di, root_buffer
    mov  cx, 224
.lp:
    mov  al, [di]
    or   al, al
    jz   .found
    cmp  al, 0xE5
    je   .found
    add  di, 32
    loop .lp
    pop  es
    pop  di
    pop  cx
    pop  ax
    clc
    ret
.found:
    mov  word [current_file_entry], di
    pop  es
    pop  di
    pop  cx
    pop  ax
    stc
    ret

create_root_entry:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  di, word [current_file_entry]
    mov  si, temp_name_83
    mov  cx, 11
    rep  movsb
    mov  di, word [current_file_entry]
    mov  byte [di + 11], 0x20
    mov  word [di + 26], 0
    mov  word [di + 28], 0
    mov  word [di + 30], 0
    mov  word [di + 20], 0
    mov  word [di + 22], 0
    mov  word [di + 24], 0
    mov  word [di + 18], 0
    call save_directory
    pop  es
    popa
    ret

format_fs:
    pusha
    mov  di, root_buffer
    mov  cx, ROOT_SECS * 512
    xor  al, al
    rep  stosb
    call save_root
    mov  si, fs_ready_msg
    call print_string
    popa
    ret
