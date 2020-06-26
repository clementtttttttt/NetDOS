hhelp:
    mov si,lfcr
    call print_string
    mov si,helpstr
    call print_string
    jmp internal_shell.command_prep

clear_command:
    mov ah,3
    int 40h
    jmp internal_shell.command_prep

lsc:
    call read_fat2
    mov si,lfcr
    call print_string
    mov si,fat
    .loop:
        cmp byte [si],0xe5
        je .skip
        push si
        add si,11
        cmp byte [si],0x0f
        pop si
        je .skip
        call printstring_thatendafter8chars
        push si
        mov si,fourspaces
        call print_string
        pop si
        .show_attribute:
            mov ah,0x0e
            mov al,'|'
            int 10h
            mov al,' '
            int 10h
            mov al,[si+11]
        .nextd:
            cmp al,1
            jne .next
            mov al,'R'
            int 10h
            jmp .skip2
            .next:
            cmp al,2
            jne .next2
            mov al,'H'
            int 10h
            jmp .skip2
            .next2:
            cmp al,4
            jne .next3
            mov al,'S'
            int 10h
            jmp .skip2
            .next3:
            cmp al,8
            jne .next4
            mov al,'V'
            int 10h
            jmp .skip2
            .next4:
            cmp al,10h
            jne .next5
            mov al,'D'
            int 10h
            jmp .skip2
            .next5:
            cmp al,20h
            jne .next6
            mov al,'A'
            int 10h
            jmp .skip2
            .next6:
            cmp al,1|2|4|8|10h|20h
            jne .error
            mov al,'L'
            int 10h
            jmp .skip2
            .error:
            mov al,'E'
            int 10h
        
        .skip2:
        push ax
        mov al,' '
        mov ah,0x0e
        int 10h
        pop ax
        .display_size:
            push si
            mov eax,[si+0x1c]
            call convert
            mov esi,ramstr
            call print_string
            call .clear_ramstr
            pop si
        push si
        mov si,lfcr
        call print_string
        pop si
        .skip:
        add si,20h
        cmp byte [si],0
        jne .loop
    jmp internal_shell.command_prep
    .clear_ramstr:
        mov si,ramstr
        .loop_cr:
            mov byte [si],0
            inc si
            cmp si,ramstr+10
            jne .loop_cr
        ret
printstring_thatendafter8chars:
    pusha
    mov cx,0
    mov ah,0x0e
    .loop:
    cld
    mov al,[si]
    int 10h
    inc cx
    inc si
    cmp cx,11
    jne .loop
    popa
    ret
c_data:
    ls_test db "lstest",10,13,0
    fourspaces db "  ",0
end_c_data:

    
