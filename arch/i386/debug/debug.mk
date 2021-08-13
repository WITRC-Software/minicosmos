# debug.mk of i386

debug_default=fdfat12
debug_mode=$(debug_default)

MNT = debug/mount

FD = debug/fd.img

ifeq ($(debug_mode),fdfat12)
HEAD_BIN = boot/fat12head.bin
RUN_BIN = boot/fat12run.bin
args = -m 128M -fda $(FD) -boot a
endif

$(FD):
	@dd if=/dev/zero of=$@ bs=512 count=2880

debug_image: $(FD)
	@dd if=$(HEAD_BIN) of=$(FD) bs=512 count=1 conv=notrunc
	@sudo mount -o loop $(FD) $(MNT)
	@sudo cp $(RUN_BIN) $(MNT)/run.bin -v
	@echo "copy run.bin"
	@sudo umount $(FD)

debug_try: debug_image
	@qemu-system-i386 $(args)
	@exit

debug_d_try:debug_image

