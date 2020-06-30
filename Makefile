
test:out.img
	@echo "[QEMU] $<"
	@qemu-system-i386 -fda out.img -cpu SandyBridge > /dev/null
all:out.img

UKERNEL.COM:kernel.asm include/*.asm
	@echo "[NASM] $<"
	@nasm kernel.asm -o $@
out.img:UKERNEL.COM
	@echo "[MKDOSFS] out.img"
	-@mkdosfs -C out.img 1440 -F 16 > /dev/null 2>&1
	@echo "[DD] boot16 out.img" 
	@dd if=boot16 of=out.img conv=notrunc status=none > /dev/null  
	@echo "[MOUNT] out.img"
	@sudo mount out.img temp -o fat=16 > /dev/null
	@echo "[CP] UKERNEL.COM TEMP"
	@sudo cp UKERNEL.COM temp/
	@sleep 0.6
	@echo "[UMOUNT] TEMP"
	@sudo umount temp
	
