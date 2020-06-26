enable_A20:
        cli
 
        call    a20wait
        mov     al,0xAD
        out     0x64,al
 
        call    a20wait
        mov     al,0xD0
        out     0x64,al
 
        call    a20wait2
        in      al,0x60
        push    eax
 
        call    a20wait
        mov     al,0xD1
        out     0x64,al
 
        call    a20wait
        pop     eax
        or      al,2
        out     0x60,al
 
        call    a20wait
        mov     al,0xAE
        out     0x64,al
 
        call    a20wait
        sti
        ret
 
a20wait:
        in      al,0x64
        test    al,2
        jnz     a20wait
        ret
 
 
a20wait2:
        in      al,0x64
        test    al,1
        jz      a20wait2
        ret
inthandler:
    pusha
    cmp ah,0
    jne next1
    ;ah=0: resets the computer
    jmp 0xffff:0x0000
    next1:
    cmp ah,1
    jne next2
        call print_string
        popa
        iret
    next2:
    cmp ah,2
    jne next3
        JMP app_return
        popa
        iret
    next3:
        cmp ah,3
        jne next4
        mov ax,3
        int 10h
        popa
        iret
    next4:
        cmp ah,4
        jne next5
        mov ax,KernelVER
        mov fs,ax
        popa
        iret
    next5:
        cmp ah,5
        jne next6
        call read_fat2
        popa
        iret
    next6:
        cmp ah,6
        jne next7
        mov si,commandstr
        mov fs,si
        popa 
        iret
    next7:
        mov si,internal_shell.command_prep
        mov fs,si
        popa
        iret
app_return:
        push internal_shell
        iret

    
    
syscall_data:

KernelVER db "KERNEL 1.0",10,13,0

end_of_syscall_data:
