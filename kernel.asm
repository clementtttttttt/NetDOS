use16
org 100h
code:

jmp clear_screen
clear_screen:
    mov ax,0x3
    int 0x10

    mov si,init
    call print_string
    cli

unreal_mode:
    push ds
    lgdt[gdtinfo]
    mov eax,cr0
    or al,1
    mov cr0,eax
    use32
    jmp $+2
    mov bx,0x08
    mov ds,bx
    and al,0xfe
    mov cr0,eax
    use16
    pop ds
    sti
    mov si,unrealmodeok
    call print_string
setup_system_call:

    mov ax,0
    mov es,ax
    mov word [es:40h*4],inthandler
    mov word [es:40h*4+2],0x50
    mov word [es:9h*4],irq1
    mov word [es:9h*4+2],50h
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
clean_fat:
    mov si,fat+2600h
    .loop:
        cmp byte [si],0xe5
        jne .skip
        .loop2:
            push si
            mov byte [si],0
            inc si
            pop ax
            add ax,32
            cmp si,ax
            jg .return
            jmp .loop2
        .skip:
        inc si
        .return:
        cmp si,fat+2600h+(224*32)
        jg .loop
findinit:
    mov si,initprog
    mov di,fat+2600h
    call FindName
load_ring3:
  

        
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
        cmp byte [commandstr],0
        je .command_prep
        mov cx,5
        mov si,commandstr
        mov di,help
        rep cmpsb
        je hhelp
        mov si,commandstr
        mov di,ls
        mov cx,3
        rep cmpsb
        je lsc
        jmp .command_not_found
        
    .command_not_found:
        mov si,command_not_found
        call print_string 
        jmp .command_prep
    .clearcommandstr:
        cmp di,commandstr+100
        je return
        mov byte [di],0
        inc di
        jmp .clearcommandstr
return:
    mov di,commandstr
    ret

data:
    ls db "ls",0
    clear db "clear",0
    helpstr db "ls=list directory",10,13,"program-name=execute program",10,13,0
    cpuidunsupportedstr db "CPU IS BEFORE i486-DX2,CONSIDER BUYING A NEW COMPUTER",10,13,0
    help db "help",0
    backspace db 0x8,0x20,0x8,0
    currentaddr dw 0
    temp dd 0
    lfcr db 10,13,0
    fatal_error db "KERNEL PANIC: INIT RETURNED (Which is not supposed to)",10,13,0
    command_not_found db 10,13,"Invalid command,view a list of commands by typing help (CASE SENSITIVE!!!)",10,13,0
    intershell db "NetDOS NDSH version 1.0",10,13,"Written by clementtttttttt in the age of 13,with ",0
    bps dw 512
    nof db 2
    rst dw 1
    sfi db "Searching for the INIT program...",10,13,0
    initprog     db      "INIT    ndf"   ; name and extension each must be
    CRLF db 10,13,0
	init db "Starting NetDos...",10,13,0
    datasector dw 0
    unrealmodeok db "Unreal Mode Initialized.",10,13,0
    syscallok db "System call and IRQ1 is initialized.",10,13,0
    commandline db 10,13,"A:/$ ",0
    gdtinfo:
            dw gdt_end - gdt - 1   ;last byte in table
            dd gdt                 ;start of table
 
    gdt         dd 0,0        ; entry 0 is always unused
    flatdesc    db 0xff, 0xff, 0, 0, 0, 10011010b, 11001011b, 0
 
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
    commandstr times 100 db 0

fat:
    times 8 db 3
    
