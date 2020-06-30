mov ax,0x13
int 10h
mov ax,0
mov ds,ax
mov ebx,0xa0000
mov byte [ebx],15
jmp $
