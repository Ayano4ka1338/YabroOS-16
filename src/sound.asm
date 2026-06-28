; PC Speaker sound - (c) Ayano4ka1338, 2026
speaker_state: db 0

; Simple beep
play_beep:
    pusha
    mov al, [speaker_state]
    or  al, 3
    out 61h, al
    
    mov ax, 100
    call delay_ms
    
    in al, 61h
    and al, 0xFC
    out 61h, al
    mov [speaker_state], al
    popa
    ret

; Play tone at frequency for duration
play_tone:
    pusha
    mov  ax, 0x34DE
    mov  bx, [.freq]
    xor  dx, dx
    div  bx
    mov  [.divisor], ax
    
    mov  al, 0xB6
    out  TIMER_CMD, al
    
    mov  ax, [.divisor]
    out  TIMER_CH2, al
    mov  al, ah
    out  TIMER_CH2, al
    
    in   al, SPEAKER_PORT
    or   al, 3
    out  SPEAKER_PORT, al
    mov  [speaker_state], al
    
    mov  ax, [.duration]
    call delay_ms
    
    in   al, SPEAKER_PORT
    and  al, 0xFC
    out  SPEAKER_PORT, al
    mov  [speaker_state], al
    
    popa
    ret
.freq:      dw 1000
.duration:  dw 100
.divisor:   dw 0

; Simple delay in milliseconds
delay_ms:
    pusha
.delay_loop:
    mov cx, 100
.inner:
    nop
    nop
    nop
    nop
    loop .inner
    dec ax
    jnz .delay_loop
    popa
    ret
