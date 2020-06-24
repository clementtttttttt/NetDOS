
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
   
    mov ax,0x0204
    mov dl,0
    mov dh,1
    mov ch,0
    mov cl,2
    mov bx,fat
    int 13h
    jc .loop
    popa
    ret

ReadCluster:
        mov     bp, sp

        lea     ax, [si-2]
        xor     ch, ch
        mov     cl, 1
                ; cx = sector count
        mul     cx

        add     ax, [bp]
        adc     dx, [bp+1*2]
                ; dx:ax = LBA

        call    ReadSector

        mov     ax, 512
        shr     ax, 4                   ; ax = paragraphs per sector
        mul     cx                      ; ax = paragraphs read

        mov     cx, es
        add     cx, ax
        mov     es, cx                  ; es:bx updated

        add     si, si                  ; si = cluster * 2

        push    ds
        mov     ax, [bp+2*2]            ; ds = FAT segment
        jnc     First64
        add     ax, 1000h               ; adjust segemnt for 2nd part of FAT16
First64:
        mov     ds, ax
        mov     si, [si]                ; si = next cluster
        pop     ds

ReadClusterDone:

        cmp     si, 0FFF8h
        jc      ReadCluster         ; if not End Of File
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
        mov     cx, 11
       
.FindNameCycle:
        cmp     byte [es:di], ch
        je      .FindNameFailed          ; end of root directory
        pusha
        repe    cmpsb
        popa
        je      .FindNameFound
        add     di, 32
        dec     dx
        jnz     .FindNameCycle           ; next root entry
.FindNameFailed:
        stc
        ret
.FindNameFound:

        mov     si, [es:di+1Ah]         ; si = cluster no.
       
        ret

ReadSector:
        pusha

ReadSectorNext:
        mov     di, 5                   ; attempts to read

ReadSectorRetry:
        pusha

        div     word [a]
                ; ax = LBA / SPT
                ; dx = LBA % SPT         = sector - 1

        mov     cx, dx
        inc     cx
                ; cx = sector no.

        xor     dx, dx
        div     word [bpbHeadsPerCylinder]
                ; ax = (LBA / SPT) / HPC = cylinder
                ; dx = (LBA / SPT) % HPC = head

        mov     ch, al
                ; ch = LSB 0...7 of cylinder no.
        shl     ah, 6
        or      cl, ah
                ; cl = MSB 8...9 of cylinder no. + sector no.

        mov     dh, dl
                ; dh = head no.

        mov     dl, 0                ; dl = drive no.

        mov     ax, 201h
                                        ; al = sector count = 1
                                        ; ah = 2 = read function no.

        int     13h                     ; read sectors
        jnc     ReadSectorDone          ; CF = 0 if no error

        xor     ah, ah                  ; ah = 0 = reset function
        int     13h                     ; reset drive

        popa
        dec     di
        jnz     ReadSectorRetry         ; extra attempt
        stc
        ret

ReadSectorDone:
        popa
        dec     cx
        jz      ReadSectorDone2         ; last sector

        add     bx, 512 ; adjust offset for next sector
        add     ax, 1
        adc     dx, 0                   ; adjust LBA for next sector
        jmp     short ReadSectorNext

ReadSectorDone2:
        popa
        ret
ddata:
    bpbHeadsPerCylinder dw 2
    a dw 18
