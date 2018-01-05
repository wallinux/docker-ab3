# cmd.mk

MAKE	= $(Q)make -s
ECHO 	= $(Q)echo
DOCKER	= $(Q)docker
MKDIR	= $(Q)mkdir -p
RM	= $(Q)rm -f
CP	= $(Q)cp
RED 	= $(Q)tput setaf 1
GREEN 	= $(Q)tput setaf 2
NORMAL 	= $(Q)tput sgr0

define run-note
	$(GREEN)
	$(ECHO) $(1)
	$(NORMAL)
endef


ifeq ($(V),1)
TRACE 	= @(tput setaf 1; echo ------ $@; tput sgr0)
else
TRACE	= @#
endif

