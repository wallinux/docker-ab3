# lttng.mk
LTTNG_IMAGE 	  	= lttng:2.9
LTTNG_CONTAINER   	= lttng_2.9

################################################################
lttng.build: # Build lttng container
	$(TRACE)
	$(DOCKER) build -t "lttng:2.9" lttng
	$(MKSTAMP)

lttng.prepare:
	$(TRACE)
	$(DOCKER) start $(LTTNG_CONTAINER)
	$(DOCKER) exec -u root $(LTTNG_CONTAINER) sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
	$(DOCKER) stop $(LTTNG_CONTAINER)

lttng.create: lttng.build # Create a lttng container
	$(TRACE)
	$(eval docker_bin=$(shell which docker))
	$(eval docker_gid=$(shell getent group docker | cut -d: -f3))
	$(eval users_gid=$(shell getent group users  | cut -d: -f3))
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) create -P --name=$(LTTNG_CONTAINER) \
		-v `pwd`/params:/etc/lttng-live \
		-v $(docker_bin):/usr/bin/docker \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-h lttng.eprime.com \
		--dns=128.224.92.11 \
		--dns-search=wrs.com \
		-p 5342:5342 \
		-p 5343:5343 \
		-p 5344:5344 \
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
	$(DOCKER) rm $(LTTNG_CONTAINER)
	$(call rmstamp,lttng.create)

lttng.rmi: # Remove lttng image
	$(TRACE)
	$(DOCKER) rm $(LTTNG_IMAGE)
	$(call rmstamp,lttng.build)

lttng.shell: # Start a shell in lttng container
	$(TRACE)
	$(DOCKER) exec -it $(LTTNG_CONTAINER) /bin/bash

lttng.tag:
	$(DOCKER) tag $(LTTNG_IMAGE) $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

lttng.push:
	$(DOCKER) push $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

lttng.pull:
	$(DOCKER) pull $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

pull:: lttng.pull

lttng.help:
	$(TRACE)
	$(call run-help, lttng.mk)

help:: lttng.help
