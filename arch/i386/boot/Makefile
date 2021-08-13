# SPDX-License-Identifier: BSD-3-Clause
# Minicosmos
# (C) 2021 China First Softwere Factory, All rights reserved.

# Makefile of 8086,boot

ASM=nasm

BINS = \
	fat12head.bin \
	fat12run.bin

%.bin: %.asm
	@$(ASM) -o $@ $<
	@echo "[asm]" $< -\> $@

everything:$(BINS)

clean:
	@rm -f $(BINS)

cleanall:clean

