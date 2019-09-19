# lvm2.mk

LVM2_DISTRO		?= ubuntu
LVM2_DISTRO_TAG		?= 18.10

LVM2_IMAGE		= lvm2
LVM2_TAG		= $(LVM2_DISTRO)-$(LVM2_DISTRO_TAG)
LVM2_CONTAINER		= $(LVM2_IMAGE)_$(LVM2_TAG)

################################################################

lvm2.build: # Build lvm2 image
	$(TRACE)
	$(DOCKER) build --pull -f lvm2/Dockerfile.$(LVM2_DISTRO)_$(LVM2_DISTRO_TAG) \
		-t "$(LVM2_IMAGE):$(LVM2_TAG)"  .
	$(MKSTAMP)

lvm2.create: lvm2.build # Create a lvm2 container
	$(TRACE)
	$(DOCKER) create -P --name=$(LVM2_CONTAINER) \
		-h lvm2.eprime.com \
		-v $(TOP):/root/host \
		--dns=$(DNS) \
		--privileged=true \
		-i \
		$(LVM2_IMAGE):$(LVM2_TAG)
	$(MKSTAMP)

lvm2.start: lvm2.create # Start lvm2 container
	$(TRACE)
	$(DOCKER) start $(LVM2_CONTAINER)

lvm2.shell: lvm2.start # Start a shell in lvm2 container
	$(TRACE)
	$(DOCKER) exec -it $(LVM2_CONTAINER) sh -c "/bin/bash"

lvm2.terminal: lvm2.start # Start a gnome-terminal for the lvm2 container
	$(TRACE)
	$(Q)unset GNOME_TERMINAL_SCREEN; gnome-terminal -- docker exec -it $(LVM2_CONTAINER) sh -c "/bin/bash" &

lvm2.test: lvm2.start # Run lvm tests
	$(TRACE)
	$(DOCKER) exec -it $(LVM2_CONTAINER) bash -c "/root/host/lvm2/lvmtest.all"

lvm2.stop: # Stop lvm2 container
	$(TRACE)
	$(DOCKER) stop -t 2 $(LVM2_CONTAINER) || true

lvm2.rm: lvm2.stop # Remove lvm2 container
	$(TRACE)
	$(DOCKER) rm $(LVM2_CONTAINER) || true
	$(call rmstamp,lvm2.create)

lvm2.rmi: # Remove lvm2 image
	$(TRACE)
	$(DOCKER) rmi $(LVM2_IMAGE):$(LVM2_TAG)
	$(call rmstamp,lvm2.build)

lvm2.help:
	$(TRACE)
	$(call run-help, lvm2.mk)

help:: lvm2.help

pull:: lvm2.pull
