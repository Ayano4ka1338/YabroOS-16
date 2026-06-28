; Text editor - (c) Ayano4ka1338, 2026
ed_buf:         times ED_BUFSIZE db ' '
ed_row:         dw 0
ed_col:         dw 0
ed_filename:    times 64 db 0

ed_title:       db "=== YabroOS Editor | F2:Save  ESC:Quit ===", 0
ed_stat1:       db "File:", 0
ed_stat2:       db "  Ln:", 0
ed_stat3:       db " | F2=Save  ESC=Quit", 0
ed_noname:      db "(new file)", 0
ed_ask_name:    db 13, 10, "Filename: ", 0
ed_saved_msg:   db 13, 10, "Saved!", 13, 10, 0

editor:
    pusha
    mov  di, ed_buf
    mov  cx, ED_BUFSIZE
    mov  al, ' '
    rep  stosb
    mov  word [ed_row], 0
    mov  word [ed_col], 0
    mov  byte [ed_filename], 0
    mov  si, input_buffer + 4
    call skip_spaces
    cmp  byte [si], 0
    je   .no_file
    mov  di, ed_filename
.cpfn:
    lodsb
    or   al, al
    jz   .fn_done
    cmp  al, ' '
    je   .fn_done
    mov  [di], al
    inc  di
    jmp  .cpfn
.fn_done:
    mov  byte [di], 0
    mov  si, ed_filename
    mov  di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov  si, temp_name_83
    call find_file
    jnc  .no_file
    call load_file_by_cluster
    mov  si, file_buffer
    mov  di, ed_buf
    mov  cx, word [current_file_size]
    cmp  cx, ED_BUFSIZE
    jbe  .cp_ok
    mov  cx, ED_BUFSIZE
.cp_ok:
    rep  movsb
.no_file:
    call ed_redraw
.loop:
    xor  ah, ah
    int  0x16
    test al, al
    jnz  .normal
    cmp  ah, 0x48
    je   .up
    cmp  ah, 0x50
    je   .down
    cmp  ah, 0x4B
    je   .left
    cmp  ah, 0x4D
    je   .right
    cmp  ah, 0x53
    je   .del
    cmp  ah, 0x3C
    je   .save
    jmp  .loop
.normal:
    cmp  al, 0x1B
    je   .quit
    cmp  al, 0x0D
    je   .enter
    cmp  al, 0x08
    je   .bs
    cmp  al, 0x20
    jb   .loop
    cmp  al, 0x7E
    ja   .loop
    call ed_put_char
    mov  ax, word [ed_col]
    inc  ax
    cmp  ax, ED_COLS
    jl   .c_ok
    mov  ax, ED_COLS - 1
.c_ok:
    mov  word [ed_col], ax
    call ed_redraw_line
    call ed_draw_statusbar
    call ed_move_cursor
    jmp  .loop
.up:
    cmp  word [ed_row], 0
    je   .loop
    dec  word [ed_row]
    call ed_draw_statusbar
    call ed_move_cursor
    jmp  .loop
.down:
    mov  ax, word [ed_row]
    cmp  ax, ED_ROWS - 1
    je   .loop
    inc  word [ed_row]
    call ed_draw_statusbar
    call ed_move_cursor
    jmp  .loop
.left:
    cmp  word [ed_col], 0
    je   .loop
    dec  word [ed_col]
    call ed_move_cursor
    jmp  .loop
.right:
    mov  ax, word [ed_col]
    cmp  ax, ED_COLS - 1
    je   .loop
    inc  word [ed_col]
    call ed_move_cursor
    jmp  .loop
.enter:
    mov  word [ed_col], 0
    mov  ax, word [ed_row]
    inc  ax
    cmp  ax, ED_ROWS
    jl   .ent_ok
    mov  ax, ED_ROWS - 1
.ent_ok:
    mov  word [ed_row], ax
    call ed_redraw
    jmp  .loop
.bs:
    cmp  word [ed_col], 0
    jne  .bs_char
    cmp  word [ed_row], 0
    je   .loop
    dec  word [ed_row]
    mov  word [ed_col], ED_COLS - 1
    call ed_move_cursor
    jmp  .loop
.bs_char:
    dec  word [ed_col]
    mov  al, ' '
    call ed_put_char
    call ed_redraw_line
    call ed_move_cursor
    jmp  .loop
.del:
    mov  al, ' '
    call ed_put_char
    call ed_redraw_line
    call ed_move_cursor
    jmp  .loop
.save:
    call ed_save_file
    call ed_draw_statusbar
    jmp  .loop
.quit:
    call clear_screen
    popa
    ret

ed_put_char:
    push ax
    push bx
    push si
    mov  bh, al
    mov  ax, word [ed_row]
    mov  bx, ED_COLS
    mul  bx
    add  ax, word [ed_col]
    mov  si, ed_buf
    add  si, ax
    mov  [si], bh
    pop  si
    pop  bx
    pop  ax
    ret

ed_redraw:
    pusha
    call clear_screen
    mov  dh, 0
    mov  dl, 0
    call set_cursor
    mov  si, ed_title
    call print_string
    xor  bx, bx
.drw:
    cmp  bx, ED_ROWS
    je   .done
    mov  ax, bx
    inc  ax
    mov  dh, al
    mov  dl, 0
    call set_cursor
    mov  ax, bx
    mov  dx, ED_COLS
    mul  dx
    mov  si, ed_buf
    add  si, ax
    mov  cx, ED_COLS
.dcol:
    lodsb
    mov  ah, 0x0E
    int  0x10
    loop .dcol
    inc  bx
    jmp  .drw
.done:
    call ed_draw_statusbar
    call ed_move_cursor
    popa
    ret

ed_redraw_line:
    pusha
    mov  ax, word [ed_row]
    inc  ax
    mov  dh, al
    mov  dl, 0
    call set_cursor
    mov  ax, word [ed_row]
    mov  dx, ED_COLS
    mul  dx
    mov  si, ed_buf
    add  si, ax
    mov  cx, ED_COLS
.lp:
    lodsb
    mov  ah, 0x0E
    int  0x10
    loop .lp
    popa
    ret

ed_draw_statusbar:
    pusha
    mov  dh, ED_ROWS + 1
    mov  dl, 0
    call set_cursor
    mov  cx, 78
.clr:
    mov  ah, 0x0E
    mov  al, ' '
    int  0x10
    loop .clr
    mov  dh, ED_ROWS + 1
    mov  dl, 0
    call set_cursor
    mov  si, ed_stat1
    call print_string
    mov  si, ed_filename
    cmp  byte [si], 0
    jne  .has_nm
    mov  si, ed_noname
.has_nm:
    call print_string
    mov  si, ed_stat2
    call print_string
    mov  ax, word [ed_row]
    inc  ax
    call print_ax
    mov  ah, 0x0E
    mov  al, ':'
    int  0x10
    mov  ax, word [ed_col]
    inc  ax
    call print_ax
    mov  si, ed_stat3
    call print_string
    popa
    ret

ed_move_cursor:
    pusha
    mov  ax, word [ed_row]
    inc  ax
    mov  dh, al
    mov  ax, word [ed_col]
    mov  dl, al
    call set_cursor
    popa
    ret

set_cursor:
    pusha
    mov  ah, 0x02
    xor  bh, bh
    int  0x10
    popa
    ret

ed_save_file:
    pusha
    cmp  byte [ed_filename], 0
    jne  .has_nm
    mov  si, ed_ask_name
    call print_string
    mov  di, ed_filename
    call get_string_to
    cmp  byte [ed_filename], 0
    je   .cancel
.has_nm:
    mov  si, ed_filename
    mov  di, temp_name
    call copy_str_to_temp
    call convert_name_si
    mov  si, temp_name_83
    call find_file
    jc   .file_exists
    call find_free_entry
    jnc  .serr
    call create_root_entry
    call find_free_cluster
    cmp  ax, 0
    je   .disk_full
    push ax
    mov  dx, 0x0FFF
    call set_fat12_entry
    pop  ax
    mov  word [current_file_cluster], ax
    mov  di, word [current_file_entry]
    mov  word [di + 26], ax
.file_exists:
    call ed_write_clusters
    mov  di, word [current_file_entry]
    mov  word [di + 28], ED_BUFSIZE
    mov  word [di + 30], 0
    call save_directory
    call save_fat
    mov  si, ed_saved_msg
    call print_string
    popa
    ret
.disk_full:
    mov  si, fs_full_msg
    call print_string
    popa
    ret
.serr:
.cancel:
    mov  si, fs_full_msg
    call print_string
    popa
    ret

ed_write_clusters:
    pusha
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  word [.remain], ED_BUFSIZE
    mov  word [.src_off], 0
    mov  ax, word [current_file_cluster]
    mov  word [.cur_clust], ax
    mov  word [.prev_clust], 0
.ewc_loop:
    cmp  word [.remain], 0
    je   .ewc_done
    mov  ax, word [.cur_clust]
    cmp  ax, 2
    jb   .ewc_alloc
    cmp  ax, 0xFF8
    jae  .ewc_alloc
    jmp  .ewc_have
.ewc_alloc:
    call find_free_cluster
    cmp  ax, 0
    je   .ewc_full
    push ax
    mov  dx, 0x0FFF
    call set_fat12_entry
    pop  ax
    mov  bx, word [.prev_clust]
    cmp  bx, 2
    jb   .ewc_no_link
    push ax
    xchg ax, bx
    mov  dx, bx
    call set_fat12_entry
    pop  ax
.ewc_no_link:
    cmp  word [.prev_clust], 0
    jne  .ewc_not_first
    mov  word [current_file_cluster], ax
    mov  di, word [current_file_entry]
    mov  word [di + 26], ax
.ewc_not_first:
    mov  word [.cur_clust], ax
.ewc_have:
    mov  ax, word [.cur_clust]
    mov  word [.prev_clust], ax
    call cluster_to_sector
    call lba_to_chs
    mov  si, ed_buf
    add  si, word [.src_off]
    mov  di, temp_data
    mov  cx, word [.remain]
    cmp  cx, 512 * CLUSTER_SIZE
    jle  .ewc_partial
    mov  cx, 512 * CLUSTER_SIZE
.ewc_partial:
    push cx
    rep  movsb
    pop  cx
    push cx
    neg  cx
    add  cx, 512 * CLUSTER_SIZE
    jle  .ewc_nopad
    xor  al, al
    rep  stosb
.ewc_nopad:
    pop  cx
    push bx
    mov  bx, temp_data
    push es
    mov  ax, KERNEL_SEG
    mov  es, ax
    mov  ah, 0x03
    mov  al, CLUSTER_SIZE
    mov  dl, byte [boot_drive]
    int  0x13
    pop  es
    pop  bx
    jnc  .ewc_wr_ok
    mov  si, disk_error_msg
    call print_string
    jmp  .ewc_done
.ewc_wr_ok:
    add  word [.src_off], cx
    sub  word [.remain], cx
    mov  ax, word [.cur_clust]
    call get_fat12_entry
    mov  word [.cur_clust], ax
    jmp  .ewc_loop
.ewc_full:
    mov  si, fs_full_msg
    call print_string
.ewc_done:
    pop  es
    popa
    ret
.remain:    dw 0
.src_off:   dw 0
.cur_clust: dw 0
.prev_clust:dw 0
