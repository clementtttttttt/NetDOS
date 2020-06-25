inthandler:
    pusha
    cmp ah,0
    jne next1
    ;ah=0: resets the computer
    jmp 0xfff0:0x0000
    next1:
    cmp ah,1
    jne next2
        call print_string
        popa
        iret
    next2:
    cmp ah,2
    jne next3
        JMP executable_loader
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
        call read_fat2
        popa
        iret
executable_loader:
    mov ebx,0x36310
    mov word ax,[ebx]
    cmp ax,4e44h
    je .load_nde_exec
    .load_flatbin:
        call [ebx]
        iret
    .load_nde_exec:
        iret
convert:
    mov ecx,10
    xor bx,bx
.loop:
    xor edx,edx
    div ecx
    push dx
    inc bx
    test eax,eax
    jnz .loop
    mov cx,bx
.toascii:
    pop ax
    add al,'0'
    mov [si],al
    inc si
    loop .toascii
    ret
    
    
mmap_ent equ 0x8000             ; the number of entries will be stored at 0x8000
do_e820:
        mov di, 0x8004          ; Set di to 0x8004. Otherwise this code will get stuck in `int 0x15` after some entries are fetched 
	xor ebx, ebx		; ebx must be 0 to start
	xor bp, bp		; keep an entry count in bp
	mov edx, 0x0534D4150	; Place "SMAP" into edx
	mov eax, 0xe820
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes
	int 0x15
	jc short .failed	; carry set on first call means "unsupported function"
	mov edx, 0x0534D4150	; Some BIOSes apparently trash this register?
	cmp eax, edx		; on success, eax must have been reset to "SMAP"
	jne short .failed
	test ebx, ebx		; ebx = 0 implies list is only 1 entry long (worthless)
	je short .failed
	jmp short .jmpin
.e820lp:
	mov eax, 0xe820		; eax, ecx get trashed on every int 0x15 call
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes again
	int 0x15
	jc short .e820f		; carry set means "end of list already reached"
	mov edx, 0x0534D4150	; repair potentially trashed register
.jmpin:
	jcxz .skipent		; skip any 0 length entries
	cmp cl, 20		; got a 24 byte ACPI 3.X response?
	jbe short .notext
	test byte [es:di + 20], 1	; if so: is the "ignore this data" bit clear?
	je short .skipent
.notext:
	mov ecx, [es:di + 8]	; get lower uint32_t of memory region length
	or ecx, [es:di + 12]	; "or" it with upper uint32_t to test for zero
	jz .skipent		; if length uint64_t is 0, skip entry
	inc bp			; got a good entry: ++count, move to next storage spot
	add di, 24
.skipent:
	test ebx, ebx		; if ebx resets to 0, list is complete
	jne short .e820lp
.e820f:
	mov [mmap_ent], bp	; store the entry count
	clc			; there is "jc" on end of list to this point, so the carry must be cleared
	ret
.failed:
	stc			; "function unsupported" error exit
	ret
syscall_data:

KernelVER db "KERNEL 1.0",10,13,0

end_of_syscall_data:
