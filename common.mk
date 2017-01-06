# Default settings
HOSTNAME 	?= $(shell hostname)
USER		?= $(shell whoami)

# Don't inherit path from environment
export PATH	:= /bin:/usr/bin
export SHELL	:= /bin/bash

# Optional configuration
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk
-include userconfig-$(HOSTNAME)-$(USER).mk

TOP	:= $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
Q=@
endif

vpath % .stamps
MKSTAMP = $(Q)mkdir -p .stamps ; touch .stamps/$@
%.force:
	rm -f $(TOP)/.stamps/$*
	$(MAKE) $*

-include cmd.mk
