# Default settings
HOSTNAME 	?= $(shell hostname)
USER		?= $(shell whoami)

# Don't inherit path from environment
export PATH	:= /bin:/usr/bin
export SHELL	:= /bin/bash
export TERM 	:= xterm

# Optional configuration
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk
-include userconfig-$(HOSTNAME)-$(USER).mk

TOP	:= $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
export Q=@
endif
export V

.PHONY: *.help

define run-help
	$(GREEN)
	$(ECHO) -e "\n----- $@ -----"
	$(Q)grep ":" $(1) | grep -v -e grep | grep -v "\#\#" | grep -e "\#" | sed 's/:/#/' | cut -d'#' -f1,3 | sort | column -s'#' -t
	$(NORMAL)
endef

STAMPSDIR = $(TOP)/.stamps
vpath % $(STAMPSDIR)
MKSTAMP = $(Q)mkdir -p $(STAMPSDIR) ; touch $(STAMPSDIR)/$@
%.force:
	$(call rmstamp, $*)
	$(MAKE) $*

define rmstamp
	$(RM) $(STAMPSDIR)/$(1) 
endef

-include cmd.mk
