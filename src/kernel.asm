; YabroOS Kernel - (c) Ayano4ka1338, 2026
[org 0x0000]
[bits 16]

; Kernel entry point
start:
    cli
    mov  ax, KERNEL_SEG
    mov  ds, ax
    mov  es, ax
    mov  byte [boot_drive], dl
    mov  ax, STACK_SEG
    mov  ss, ax
    mov  sp, 0xFFFE
    sti
    call clear_screen
    
    mov  si, banner_pwd
    call print_string
    mov  byte [pwd_attempts], MAX_ATTEMPTS
    
.pwd_loop:
    mov  si, pwd_prompt
    call print_string
    call get_password
    
    call verify_password
    cmp  al, 1
    je   .pwd_ok
    
    dec  byte [pwd_attempts]
    cmp  byte [pwd_attempts], 0
    je   .pwd_fail
    
    mov  si, pwd_wrong_msg
    call print_string
    jmp  .pwd_loop
    
.pwd_fail:
    mov  si, pwd_locked_msg
    call print_string
    call do_shutdown
    
.pwd_ok:
    call clear_screen
    mov  si, welcome_msg
    call print_string
    call init_fs
    call init_mouse
    call install_dos_hooks
    jmp  main_loop

%include "src/config.inc"
%include "src/utils.asm"
%include "src/fat12.asm"
%include "src/mouse.asm"
%include "src/sound.asm"
%include "src/graphics.asm"
%include "src/editor.asm"
%include "src/calculator.asm"
%include "src/shell.asm"
%include "src/shared.asm"
%include "src/commands.asm"
%include "src/dos_int21.asm"
%include "src/data.asm"

; Main command loop
main_loop:
    mov  ax, KERNEL_SEG
    mov  ds, ax
    mov  es, ax
    mov  ax, STACK_SEG
    mov  ss, ax
    mov  sp, 0xFFFE
    call draw_cursor
    
    mov  si, prompt
    call print_string
    call get_string
    call hide_cursor
    cmp  byte [input_buffer], 0
    je   main_loop
    mov  si, input_buffer
    call to_lowercase

    ; Check commands
    mov  si, input_buffer
    mov  di, cmd_help
    call strcmp
    jc   .do_help
    
    mov  si, input_buffer
    mov  di, cmd_cls
    call strcmp
    jc   .do_cls
    
    mov  si, input_buffer
    mov  di, cmd_ls
    call strcmp
    jc   .do_ls
    
    mov  si, input_buffer
    mov  di, cmd_shell
    call strcmp
    jc   .do_shell
    
    mov  si, input_buffer
    mov  di, cmd_format
    call strcmp
    jc   .do_format
    
    mov  si, input_buffer
    mov  di, cmd_run
    call strcmp
    jc   .do_run
    
    mov  si, input_buffer
    mov  di, cmd_fetch
    call strcmp
    jc   .do_fetch
    
    mov  si, input_buffer
    mov  di, cmd_reboot
    call strcmp
    jc   .do_reboot
    
    mov  si, input_buffer
    mov  di, cmd_graphics
    call strcmp
    jc   .do_graphics
    
    mov  si, input_buffer
    mov  di, cmd_dump
    call strcmp
    jc   .do_dump
    
    mov  si, input_buffer
    mov  di, cmd_calc
    call strcmp
    jc   .do_calc
    
    mov  si, input_buffer
    mov  di, cmd_shutdown
    call strcmp
    jc   .do_shutdown
    
    mov  si, input_buffer
    mov  di, cmd_poweroff
    call strcmp
    jc   .do_shutdown
    
    mov  si, input_buffer
    mov  di, cmd_beep
    call strcmp
    jc   .do_beep
    
    ; Commands with prefixes
    mov  si, input_buffer
    mov  di, cmd_tone
    call strcmp_prefix
    jc   .do_tone
    
    mov  si, input_buffer
    mov  di, cmd_edit_pfx
    call strcmp_prefix
    jc   .do_edit
    
    mov  si, input_buffer
    mov  di, cmd_create
    call strcmp_prefix
    jc   .do_create
    
    mov  si, input_buffer
    mov  di, cmd_write
    call strcmp_prefix
    jc   .do_write
    
    mov  si, input_buffer
    mov  di, cmd_type
    call strcmp_prefix
    jc   .do_type
    
    mov  si, input_buffer
    mov  di, cmd_del
    call strcmp_prefix
    jc   .do_del
    
    mov  si, input_buffer
    mov  di, cmd_rename
    call strcmp_prefix
    jc   .do_rename
    
    mov  si, input_buffer
    mov  di, cmd_runf
    call strcmp_prefix
    jc   .do_runf
    
    mov  si, input_buffer
    mov  di, cmd_mkdir
    call strcmp_prefix
    jc   .do_mkdir
    
    mov  si, input_buffer
    mov  di, cmd_cd
    call strcmp_prefix
    jc   .do_cd
    
    mov  si, input_buffer
    mov  di, cmd_cp
    call strcmp_prefix
    jc   .do_cp
    
    ; Try running as file
    mov  si, input_buffer
    call try_run_as_file
    jc   main_loop
    
    ; Unknown command
    mov  si, unknown_msg
    call print_string
    jmp  main_loop

; Command handlers
.do_help:
    mov  si, help_text
    call print_string
    jmp  main_loop

.do_cls:
    call clear_screen
    jmp  main_loop

.do_ls:
    call list_files
    jmp  main_loop

.do_shell:
    call shell_mode
    jmp  main_loop

.do_format:
    call format_fs
    jmp  main_loop

.do_run:
    call run_sector
    jmp  main_loop

.do_fetch:
    mov  si, info_text
    call print_string
    jmp  main_loop

.do_reboot:
    call system_reboot
    jmp  main_loop

.do_graphics:
    call graphics_mode
    jmp  main_loop

.do_dump:
    call dump_sector
    jmp  main_loop

.do_calc:
    call calculator
    jmp  main_loop

.do_shutdown:
    call do_shutdown
    jmp  main_loop

.do_beep:
    call play_beep
    jmp  main_loop

.do_tone:
    call cmd_tone_handler
    jmp  main_loop

.do_edit:
    call editor
    jmp  main_loop

.do_create:
    call cmd_create_handler
    jmp  main_loop

.do_write:
    call cmd_write_handler
    jmp  main_loop

.do_type:
    call cmd_type_handler
    jmp  main_loop

.do_del:
    call cmd_del_handler
    jmp  main_loop

.do_rename:
    call cmd_rename_handler
    jmp  main_loop

.do_runf:
    call cmd_runf_handler
    jmp  main_loop

.do_mkdir:
    call cmd_mkdir_handler
    jmp  main_loop

.do_cd:
    call cmd_cd_handler
    jmp  main_loop

.do_cp:
    call cmd_cp_handler
    jmp  main_loop
