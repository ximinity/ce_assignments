all: obj/ecdh25519test_val.elf

CFLAGS=-O0 -g -Wall

obj/test_val.elf: obj/smult.o obj/group.o obj/fe25519.o obj/test_val.o | obj
	$(CC) -o $@ obj/test_val.o obj/smult.o obj/group.o obj/fe25519.o

obj/fe25519.o: fe25519.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/group.o: group.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/smult.o: smult.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj/test_val.o: test_val.c | obj
	$(CC) $(CFLAGS) -o $@ -c $<

obj:
	mkdir -p obj

clean:
	rm -r obj

valgrind: obj/test_val.elf
	valgrind --track-origins=yes obj/test_val.elf
