; VGA_AC_INDEX
; VGA_AC_WRITE
; VGA_AC_READ
VGA_MISC_WRITE		EQU	3C2h
VGA_SEQ_INDEX		EQU	3C4h
VGA_SEQ_DATA		EQU	3C5h
; VGA_DAC-READ_INDEX
; VGA_DAC_WRITE_INDEX
; VGA_DAC_DATA
; VGA_MISC_READ
VGA_CRTC_INDEX		EQU	3D4h
VGA_CRTC_DATA		EQU	3D5h
VGA_INSTAT_READ		EQU	3DAh

NUM_SEQ_REGS		EQU	5
NUM_CRTC_REGS		EQU	25
; NUM_GC_REGS
; NUM_AC_REGS

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
        cmp ah,7
        jne next8
        popa
        pop ax
        push internal_shell.eskip
        iret
    next8:
        cmp ah,8
        jne next9
        popa 
        jmp RelocateEXE
    next9:
        popa
        mov fs,[keyboard_buffer]
        iret

app_return:
        push internal_shell
        iret

RelocateEXE:

        add     ax, [08h]               ; ax = image base
        mov     cx, [06h]               ; cx = reloc items
        mov     bx, [18h]               ; bx = reloc table pointer

        jcxz    RelocationDone

ReloCycle:
        mov     di, [bx]                ; di = item ofs
        mov     dx, [bx+2]              ; dx = item seg (rel)
        add     dx, ax                  ; dx = item seg (abs)

        push    ds
        mov     ds, dx                  ; ds = dx
        add     [di], ax                ; fixup
        pop     ds

        add     bx, 4                   ; point to next entry
        loop    ReloCycle

RelocationDone:

        mov     bx, ax
        add     bx, [0Eh]
        mov     ss, bx                  ; ss for EXE
        mov     sp, [10h]               ; sp for EXE

        add     ax, [16h]               ; cs
        pop fs
        pop fs
        push    ax
        push    word [14h]              ; ip
        iret

write_regs:
pusha
	push si
	push dx
	push cx
	push ax
		cld

; write MISC register
		mov dx,VGA_MISC_WRITE
		lodsb
		out dx,al

; write SEQuencer registers
		mov cx,NUM_SEQ_REGS
		mov ah,0
write_seq:
		mov dx,VGA_SEQ_INDEX
		mov al,ah
		out dx,al

		mov dx,VGA_SEQ_DATA
		lodsb
		out dx,al

		inc ah
		loop write_seq

; write CRTC registers
; Unlock CRTC registers: enable writes to CRTC regs 0-7
		mov dx,VGA_CRTC_INDEX
		mov al,17
		out dx,al

		mov dx,VGA_CRTC_DATA
		in al,dx
		and al,7Fh
		out dx,al

; Unlock CRTC registers: enable access to vertical retrace regs
		mov dx,VGA_CRTC_INDEX
		mov al,3
		out dx,al

		mov dx,VGA_CRTC_DATA
		in al,dx
		or al,80h
		out dx,al

; make sure CRTC registers remain unlocked
		mov al,[si + 17]
		and al,7Fh
		mov [si + 17],al

		mov al,[si + 3]
		or al,80h
		mov [si + 3],al

; now, finally, write them
		mov cx,NUM_CRTC_REGS
		mov ah,0
write_crtc:
		mov dx,VGA_CRTC_INDEX
		mov al,ah
		out dx,al

		mov dx,VGA_CRTC_DATA
		lodsb
		out dx,al

		inc ah
		loop write_crtc
	pop ax
	pop cx
	pop dx
	pop si
	popa
	ret
changevidmode:
    mov [zero],es
    mov ax,40h
    mov es,ax
    mov ax,0x3
    int 0x10
        mov ax,1112h
    xor bl,bl
    int 10h
    mov si,regs_90x60
    call write_regs
    push ds
    push es
    mov ax,0040h
	mov ds,ax
	mov es,ax

	mov word [004Ah],90		; columns on screen

	mov word [004Ch],90*60*2	; framebuffer size

	mov cx,8
	mov di,0050h
	xor ax,ax
	rep stosw			; cursor pos for 8 pages

	mov word [0060h],0607h		; cursor shape

	mov byte [0084h],59		; rows on screen, minus one

	mov byte [0085h],8		; char height, in scan-lines
    pop es
    pop ds
    ret
regs_90x60:
; MISC
	db 0E7h
; SEQuencer
	db 03h, 01h, 03h, 00h, 02h
; CRTC
	db  6Bh, 59h,  5Ah, 82h, 60h,  8Dh, 0Bh,  3Eh,
	db  00h, 47h,  06h, 07h, 00h,  00h, 00h,  00h,
	db 0EAh, 0Ch, 0DFh, 2Dh, 08h, 0E8h, 05h, 0A3h,
	db 0FFh
syscall_data:
zero dq 0
KernelVER db "KERNEL 1.0",10,13,0

end_of_syscall_data:
