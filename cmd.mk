# cmd.mk

ECHO 	= $(Q)echo
RED 	= $(Q)tput setaf 1
GREEN 	= $(Q)tput setaf 2
NORMAL 	= $(Q)tput sgr0
TRACE 	= $(Q)tput setaf 1; echo ------ $@; tput sgr0

