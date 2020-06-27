
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
bpbSectorsPerCluster db 1
bpbBytesPerSector dw 512
bpbSectorsPerTrack dw 18
bsDriveNumber db 0
ReadNextCluster:


;; Reads a sector using BIOS Int 13h fn 2 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Input:  DX:AX = LBA                    ;;
;;         CX    = sector count           ;;
;;         ES:BX -> buffer address        ;;
;; Output: CF = 1 if error                ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ReadSector:
        pusha

ReadSectorNext:
        mov     di, 5                   ; attempts to read

ReadSectorRetry:
        pusha

        div     word [bpbSectorsPerTrack]
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

        mov     dl, [bsDriveNumber]
                ; dl = drive no.

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

        add     bx, [bpbBytesPerSector] ; adjust offset for next sector
        add     ax, 1
        adc     dx, 0                   ; adjust LBA for next sector
        jmp     short ReadSectorNext

ReadSectorDone2:
        popa
        ret
