
test:out.img
	qemu-system-i386 -fda out.img -cpu SandyBridge
all:out.img

UKERNEL.COM:kernel.asm include/*.asm
	nasm kernel.asm -o $@
out.img:UKERNEL.COM
	-mkdosfs -C out.img 1440 -F 16
	-sudo umount temp
	dd if=boot16 of=out.img conv=notrunc
	sudo mount out.img temp -o fat=16
	sudo cp UKERNEL.COM temp/
	sleep 0.6
	sudo umount temp
	
