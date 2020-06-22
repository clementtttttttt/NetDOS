inthandler:
    pusha
    cmp ah,0
    jne next1
    ;ah=0: resets the computer
    jmp 0xfff0:0x0000
    next1:
    cmp ah,1
    jne next2
        call print_string
        popa
        iret
    next2:
    cmp ah,2
    jne next3
        JMP executable_loader
        popa
        iret
    next3:
        mov ax,3
        int 10h
        popa
        iret
executable_loader:
    mov ebx,0x36310c
    mov word ax,[ebx]
    cmp ax,4e44h
    je .load_nde_exec
    .load_flatbin:
        call [ebx]
        iret
    .load_nde_exec:
        iret
syscall_data:



end_of_syscall_data:
