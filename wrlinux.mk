# wrlinux.mk

WRLINUX_REMOTE_IMAGE	+= saxofon/wrlinux_builder
WRLINUX_IMAGE		+= wrlinux_builder
WRLINUX_TAG		?= 8-Ubuntu16.04
WRLINUX_CONTAINER	= $(WRLINUX_IMAGE)_$(WRLINUX_TAG)

################################################################

wrlinux.build.%: # Build wrlinux image
	$(TRACE)
	$(DOCKER) build -f wrlinux/Dockerfile -t "$(WRLINUX_IMAGE):$*" .
	$(MKSTAMP)

wrlinux.create: wrlinux.build.$(WRLINUX_TAG) # Create a wrlinux container
	$(TRACE)
	$(DOCKER) create -P --name=$(WRLINUX_CONTAINER) \
		-h wrlinux.eprime.com \
		--dns=8.8.8.8 \
		-i \
		$(WRLINUX_IMAGE):$(WRLINUX_TAG)
	$(MKSTAMP)

wrlinux.start: wrlinux.create # Start wrlinux container
	$(TRACE)
	$(DOCKER) start $(WRLINUX_CONTAINER)

wrlinux.shell: # Start a shell in wrlinux container
	$(TRACE)
	$(DOCKER) exec -it $(WRLINUX_CONTAINER) sh -c "/bin/bash"

wrlinux.stop: # Stop wrlinux container
	$(TRACE)
	$(DOCKER) stop $(WRLINUX_CONTAINER)

wrlinux.rm: # Remove wrlinux container
	$(TRACE)
	$(DOCKER) rm $(WRLINUX_CONTAINER) || true
	$(call rmstamp,wrlinux.create)

wrlinux.rmi: # Remove wrlinux image
	$(TRACE)
	$(DOCKER) rmi $(WRLINUX_IMAGE):$(WRLINUX_TAG)
	$(call rmstamp,wrlinux.build.$(WRLINUX_TAG))

wrlinux.tag:
	$(DOCKER) tag $(WRLINUX_IMAGE):$(WRLINUX_TAG) $(REGISTRY_SERVER)/$(WRLINUX_IMAGE):$(WRLINUX_TAG)

wrlinux.push: wrlinux.tag # Push wrlinux image to local registry
	$(DOCKER) push $(REGISTRY_SERVER)/$(WRLINUX_IMAGE):$(WRLINUX_TAG)

wrlinux.pull: # Update all wrlinux images
	$(TRACE)
	$(DOCKER) pull -a $(WRLINUX_REMOTE_IMAGE)
	$(DOCKER) pull $(REGISTRY_SERVER)/$(WRLINUX_IMAGE):$(WRLINUX_TAG)

wrlinux.help:
	$(TRACE)
	$(call run-help, wrlinux.mk)

help:: wrlinux.help
	$(TRACE)
	$(call run-help, wrlinux.mk)

pull:: wrlinux.pull
