all: obj/ecdh25519test.bin

DIR_PREFIX ?= $(CURDIR)/../mk/mps2-an386

include ../mk/mps2-an386/Makefile

%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

obj/ecdh25519test.elf: obj/smult.o obj/group.o obj/fe25519.o obj/test_hal.o $(LINKDEPS) | obj
		$(LD) -o $@ obj/test_hal.o obj/smult.o obj/group.o obj/fe25519.o $(LDFLAGS) $(LDLIBS)

obj/fe25519.o: fe25519.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/group.o: group.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/smult.o: smult.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/test_hal.o: test_hal.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj:
	mkdir -p obj

clean:
	rm -r obj

QEMU ?= qemu-system-arm
QEMUARGS ?= -M mps2-an386 -nographic -semihosting -kernel obj/ecdh25519test.bin

test-qemu: obj/ecdh25519test.bin
	$(QEMU) $(QEMUARGS)

test-qemu-gdb: obj/ecdh25519test.bin
	$(QEMU) $(QEMUARGS) -s -S
