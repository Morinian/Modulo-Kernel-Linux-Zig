KDIR ?= /lib/modules/$(shell uname -r)/build

.PHONY: all module client clean

all: module client

module:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/kernel modules

client:
	zig build-exe client/main.zig -O ReleaseSafe -femit-bin=zigcalc

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR)/kernel clean
	rm -f kernel/zigcalc_core.o kernel/.zigcalc_core.o.cmd zigcalc
