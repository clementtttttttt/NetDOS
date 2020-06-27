mov ax,0x13
int 10h
xor ax,ax
mov ds,ax
mov ebx,0xa8000
mov byte [ebx],15
jmp $
