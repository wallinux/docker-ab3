# cmd.mk

CP	= $(Q)cp
DOCKER	= $(Q)docker
ECHO 	= $(Q)echo
GREEN 	= $(Q)tput setaf 2
MAKE	= $(Q)make -s
MKDIR	= $(Q)mkdir -p
NORMAL 	= $(Q)tput sgr0
PODMAN	= $(Q)podman
RED 	= $(Q)tput setaf 1
RM	= $(Q)rm -f

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

