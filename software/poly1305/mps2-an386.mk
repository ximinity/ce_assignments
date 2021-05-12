all: obj/poly1305test.bin

DIR_PREFIX ?= $(CURDIR)/../mk/mps2-an386

include ../mk/mps2-an386/Makefile

%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

obj/poly1305test.elf: obj/poly1305.o obj/test_hal.o $(LINKDEPS) | obj
		$(LD) -o $@ obj/test_hal.o obj/poly1305.o $(LDFLAGS) $(LDLIBS)

obj/poly1305.o: poly1305.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/test_hal.o: test_hal.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj:
	mkdir -p obj

clean:
	rm -r obj

QEMU ?= qemu-system-arm
QEMUARGS ?= -M mps2-an386 -nographic -semihosting -kernel obj/poly1305test.bin

test-qemu: obj/poly1305test.bin
	$(QEMU) $(QEMUARGS)

test-qemu-gdb: obj/poly1305test.bin
	$(QEMU) $(QEMUARGS) -s -S
