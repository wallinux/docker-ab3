# lttng.mk
LTTNG_TAGS		?= rcs 2.7 2.8 2.9
LTTNG_TAG		?= rcs
LTTNG_IMAGE		= lttng:$(LTTNG_TAG)
LTTNG_CONTAINER		= lttng_$(LTTNG_TAG)
LTTNG_HOSTIP		= $(shell /sbin/ifconfig | grep 128.224 | cut -d: -f 2 | cut -d' ' -f 1)
################################################################

lttng.build: # Build lttng image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig lttng/
	$(DOCKER) build -f lttng/Dockerfile -t "lttng" .
	$(MKSTAMP)

lttng.build.% : lttng.build # Build lttng.$(LTTNG_TAG) image
	$(TRACE)
	$(DOCKER) build -f lttng/Dockerfile-$* -t "lttng:$*" .
	$(MKSTAMP)

lttng.prepare:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $(LTTNG_CONTAINER)
	$(DOCKER) exec -u root $(LTTNG_CONTAINER) \
		sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
	$(DOCKER) exec $(LTTNG_CONTAINER) \
		sh -c "if [ ! -e /root/.ssh/id_rsa ]; then ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''; fi"
	$(DOCKER) stop $(LTTNG_CONTAINER)

lttng.create: lttng.build.$(LTTNG_TAG) # Create a lttng container
	$(TRACE)
	$(DOCKER) create -P --name=$(LTTNG_CONTAINER) \
		-h lttng.eprime.com \
		--dns=8.8.8.8 \
		-p 5342:5342 \
		-p 5343:5343 \
		-p 5344:5344 \
		-i \
		$(LTTNG_IMAGE)
	$(MAKE) lttng.prepare
	$(MKSTAMP)

lttng.start: lttng.create # Start lttng container
	$(TRACE)
	$(DOCKER) start $(LTTNG_CONTAINER)

lttng.stop: # Stop lttng container
	$(TRACE)
	$(DOCKER) stop $(LTTNG_CONTAINER)

lttng.rm: # Remove lttng container
	$(TRACE)
	$(DOCKER) rm $(LTTNG_CONTAINER) || true
	$(call rmstamp,lttng.create)

lttng.RM: # Remove ALL lttng container
	$(foreach tag, $(LTTNG_TAGS), make -s lttng.rm LTTNG_TAG=$(tag); )

lttng.rmi: # Remove lttng image
	$(TRACE)
	$(DOCKER) rmi $(LTTNG_IMAGE)
	$(call rmstamp,lttng.build.$(LTTNG_TAG))

lttng.RMI: # Remove ALL lttng image
	$(foreach tag, $(LTTNG_TAGS), make -s lttng.rmi LTTNG_TAG=$(tag); )

lttng.shell: # Start a shell in lttng container
	$(TRACE)
	$(DOCKER) exec -it $(LTTNG_CONTAINER) sh -c "export HOSTIP=$(LTTNG_HOSTIP); /bin/bash"

lttng.run: # run test-live in lttng container
	$(TRACE)
	$(DOCKER) exec -it $(LTTNG_CONTAINER) sh -c "export HOSTIP=$(LTTNG_HOSTIP); /root/test-live"

lttng.update: # Update lttng in the container
	$(DOCKER) exec -it $(LTTNG_CONTAINER) sh -c "cd lttng-test; git pull; make repo.pull"

lttng.rebuild: # Rebuild lttng in the container
	$(DOCKER) exec -it $(LTTNG_CONTAINER) sh -c "cd lttng-test; make install"

lttng.tag:
	$(DOCKER) tag $(LTTNG_IMAGE) $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

lttng.push: lttng.tag # Push image to local registry
	$(DOCKER) push $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

lttng.pull: # Pull image from local registry
	$(DOCKER) pull $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

pull:: lttng.pull

lttng.distclean: lttng.RM lttng.RMI

lttng.help:
	$(TRACE)
	$(call run-help, lttng.mk)
	$(call run-note, "- Use the LTTNG_TAG(=$(LTTNG_TAG)) to define image/container")
	$(call run-note, "- Supported LTTNGS_TAGS are: $(LTTNG_TAGS)")

help:: lttng.help
