# u-boot.mk

U-BOOT_DISTRO		?= ubuntu
U-BOOT_DISTRO_TAG	?= 18.04

U-BOOT_IMAGE		= u-boot_800
U-BOOT_TAG		= $(U-BOOT_DISTRO)-$(U-BOOT_DISTRO_TAG)
U-BOOT_CONTAINER	= $(U-BOOT_IMAGE)_$(U-BOOT_TAG)
U-BOOT_DIR		= u-boot

################################################################

u-boot.build.%: # Build u-boot image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig $(U-BOOT_DIR)
	$(Q)sed -i '/signingkey/d' $(U-BOOT_DIR)/.gitconfig
	$(Q)sed -i '/gpg/d' $(U-BOOT_DIR)/.gitconfig
	$(CP) $(HOME)/.tmux.conf $(U-BOOT_DIR)
	$(DOCKER) build --pull -f $(U-BOOT_DIR)/Dockerfile \
		-t "$(U-BOOT_IMAGE):$*" \
		--build-arg IMAGENAME=$(U-BOOT_DISTRO):$(U-BOOT_DISTRO_TAG) .
	$(MKSTAMP)

u-boot.build: u-boot.build.$(U-BOOT_TAG)
	$(TRACE)

u-boot.create: u-boot.build.$(U-BOOT_TAG) # Create a u-boot container
	$(TRACE)
	$(DOCKER) create -P --name=$(U-BOOT_CONTAINER) \
		-h u-boot.eprime.com \
		--dns=$(DNS) \
		-i \
		$(U-BOOT_IMAGE):$(U-BOOT_TAG)
	$(MKSTAMP)

u-boot.start: u-boot.create # Start u-boot container
	$(TRACE)
	$(DOCKER) start $(U-BOOT_CONTAINER)

u-boot.shell: # Start a shell in u-boot container
	$(TRACE)
	$(DOCKER) exec -it $(U-BOOT_CONTAINER) sh -c "/bin/sh"

u-boot.terminal: u-boot.start
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $(U-BOOT_CONTAINER) sh -c \"/bin/bash\"" &

u-boot.stop: # Stop u-boot container
	$(TRACE)
	$(DOCKER) stop $(U-BOOT_CONTAINER)

u-boot.rm: # Remove u-boot container
	$(TRACE)
	$(DOCKER) rm $(U-BOOT_CONTAINER) || true
	$(call rmstamp,u-boot.create)

u-boot.rmi: # Remove u-boot image
	$(TRACE)
	$(DOCKER) rmi $(U-BOOT_IMAGE):$(U-BOOT_TAG)
	$(call rmstamp,u-boot.build.$(U-BOOT_TAG))

u-boot.help:
	$(TRACE)
	$(call run-help, u-boot.mk)

help:: u-boot.help
	$(TRACE)
	$(call run-help, u-boot.mk)

pull:: u-boot.pull
