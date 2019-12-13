PK := `which pk`

CFLAGS := -static
LLCFLAGS := -march=riscv64
CLANGFLAGS := -S -emit-llvm --target=riscv64 -march=rv64gc

ifneq (,$(filter $(firstword $(MAKECMDGOALS)), clean run))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

help:
	@echo "make PROGRAM [PK=...] | run PROGRAM | clean [PROGRAM...]"

%: %.s
	riscv64-linux-gnu-gcc $(CFLAGS) -o $@ $<

%.s: %.ll
	llc $(LLCFLAGS) -o $@ $<

%.ll: %.c
	clang $(CLANGFLAGS) -o $@ $<

run: $(RUN_ARGS)
	spike $(PK) $^

clean:
	-rm -f *.ll *.o *.s $(RUN_ARGS)

.PHONY: help run clean $(RUN_ARGS)
.SECONDARY:
.SUFFIXES:
