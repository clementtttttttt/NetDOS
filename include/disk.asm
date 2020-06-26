
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reads a FAT16 cluster      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inout:  ES:BX -> buffer    ;;
;;         SI = cluster no    ;;
;; Output: SI = next cluster  ;;
;;         ES:BX -> next addr ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
read_fat2:
    mov ah,0
    mov dl,0
    int 13h
    pusha
    .loop:
   mov ax,0x0203
    mov dl,0
    mov dh,1
    mov ch,0
    mov cl,2
    mov bx,fat
    int 13h
    jc .loop
    popa
    ret


load_fat_data:
    push ds
    pop es
    mov ah,0x02
    mov al,5
    mov dl,0
    mov cl,13
    mov ch,0
    mov dh,1
    mov bx,fat
    int 13h
    mov dl,0
    mov cl,1
    mov ch,1
    mov dh,0
    mov ax,0x0218
    mov bx,fat+(5*512)
    int 13h
    mov dl,0
    mov cl,10x
    mov ch,1
    mov dh,1
    mov ax,0x0218
    mov bx,fat+(18+5)*512
    int 13h
    ret
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Looks for a file/dir by its name      ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Input:  DS:SI -> file name (11 chars) ;;
;;         ES:DI -> root directory array ;;
;;         DX = number of root entries   ;;
;; Output: SI = cluster number           ;;
;;carry if file not found                ;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FindName:
        push cx
        mov     cx, 11
       
.FindNameCycle:
        cmp     byte [es:di], ch
        je      .FindNameFailed          ; end of root directory
        pusha
        repe    cmpsb
        popa
        je      .FindNameFound
        add     di, 20h
        dec     dx
        jnz     .FindNameCycle           ; next root entry
.FindNameFailed:
        pop cx
        stc
        ret
.FindNameFound:
        pop cx
        mov     si, [di+0x1a]         ; si = cluster no.
        mov fs,[di+0x1c]
        
        ret

ddata:
    bpbHeadsPerCylinder dw 2
    a dw 18
