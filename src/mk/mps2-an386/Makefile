MPS2_DATA_IN_FLASH = 1
CROSS_PREFIX ?= arm-none-eabi
CC := $(CROSS_PREFIX)-gcc
CPP := $(CROSS_PREFIX)-cpp
AR := $(CROSS_PREFIX)-ar
LD := $(CC)
GDB = gdb-multiarch
OBJCOPY := $(CROSS_PREFIX)-objcopy
SIZE := $(CROSS_PREFIX)-size

LDSCRIPT = $(OBJDIR)/ldscript.ld

ARCH_COMMON_FLAGS += -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
ARCH_FLAGS += -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
ARFLAGS = rcs

CFLAGS += \
	$(ARCH_FLAGS) \
	--specs=nano.specs \
	--specs=nosys.specs \
	-g \
	-O3 \
	-Wall -Wextra -Wimplicit-function-declaration \
	-Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes \
	-Wundef -Wshadow \
	-fno-common \
	-MD \
	-I$(DIR_PREFIX)/include \
	-I$(DIR_PREFIX)/common/mps2

LDFLAGS += \
	--specs=nano.specs \
	--specs=nosys.specs \
	-Wl,--wrap=_sbrk \
	-ffreestanding \
	-Lobj \
	-T$(LDSCRIPT) \
	$(ARCH_FLAGS)

LIBHAL_SRC := \
	$(DIR_PREFIX)/common/mps2/startup_MPS2.S \
	$(DIR_PREFIX)/common/hal-mps2.c

$(OBJDIR)/libpqm4hal.a: $(OBJDIR)/common/hal-mps2.o $(OBJDIR)/common/mps2/startup_MPS2.S.o | mps2dir
	$(AR) $(ARFLAGS) $@ $(OBJDIR)/common/hal-mps2.o $(OBJDIR)/common/mps2/startup_MPS2.S.o

$(LDSCRIPT): CFLAGS += $(if $(MPS2_DATA_IN_FLASH),-DDATA_IN_FLASH)

$(OBJDIR)/common/mps2/startup_MPS2.S.o: $(DIR_PREFIX)/common/mps2/startup_MPS2.S | mps2dir
	$(CC) $(CFLAGS) -o $@ -c $<
$(OBJDIR)/common/mps2/startup_MPS2.S.o: CFLAGS += $(if $(MPS2_DATA_IN_FLASH),-DDATA_IN_FLASH)

$(OBJDIR)/common/hal-mps2.o: $(DIR_PREFIX)/common/hal-mps2.c | mps2dir
	$(CC) $(CFLAGS) -o $@ -c $<

mps2dir:
	mkdir -p obj/common/mps2

LDLIBS += -lpqm4hal
LIBDEPS += $(OBJDIR)/libpqm4hal.a

$(LDSCRIPT): $(DIR_PREFIX)/common/mps2/MPS2.ld
	@printf "  GENLNK  $@\n"; \
	[ -d $(@D) ] || $(Q)mkdir -p $(@D); \
	arm-none-eabi-gcc -x assembler-with-cpp -E -Wp,-P $(CFLAGS) $< -o $@

LINKDEPS += $(LDSCRIPT) $(LIBDEPS)
