hhelp:
    mov si,lfcr
    call print_string
    mov si,helpstr
    call print_string
    jmp internal_shell.command_prep


lsc:
    mov si,lfcr
    call print_string
    mov si,fat+2600h
    .loop:
        cmp byte [si],0xe5
        je .skip
        call printstring_thatendafter8chars
        push si
        mov si,fourspaces
        call print_string
        pop si
        .skip:
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

    
