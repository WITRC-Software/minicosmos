# SPDX-License-Identifier: BSD-3-Clause
# Minicosmos
# (C) 2021 China First Softwere Factory, All rights reserved.

# Main Makefile of Global

include tools/err.mk

arch = NOTHING

everything:
	@echo "Making..."
ifeq ($(arch),NOTHING)
	@echo "Error:" $(ERR_NO_ARCH_S) "(" $(ERR_NO_ARCH) ")"
	@exit
endif
	@make -C arch/$(arch)/	everything

clean:
	@echo "Making..."
ifeq ($(arch),NOTHING)
	@echo "Error:" $(ERR_NO_ARCH_S) "(" $(ERR_NO_ARCH) ")"
	@exit
endif
	@make -C arch/$(arch)/	clean

cleanall:
	@echo "Making..."
ifeq ($(arch),NOTHING)
	@echo "Error:" $(ERR_NO_ARCH_S) "(" $(ERR_NO_ARCH) ")"
	@exit
endif
	@make -C arch/$(arch)/	cleanall


# debug

try:
	@echo "Making..."
ifeq ($(arch),NOTHING)
	@echo "Error:" $(ERR_NO_ARCH_S) "(" $(ERR_NO_ARCH) ")"
	@exit
endif
	@make -C arch/$(arch)/	try
	
d_try:	
	@echo "Making..."
ifeq ($(arch),NOTHING)
	@echo "Error:" $(ERR_NO_ARCH_S) "(" $(ERR_NO_ARCH) ")"
	@exit
endif
	@make -C arch/$(arch)/	d_try

