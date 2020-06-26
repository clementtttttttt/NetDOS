use16
org 100h
code:

jmp clear_screen
clear_screen:
    mov ax,0x3
    int 0x10
    
    mov si,init
    call print_string
setup_stack:
    mov ax,0x7f0
    mov ss,ax
    mov sp,0
reset_floppy:
    mov ah,0
    xor dl,dl
    int 13h
unreal_mode:
    cli
    push ds
    lgdt[gdtinfo]
    
    mov eax,cr0
    or al,1
    mov cr0,eax
    pmode:
    use32
    jmp $+2
    mov bx,0x08
    mov ds,bx
    and al,0xfe
    mov cr0,eax
    real:
    
    use16
    pop ds
    sti
    mov si,unrealmodeok
    call print_string
a20:
    call enable_A20
pit_setup:
    cli
    mov ax,0
    mov es,ax
    mov word [es:8*4],irq0
    mov word [es:8*4+2],50h
    mov al,0x34
    out 0x43,al
    mov ax,0x2e9c
    out 0x40,al
    mov al,ah
    out 0x40,al
    mov al,10111101b
    out 21h,al
    sti
    
setup_system_call:
    cli
    mov ax,0
    mov es,ax
    mov word [es:40h*4],inthandler
    mov word [es:40h*4+2],0x50
    mov word [es:9h*4],irq1
    mov word [es:9h*4+2],50h
    mov word [es:6h*4],illegalinstruct
    mov word [es:6h*4+2],50h
    mov word [es:0h],1
    sti

    mov si,syscallok
    call print_string
    mov si,manfacstr
    call print_string
check_cpuid_exist:
    pushfd
    pushfd
    xor dword [esp],0x00200000
    popfd
    pushfd 
    pop eax
    xor eax,[esp]
    popfd
    and eax,0x00200000
    cmp eax,0
    jne OK
    mov si,cpuidunsupportedstr
    call print_string
    jmp read_fat
OK:
sti

mov eax,80000002h
getcpuinfo:
    push eax
    cpuid
    push edx
    push ecx
    push ebx
    push eax
    mov ebx,edxx
    pop dword [ebx]
    mov ebx,ecxx
    pop dword [ebx]
    mov ebx,ebxx
    pop dword [ebx]
    mov ebx,eaxx
    pop dword [ebx]
    xor si,si
    mov si,cpustr
    call print_string
    pop eax
    add eax,1
    cmp eax,80000002h+2
    jle getcpuinfo
    mov si,lfcr
    call print_string
read_fat:
    mov ax,0x0212
    mov dl,0
    mov dh,0
    mov ch,0
    mov cl,2
    push ds
    pop es
    mov bx,fat
    int 13h
    mov ax,0x0204
    mov dl,0
    mov dh,1
    mov ch,0
    mov cl,1
    mov bx,fat+18*512
    int 13h
    jc read_fat

findinit:
    mov si,initprog
    mov di,fat+2600h
    call FindName
  

        
    jc internal_shell
load_init:
    stc
cli
    mov si,fatal_error
    call print_string
halt:
    hlt
    jmp halt

print_string:				; Output string in SI to screen
	pusha
    mov ah,0x0e
    CLD
.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string
	int 0x10
	jmp short .repeat

.done:
	popa 
	ret


internal_shell:
    cld
    sti
    mov si,intershell
    call print_string
     mov ah,4
    int 40h
    mov si,fs
    call print_string
    .command_prep:
        mov si,commandline
        call print_string
   
    
        xor bx,bx
            mov di,commandstr
        call .clearcommandstr
        mov byte [keyboard_buffer],0
    .command:
        cmp byte [keyboard_buffer],0
        je .skip
                cmp byte [keyboard_buffer],' '
        je .space_handler
        cmp byte [keyboard_buffer],10
        je .execute_command
        cmp byte [keyboard_buffer],0x08
        jne .backskip

            cmp di,commandstr
            je .skip
            mov si,backspace
            call print_string
            mov byte [di],0
            dec di
            mov byte [di],0
            jmp .skip
        .backskip:
        mov al,[keyboard_buffer]
        mov ah,0x0e
        int 10h
        mov [di],al
        inc di
        .skip:
        mov byte [keyboard_buffer],0
        hlt
        jmp .command
    .execute_command:
        push ds
        pop es
        cmp byte [commandstr],0
        je .command_prep
        mov cx,4
        mov si,commandstr
        mov di,help
        rep cmpsb
        je hhelp
        mov si,commandstr
        mov di,ls
        mov cx,3
        rep cmpsb
        je lsc
        mov si,commandstr
        mov di,clear
        mov cx,6
        rep cmpsb
        je clear_command
        mov si,commandstr
        mov di,kernel
        mov cx,12
        rep cmpsb
        je bootloaderonly
        mov si,commandstr
        mov di,rm
        mov cx,3
        rep cmpsb
        je .rmc
        jmp .execute_file
.rmc:
    mov ah,7
    int 40h
    push fs
    retw
    .command_not_found:
        mov si,command_not_found
        call print_string 
        jmp .command_prep
    .clearcommandstr:
        cmp di,commandstr+100
        je return
        mov byte [di],20h
        inc di
        jmp .clearcommandstr
    .space_handler:
        mov al,' '
        mov ah,0x0e
        int 10h
        mov byte [di],20h
        inc di
        jmp .skip
    .execute_file:
        sti
        call read_fat2
        xor cx,cx
        xor bx,bx
        jmp .enameloop
        .retryentry:
            cmp cx,1
            je .break
            inc cx
            jmp .loop2
            inc si
            .loop2:
                cmp byte [si],0
                jne .loop2-1
            mov si,commandstr
            add si,8
            mov byte [si],'N'
            inc si
            mov byte [si],'D'
            inc si
            mov byte [si],'F'
            mov si,commandstr
        .enameloop:
            push ds
            pop es
            call read_fat2

            mov di,fat
            mov si,commandstr
            
            mov dx,224
            call FindName
            mov [tempw],si
            mov [tempw2],fs
            jc .retryentry
            
            jnc .eskip
          
            .break:
            mov si,command_not_found
            call print_string
            jmp .command_prep
        .eskip:
            mov si,lfcr
            call print_string
            mov si,loadingprogram
            call print_string
            call load_fat_data
            
            mov dx,[tempw]
            mov cx,512
            mov ax,dx
            .loopbreak:
            pusha
              
                popa
                add dx,ax
                dec cx
                cmp cx,1
              
                jne .loopbreak
            mov si,fat
            add si,dx
            
            push word 0x7e0
            pop es
            mov cx,[tempw2]
            mov di,0
            rep movsw
            push ds
            mov ax,0x7e0
            mov ds,ax
            call 0x7e0:0
            pop ds
            jmp internal_shell.command_prep

return:
    mov di,commandstr
    ret
bootloaderonly:
    mov si,bootloadonly
    mov ah,1
    int 40h
    jmp internal_shell.command_prep
data:
    loadingprogram db 10,13,"Loading program...",10,13,0
    upgraderam db 10,13,"Upgrade your ram to 1.2mb in order to unlock executing programs.",10,13,0
    kernel db "UKERNEL COM",20h
    bootloadonly db  10,13,"Running kernel is disallowed since it might break in some hardware.",10,13,0
    tempw2 dw 0
    tempw dw 0
    ramstr times 10 db 0
    cpuflag db 0
    rm db "rm",20h
    ls db "ls",20h
    clear db "clear",20h
    helpstr db "ls=list directory",10,13,"program-name=execute program",10,13,0
    cpuidunsupportedstr db "CPU IS BEFORE i486-DX2,CONSIDER BUYING A NEW COMPUTER",10,13,0
    help db "help",20h
    backspace db 0x8,0x20,0x8,0
    currentaddr dw 0
    temp dd 0
    lfcr db 10,13,0
    fatal_error db "KERNEL PANIC: INIT RETURNED (Which is not supposed to)",10,13,0
    command_not_found db 10,13,"Invalid command,view a list of commands by typing help (CASE SENSITIVE!!!)",10,13,0
    intershell db "NetDOS NDSH version 1.0",10,13,"Written by clementtttttttt at the age of 13,with ",0
    bps dw 512
    nof db 2
    rst dw 1
    sfi db "Searching for the INIT program...",10,13,0
    initprog     db      "INIT    ndf"   ; name and extension each must be
	init db "Starting NetDos...",10,13,0
    datasector dw 0
    unrealmodeok db "Unreal Mode Initialized.",10,13,0
    syscallok db "System call and IRQ1 is initialized.",10,13,0
    commandline db 10,13,"A:/$ ",0
    gdtinfo:
            dw gdt_end - gdt - 1   ;last byte in table
            dd gdt                 ;start of table
 
    gdt         dd 0,0        ; entry 0 is always unused
    flatdesc    db 0xff, 0xff, 0, 0, 0, 10010010b, 11001111b, 0
 
    gdt_end:
        times 10 nop
    keyboard_buffer:   
        db 0
        db 0
    times 10 nop
    cpustr: 
        edxx dd 0
        ecxx dd 0
        ebxx dd 0
        eaxx dd 0
        db 0
    manfacstr db "CPU model is:",0
    dummy db fat
end_of_data:
commandasm:
    %include "include/commands.asm"
end_of_commandasm:

sasm:
    %include "include/syscall.asm"
end_of_sasm:
nop
kasm:
    %include "include/keyboard.asm"
end_of_kasm:
nop
dasm:
    %include "include/disk.asm"
end_of_dasm:
nop
    commandstr times 100 db 20h

fat:
    times 8 db 3
    
