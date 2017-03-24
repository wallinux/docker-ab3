# registry.mk
REGISTRY_IMAGE		= registry
REGISTRY_CONTAINER	= registry
REGISTRY_PORT		= 5000
REGISTRY_SERVER		= localhost:$(REGISTRY_PORT)

################################################################
registry.create: # Create a local registry container
	$(TRACE)
	$(DOCKER) create -P -p $(REGISTRY_PORT):$(REGISTRY_PORT) --restart=always --name $(REGISTRY_CONTAINER) $(REGISTRY_IMAGE)
	$(MKSTAMP)

registry.start: registry.create # Start local registry container
	$(TRACE)
	$(DOCKER) start $(REGISTRY_CONTAINER)

registry.stop: # Stop local registry container
	$(TRACE)
	$(DOCKER) stop $(REGISTRY_CONTAINER)

registry.rm: # Remove a local registry container
	$(TRACE)
	$(DOCKER) rm $(REGISTRY_CONTAINER)
	$(call rmstamp,registry.create)

registry.rmi: # Remove a registry image
	$(TRACE)
	$(DOCKER) rmi $(REGISTRY_CONTAINER)

registry.pull: # Update registry image
	$(TRACE)
	$(DOCKER) pull $(REGISTRY_CONTAINER)

registry.list: # List images in registry
	$(TRACE)
	$(Q)$(TOP)/bin/registry-images "http://$(REGISTRY_SERVER)"

registry.help:
	$(TRACE)
	$(call run-help, registry.mk)
	$(call run-note, "REGISTRY_SERVER = $(REGISTRY_SERVER)")

help:: registry.help

pull:: registry.pull
