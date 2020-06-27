 irq0:
    pusha
    mov al,20h
    out 20h,al
    popa
    iret
irq1:    
    pusha
    mov al,20h
    out 20h,al
    in al,60h
    cmp al,0x01
    je break
    cmp al,0x3b
    je reset
    cmp al,0x2a
    je shift_handler
    cmp al,0x3a
    je shift_handler
    cmp al,0xaa
    je shift_handler
    
    mov [kdata.temp],al
    return_point:
    cmp byte [kdata.shiftbit] , 1
    je shift
    mov bx,kdata.lookup_table
    shiftreturnpoint:
    add bx,[kdata.temp]
    mov byte al,[bx]
    cmp al,0
    je skip
    mov bx,keyboard_buffer
    mov byte [bx],al
    skip:
    popa
    iret
break:
    mov ax,0xffff
    mov es,ax
    mov bx,0x10
    mov byte [es:bx],0
    mov ax,50h
    mov es,ax
    mov ds,ax
    mov fs,ax
    mov gs,ax
   popa
    mov si,kdata.break
    call print_string
    pop ax
    pop ax
    push 50h
    push internal_shell
    mov bx,0x7e00
  .loop:
                mov byte [bx],0
                cmp byte [bx],0
                jne .loop
    mov ah,3
    int 40h
    iret
reset:
    jmp 0xffff:0000
shift:
    mov bx,kdata.lookup_table_shift
    jmp shiftreturnpoint
shift_handler:
    mov ax,[kdata.shiftbit]
    xor ax,1
    mov [kdata.shiftbit],ax
    jmp skip
    
illegalinstruct:

    
    pusha
  
    mov si,kdata.illegalins
    call print_string

    mov si,lfcr
    call print_string
    popa
    mov ax,50h
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    pop ax
    pop ax
    push 50h
    push internal_shell.command_prep
    iret
convert:
    mov ecx, 10        ; divisor
    xor ebx, ebx          ; count digits

divide:
    xor edx, edx        ; high part = 0
    div ecx             ; eax = edx:eax/ecx, edx = remainder
    push edx             ; DL is a digit in range [0..9]
    inc ebx              ; count digits
    test eax, eax       ; EAX is 0?
    jnz divide          ; no, continue

    ; POP digits from stack in reverse order
    mov ecx, ebx          ; number of digits
    lea esi, [ramstr]   ; DS:SI points to string buffer
next_digit:
    pop eax
    add al, '0'         ; convert to ASCII
    mov [si], al        ; write it to the buffer
    add si,1
    loop next_digit
    ret
kdata:
    .break db 10,13,"BREAK",13,10,0
    .illegalins db 10,13,"Illegal instruction(INT 6)",0
    .ctrlbit db 0
    .shiftbit db 0
    .temp db 0
    .lookup_table dw 0
        db "1234567890-=",8h,9h,"qwertyuiop[]",10,0x9e,"asdfghjkl;",27h,'`',0x7a,"\zxcvbnm,./",0,0,0,20h,'C'
        times (0xe5-0x3b) db 0
    .lookup_table_shift dw 0
        db "!@#$%^&*()_+",8h,9h,"QWERTYUIOP{}",10,0,"ASDFGHJKL:",22h,'~',0x7a,0x7c,"ZXCVBNM",'<','>','?',0,0,0,20h,0x2a
        times (0xe5-0x3b) db 0
end_of_kdata:

