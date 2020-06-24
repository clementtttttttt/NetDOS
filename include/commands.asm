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
            jmp .skip
            .next:
            cmp al,2
            jne .next2
            mov al,'H'
            int 10h
            jmp .skip
            .next2:
            cmp al,4
            jne .next3
            mov al,'S'
            int 10h
            jmp .skip
            .next3:
            cmp al,8
            jne .next4
            mov al,'V'
            int 10h
            jmp .skip
            .next4:
            cmp al,10h
            jne .next5
            mov al,'D'
            int 10h
            jmp .skip
            .next5:
            cmp al,20h
            jne .error
            mov al,'A'
            int 10h
            jmp .skip
            .error:
            mov al,'e'
            int 10h
        .skip:
        push si
        mov si,lfcr
        call print_string
        pop si
        add si,40h
        cmp byte [si],0
        jne .loop
    jmp internal_shell.command_prep
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

    
