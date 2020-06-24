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
    cmp al,0x2a
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
    popa
    iret
kdata:
    .ctrlbit db 0
    .shiftbit db 0
    .temp db 0
    .lookup_table dw 0
        db "1234567890-=",8h,9h,"qwertyuiop[]",10,0x9e,"asdfghjkl;",27h,'`',0x7a,"\zxcvbnm,./",0,0,0,20h,0x7c
        times (0xe5-0x3b) db 0
    .lookup_table_shift dw 0
        db "!@#$%^&*()_+",8h,9h,"QWERTYUIOP{}",10,0,"ASDFGHJKL:",22h,0x2d,0x7a,0x7c,"ZXCVBNM",'<','>','?',0,0,0,20h,0x7c
        times (0xe5-0x3b) db 0
end_of_kdata:

