# Repository for cryptographic engineering assignments

## Structure

The src directory contains the code given for the assignment. The structure is
kept intact. The individual implementations are updated as required by the
assignments.

## QEMU

The makefiles have been modified to support building for the mps2-an386 target.
This can be used to test the implementation in QEMU. To use this for e.g.
chacha20 run

	$ cd src/chacha20
	$ PLATFORM=mps2-an386 make test-qemu

An additional target `test-qemu-gdb` has also been added. This starts QEMU with
the `-s -S` options to easily integrate with gdb. Each directory also contains a
`.gdbinit` that contains some useful defaults.
