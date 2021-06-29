PLATFORM ?= stm32f4

OBJDIR ?= $(CURDIR)/obj

ifeq (,$(wildcard $(PLATFORM).mk))
$(error Unknown platform $(PLATFORM))
endif

include ./$(PLATFORM).mk
