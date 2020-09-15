# codechecker.mk

CODECHECKER_PORT	?= 8001
CODECHECKER_MOUNT	?= /opt/codechecker
CODECHECKER_REL		?= latest
CODECHECKER_IMAGE	?= codechecker/codechecker-web:$(CODECHECKER_REL)
CODECHECKER_CONTAINER	?= codechecker

#######################################################################

.PHONY: codecchecker.*

$(CODECHECKER_MOUNT):
	$(TRACE)
	$(MKDIR) $@

codechecker.create: $(CODECHECKER_MOUNT) # create codechecker docker container
	$(TRACE)
	$(MKDIR) $(CODECHECKER_MOUNT)
	-$(DOCKER) create -P --name $(CODECHECKER_CONTAINER) \
		-v $(CODECHECKER_MOUNT):/workspace \
		-p $(CODECHECKER_PORT):8001 \
		-i $(CODECHECKER_IMAGE)
	$(MKSTAMP)

codechecker.start: codechecker.create # start codechecker docker container
	$(TRACE)
	$(DOCKER) start $(CODECHECKER_CONTAINER)

codechecker.stop: # stop codechecker docker container
	$(TRACE)
	-$(DOCKER) stop -t 2 $(CODECHECKER_CONTAINER)

codechecker.logs: # show codechecker container log
	$(TRACE)
	$(DOCKER) logs $(CODECHECKER_CONTAINER)

codechecker.rm: codechecker.stop # remove codechecker docker container
	$(TRACE)
	-$(DOCKER) rm $(CODECHECKER_CONTAINER)
	$(call rmstamp,codechecker.create)

codechecker.rmi: # remove codechecker docker image
	$(TRACE)
	$(DOCKER) rmi $(CODECHECKER_IMAGE)

codechecker.help:
	$(call run-help, codechecker.mk)

#######################################################################

help:: codechecker.help
