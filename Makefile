# arn-build3 docker

default: help

include common.mk

################################################################

include registry.mk
include lttng.mk
include snmp.mk
include gitea.mk
include gitlab.mk
include wrlinux_builder.mk
include wrlinux.mk
include jenkins.mk

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
