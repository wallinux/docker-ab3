# wrlinux.mk

WRLINUX_DISTRO		?= ubuntu
WRLINUX_DISTRO_TAG	?= 16.04

WRLINUX_IMAGE		= wrlinux_800
WRLINUX_TAG		= $(WRLINUX_DISTRO)-$(WRLINUX_DISTRO_TAG)
WRLINUX_CONTAINER	= $(WRLINUX_IMAGE)_$(WRLINUX_TAG)

WIND_INSTALL_BASE 	?= /opt/projects/ericsson/installs
WIND_LX_HOME		= $(WIND_INSTALL_BASE)/$(WRLINUX_IMAGE)
WRLINUX_PKG_INSTALL	?= $(WIND_LX_HOME)/wrlinux-8/scripts/host_package_install.sh

################################################################

wrlinux.build.%: # Build wrlinux image
	$(TRACE)
	$(Q)cp $(WRLINUX_PKG_INSTALL) $(TOP)/wrlinux/$(WRLINUX_IMAGE)-pkg_install.sh
	$(Q)sed -i 's/sudo //' $(TOP)/wrlinux/$(WRLINUX_IMAGE)-pkg_install.sh
	$(DOCKER) build --pull --no-cache -f wrlinux/Dockerfile.$(WRLINUX_IMAGE) \
		-t "$(WRLINUX_IMAGE):$*" \
		--build-arg IMAGENAME=$(WRLINUX_DISTRO):$(WRLINUX_DISTRO_TAG) .
	$(MKSTAMP)

wrlinux.build: wrlinux.build.$(WRLINUX_TAG)
	$(TRACE)

wrlinux.create: wrlinux.build.$(WRLINUX_TAG) # Create a wrlinux container
	$(TRACE)
	$(DOCKER) create -P --name=$(WRLINUX_CONTAINER) \
		-v $(WIND_LX_HOME):$(WIND_LX_HOME):ro \
		-h wrlinux.eprime.com \
		--dns=$(DNS) \
		-i \
		$(WRLINUX_IMAGE):$(WRLINUX_TAG)
	$(MKSTAMP)

wrlinux.start: wrlinux.create # Start wrlinux container
	$(TRACE)
	$(DOCKER) start $(WRLINUX_CONTAINER)

wrlinux.shell: # Start a shell in wrlinux container
	$(TRACE)
	$(DOCKER) exec -it $(WRLINUX_CONTAINER) sh -c "/bin/sh"

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
	$(DOCKER) pull $(REGISTRY_SERVER)/$(WRLINUX_IMAGE):$(WRLINUX_TAG)

wrlinux.help:
	$(TRACE)
	$(call run-help, wrlinux.mk)

help:: wrlinux.help

pull:: wrlinux.pull
