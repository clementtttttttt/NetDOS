main:
    mov byte [kbs],0xb0
    call setkl
    .loop:
        xor byte [kbs],4
        call setkl
        hlt
        and   byte [kbs],0xfb
        call  setkl
        hlt
        jmp .loop
    
    
    
    
    
    
    
    
setkl:
    push  eax
   mov   al,0xed                 
   out   60h,al                 
KeyBoardWait:
   in    al,64h
   test  al,10b                 
   jne   KeyBoardWait              
   mov   al,byte [kbs]
   and   al,111b
   out   60h,al                 
   pop   eax
   ret
    
    
kbs db 0
