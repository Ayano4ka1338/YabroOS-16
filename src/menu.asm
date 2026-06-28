; Shell menu interface - (c) Ayano4ka1338, 2026
shell_header:
    db 13, 10, "", 13, 10
    db "YabroOS v1.0 Shell (DOS Compatible)", 13, 10
    db "", 13, 10, 13, 10, 0

shell_menu1: db "  (1) File Manager      - Browse & manage files", 13, 10, 0
shell_menu2: db "  (2) Run Program       - Execute COM/EXE/BIN files", 13, 10, 0
shell_menu3: db "  (3) Graphics Mode     - VGA Paint application", 13, 10, 0
shell_menu4: db "  (4) Text Editor       - Create & edit files", 13, 10, 0
shell_menu5: db "  (5) Calculator        - Simple arithmetic", 13, 10, 0
shell_menu6: db "  (6) System Setup      - Configuration menu", 13, 10, 0
shell_menu7: db "  (7) About System      - System information", 13, 10, 0
shell_menu8: db "  (8) Shutdown          - Power off system", 13, 10, 0
shell_menu_exit: db "  (0) Exit to Command   - Return to command line", 13, 10, 13, 10, 0
shell_choice: db "  Select (0-8): ", 0

shell_run_msg: db 13, 10, "Enter program name: ", 0

shell_setup_msg:
    db "System Setup Menu", 13, 10, 13, 10
    db "Processor: Intel 8086/8088", 13, 10
    db "RAM: 640 KB available", 13, 10
    db "Disk: 2.88 MB Floppy", 13, 10
    db "Display: VGA 320x200", 13, 10
    db "Input: Keyboard + PS/2 Mouse", 13, 10
    db "Sound: PC Speaker", 13, 10, 13, 10, 0

shell_about_msg:
    db "YabroOS v1.0 - 16-bit Real Mode Operating System", 13, 10
    db "", 13, 10
    db "Features:", 13, 10
    db "- FAT12 File System with Directory Support", 13, 10
    db "- PS/2 Mouse Support (Real Hardware) ", 13, 10
    db "- VGA Graphics Mode (320x200)", 13, 10
    db "- PC Speaker Sound Synthesis", 13, 10
    db "- DOS INT 21h Compatibility (60+ functions)", 13, 10
    db "- Text Editor with File Operations", 13, 10
    db "- shell Shell (Norton/Legacy DOS Compatible)", 13, 10
    db "- Command Line Interface", 13, 10
    db "", 13, 10
    db "Type 'help' for command list", 13, 10, 0

; Shell main loop
shell_mode:
    pusha
    call clear_screen
    
.menu_loop:
    call draw_shell_menu
    call get_menu_choice
    
    cmp al, 0
    je .shell_exit
    cmp al, 1
    je .shell_files
    cmp al, 2
    je .shell_run
    cmp al, 3
    je .shell_graphics
    cmp al, 4
    je .shell_editor
    cmp al, 5
    je .shell_calculator
    cmp al, 6
    je .shell_setup
    cmp al, 7
    je .shell_about
    cmp al, 8
    je .shell_shutdown
    
    jmp .menu_loop
    
.shell_files:
    call list_files
    mov si, press_key_msg
    call print_string
    xor ah, ah
    int 0x16
    jmp .menu_loop
    
.shell_run:
    mov si, shell_run_msg
    call print_string
    call get_string
    call hide_cursor
    mov si, input_buffer
    call try_run_as_file
    jmp .menu_loop
    
.shell_graphics:
    call graphics_mode
    jmp .menu_loop
    
.shell_editor:
    call editor
    jmp .menu_loop
    
.shell_calculator:
    call calculator
    jmp .menu_loop
    
.shell_setup:
    call setup_menu
    jmp .menu_loop
    
.shell_about:
    call show_about
    mov si, press_key_msg
    call print_string
    xor ah, ah
    int 0x16
    jmp .menu_loop
    
.shell_shutdown:
    call clear_screen
    call do_shutdown
    
.shell_exit:
    call clear_screen
    popa
    ret

; Draw shell menu
draw_shell_menu:
    call clear_screen
    mov si, shell_header
    call print_string
    mov si, shell_menu1
    call print_string
    mov si, shell_menu2
    call print_string
    mov si, shell_menu3
    call print_string
    mov si, shell_menu4
    call print_string
    mov si, shell_menu5
    call print_string
    mov si, shell_menu6
    call print_string
    mov si, shell_menu7
    call print_string
    mov si, shell_menu8
    call print_string
    mov si, shell_menu_exit
    call print_string
    ret

; Get menu choice
get_menu_choice:
    mov si, shell_choice
    call print_string
    xor ah, ah
    int 0x16
    sub al, '0'
    ret

; Setup menu
setup_menu:
    call clear_screen
    mov si, shell_setup_msg
    call print_string
    mov si, press_key_msg
    call print_string
    xor ah, ah
    int 0x16
    ret

; About screen
show_about:
    call clear_screen
    mov si, shell_about_msg
    call print_string
    ret
