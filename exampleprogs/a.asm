mov si,helloworld
mov ah,1
int 40h
retf

helloworld db "Hello World!",10,13,0
