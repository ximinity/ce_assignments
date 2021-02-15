all: obj/chacha20test.bin

DIR_PREFIX ?= $(CURDIR)/../mk/mps2-an386

include ../mk/mps2-an386/Makefile

%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

obj/chacha20test.elf: obj/chacha20.o obj/test_hal.o $(LINKDEPS) | obj
		$(LD) -o $@ obj/test_hal.o obj/chacha20.o $(LDFLAGS) $(LDLIBS)

obj/chacha20.o: chacha20.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/test_hal.o: test_hal.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj:
	mkdir -p obj

clean:
	rm -r obj

QEMU ?= qemu-system-arm
QEMUARGS ?= -M mps2-an386 -nographic -semihosting -kernel obj/chacha20test.bin

test-qemu: obj/chacha20test.bin
	$(QEMU) $(QEMUARGS)

test-qemu-gdb: obj/chacha20test.bin
	$(QEMU) $(QEMUARGS) -s -S
