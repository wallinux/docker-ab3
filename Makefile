default: help

include common.mk

#DNS		?= $(shell nslookup google.com | grep Server | cut -f3)
DNS		?= 8.8.8.8
DOCKER_ID_USER	?= wallinux

################################################################

#include registry.mk
include network.mk
include lttng.mk
include snmp.mk
#include gitea.mk
#include gitlab.mk
#include wrlinux_builder.mk
include wrlinux.mk
include jenkins.mk
#include u-boot.mk
#include openldap.mk
include lvm2.mk
include ubuntu.mk

pull:: # Update all images
	$(TRACE)

docker.rm: # Remove all dangling containers
	$(TRACE)
	$(DOCKER) ps -qa --filter "status=exited" | xargs docker rm

docker.rmi: # Remove all dangling images
	$(TRACE)
	$(DOCKER) images -q -f dangling=true | xargs docker rmi

clean:
	$(RM) -r $(STAMPSDIR)

docker.help:
	$(call run-help, Makefile)

help:: docker.help # Show available rules and info about them
	$(TRACE)
