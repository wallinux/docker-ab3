# wrlinux_builder.mk

WRLINUX_BUILDER_REMOTE_IMAGE	+= saxofon/wrlinux_builder
WRLINUX_BUILDER_IMAGE		+= wrlinux_builder
WRLINUX_BUILDER_TAG		?= 8-Ubuntu16.04
WRLINUX_BUILDER_CONTAINER	= $(WRLINUX_BUILDER_IMAGE)_$(WRLINUX_BUILDER_TAG)

################################################################

wrlinux_builder.build.%: # Build wrlinux_builder image
	$(TRACE)
	$(DOCKER) build -f wrlinux_builder/Dockerfile -t "$(WRLINUX_BUILDER_IMAGE):$*" .
	$(MKSTAMP)

wrlinux_builder.build: wrlinux_builder.build.$(WRLINUX_BUILDER_TAG)
	$(TRACE)

wrlinux_builder.create: wrlinux_builder.build.$(WRLINUX_BUILDER_TAG) # Create a wrlinux_builder container
	$(TRACE)
	$(DOCKER) create -P --name=$(WRLINUX_BUILDER_CONTAINER) \
		-h wrlinux_builder.eprime.com \
		--dns=8.8.8.8 \
		-i \
		$(WRLINUX_BUILDER_IMAGE):$(WRLINUX_BUILDER_TAG)
	$(MKSTAMP)

wrlinux_builder.start: wrlinux_builder.create # Start wrlinux_builder container
	$(TRACE)
	$(DOCKER) start $(WRLINUX_BUILDER_CONTAINER)

wrlinux_builder.shell: # Start a shell in wrlinux_builder container
	$(TRACE)
	$(DOCKER) exec -it $(WRLINUX_BUILDER_CONTAINER) sh -c "/bin/bash"

wrlinux_builder.stop: # Stop wrlinux_builder container
	$(TRACE)
	$(DOCKER) stop $(WRLINUX_BUILDER_CONTAINER)

wrlinux_builder.rm: # Remove wrlinux_builder container
	$(TRACE)
	$(DOCKER) rm $(WRLINUX_BUILDER_CONTAINER) || true
	$(call rmstamp,wrlinux_builder.create)

wrlinux_builder.rmi: # Remove wrlinux_builder image
	$(TRACE)
	$(DOCKER) rmi $(WRLINUX_BUILDER_IMAGE):$(WRLINUX_BUILDER_TAG)
	$(call rmstamp,wrlinux_builder.build.$(WRLINUX_BUILDER_TAG))

wrlinux_builder.tag:
	$(DOCKER) tag $(WRLINUX_BUILDER_IMAGE):$(WRLINUX_BUILDER_TAG) $(REGISTRY_SERVER)/$(WRLINUX_BUILDER_IMAGE):$(WRLINUX_BUILDER_TAG)

wrlinux_builder.push: wrlinux_builder.tag # Push wrlinux_builder image to local registry
	$(DOCKER) push $(REGISTRY_SERVER)/$(WRLINUX_BUILDER_IMAGE):$(WRLINUX_BUILDER_TAG)

wrlinux_builder.pull: # Update all wrlinux_builder images
	$(TRACE)
	$(DOCKER) pull -a $(WRLINUX_BUILDER_REMOTE_IMAGE)
	$(DOCKER) pull $(REGISTRY_SERVER)/$(WRLINUX_BUILDER_IMAGE):$(WRLINUX_BUILDER_TAG)

wrlinux_builder.help:
	$(TRACE)
	$(call run-help, wrlinux_builder.mk)

help:: wrlinux_builder.help
	$(TRACE)
	$(call run-help, wrlinux_builder.mk)

pull:: wrlinux_builder.pull
