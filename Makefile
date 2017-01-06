# arn-build3 docker 

default: help

# Default settings
HOSTNAME 	?= $(shell hostname)
USER		?= $(shell whoami)

# Don't inherit path from environment any extra PATH:s needs to go into one of the *config-*.mk
export PATH	:= /bin:/usr/bin
export SHELL	:= /bin/bash

# Optional configuration
-include make/hostconfig-$(HOSTNAME).mk
-include make/userconfig-$(USER).mk
-include make/userconfig-$(HOSTNAME)-$(USER).mk

TOP	:= $(shell pwd)

# Define V=1 to echo everything
ifneq ($(V),1)
Q=@
endif

vpath % .stamps
MKSTAMP = $(Q)mkdir -p .stamps ; touch .stamps/$@

DOCKER_IMAGES += jenkins
DOCKER_IMAGES += saxofon/wrlinux_builder

DOCKER_CONTAINERS += docker.jenkins
DOCKER_CONTAINERS += docker.wrlinux6
DOCKER_CONTAINERS += docker.wrlinux8

DOCKER_PATH =""

docker.pull:
	docker pull $(DOCKER_IMAGES)

docker.jenkins:
	$(ECHO) $@ TBD
	$(MKSTAMP)

docker.wrlinux6:
	$(ECHO) $@ TBD
	$(MKSTAMP)

docker.wrlinux8:
	$(ECHO) $@ TBD
	$(MKSTAMP)

docker.run: $(DOCKER_CONTAINERS)

docker.export:
	$(ECHO) $@ TBD
