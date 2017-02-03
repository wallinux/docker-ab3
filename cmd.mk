# cmd.mk

ECHO 	= $(Q)echo
MKDIR	= $(Q)mkdir -p
RM	= $(Q)rm -f

RED 	= $(Q)tput setaf 1
GREEN 	= $(Q)tput setaf 2
NORMAL 	= $(Q)tput sgr0
ifeq ($(V),1)
TRACE 	= @(tput setaf 1; echo ------ $@; tput sgr0)
else
TRACE	= @#
endif

