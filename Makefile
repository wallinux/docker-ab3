default: help

include common.mk

DNS		?= 8.8.8.8
DOCKER_ID_USER	?= wallinux

################################################################

#include registry.mk
include network.mk
include lttng.mk
include snmp.mk
#include gitea.mk
#include gitlab.mk
#include jenkins.mk see rcs-admin
#include u-boot.mk
#include openldap.mk
include lvm2.mk
include ubuntu.mk
include cc_server.mk

include docker.mk
include codechecker.mk


################################################################
docker.RM: # Remove all dangling containers
	$(TRACE)
	$(DOCKER) ps -qa --filter "status=exited" | xargs docker rm

docker.RMI: # Remove all dangling images
	$(TRACE)
	$(DOCKER) images -q -f dangling=true | xargs docker rmi

################################################################

pull:: # Update all images
	$(TRACE)

clean::
	$(RM) -r $(STAMPSDIR)

help:: # Show available rules and info about them
	$(TRACE)
	$(call run-help, Makefile)
