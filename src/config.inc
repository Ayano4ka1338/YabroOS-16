; System configuration - (c) Ayano4ka1338, 2026
KERNEL_SEG  equ 0x2000
STACK_SEG   equ 0x9000
PROG_SEG    equ 0x5000
PROG_OFF    equ 0x0100

; FAT12 layout
FAT_START   equ 1
FAT_SECS    equ 9
ROOT_START  equ 19
ROOT_SECS   equ 14
DATA_START  equ 33
TOTAL_SECTORS equ 5760
MAX_CLUSTERS  equ 4085
CLUSTER_SIZE  equ 2

; Editor
ED_ROWS     equ 20
ED_COLS     equ 78
ED_BUFSIZE  equ (ED_ROWS * ED_COLS)

; Password
PASSWORD_HASH   equ 0xA5F3
MAX_ATTEMPTS    equ 3

; Sound
SPEAKER_PORT    equ 0x61
TIMER_CMD       equ 0x43
TIMER_CH2       equ 0x42
TIMER_FREQ      equ 1193182
