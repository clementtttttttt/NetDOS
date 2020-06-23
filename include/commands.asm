hhelp:
    mov si,lfcr
    call print_string
    mov si,helpstr
    call print_string
    jmp internal_shell.command_prep
