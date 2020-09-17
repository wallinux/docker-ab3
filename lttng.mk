# lttng.mk
LTTNG_DISTRO		?= ubuntu-20.04
LTTNG_TAGS		?= rcs stable-2.10 stable-2.11
LTTNG_TAG		?= rcs
LTTNG_IMAGE		= lttng:$(LTTNG_TAG)
LTTNG_CONTAINER		= lttng_$(LTTNG_TAG)
#LTTNG_HOSTIP		= $(shell /sbin/ifconfig | grep 128.224 | cut -d: -f 2 | cut -d' ' -f 1)
LTTNG_HOSTIP		?= $(shell /sbin/ifconfig docker0 | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
LTTNG_HOSTNAME          ?= lttng-$(subst .,_,$(LTTNG_TAG)).eprime.com
##LTTNG_PORTS		?= -p 5342:5342 -p 5343:5343 -p 5344:5344

define run-docker-exec
	$(DOCKER) exec -e HOSTIP=$(LTTNG_HOSTIP) -u root $(1) $(LTTNG_CONTAINER) $(2)
endef

.PHONY:: lttng.*

################################################################
lttng.ALL: lttng.CREATE

lttng.CREATE: # Create ALL lttng container
	$(foreach tag,$(LTTNG_TAGS), make -s lttng.create LTTNG_TAG=$(tag); )

lttng.RM: # Remove ALL lttng container
	$(foreach tag, $(LTTNG_TAGS), make -s lttng.rm LTTNG_TAG=$(tag); )

lttng.RMI: # Remove ALL lttng images
	-$(foreach tag, $(LTTNG_TAGS), make -s lttng.rmi LTTNG_TAG=$(tag); )
	-$(DOCKER) rmi lttng
	$(call rmstamp,lttng.build)

lttng.PUSH: # Remove ALL lttng container
	$(foreach tag, $(LTTNG_TAGS), make -s lttng.push LTTNG_TAG=$(tag); )

lttng.PULL: # Remove ALL lttng container
	$(foreach tag, $(LTTNG_TAGS), make -s lttng.pull LTTNG_TAG=$(tag); )

################################################################
lttng.build: # Build lttng image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig lttng/
	$(DOCKER) build --pull -f lttng/Dockerfile.$(LTTNG_DISTRO) -t "lttng" .
	$(MKSTAMP)

lttng.build.% : lttng.build
	$(TRACE)
	$(DOCKER) build -f lttng/Dockerfile-lttng --build-arg LTTNG_TAG=$* -t "lttng:$*" .
	$(MKSTAMP)

lttng.prepare:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $(LTTNG_CONTAINER)
	$(call run-docker-exec, , sh -c "echo $(host_timezone) > /etc/timezone" )
	$(call run-docker-exec, , ln -sfn /usr/share/zoneinfo/$(host_timezone) /etc/localtime )
	$(call run-docker-exec, , dpkg-reconfigure -f noninteractive tzdata 2> /dev/null)
	$(call run-docker-exec, -t, sh -c "if [ ! -e /root/.ssh/id_rsa ]; then ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''; fi" )
	$(DOCKER) stop -t 2 $(LTTNG_CONTAINER)

lttng.create.%: lttng.build.$(LTTNG_TAG)
	$(TRACE)
	$(DOCKER) create -P --name=$(LTTNG_CONTAINER) \
		-h $(LTTNG_HOSTNAME) \
		--dns=$(DNS) \
		$(LTTNG_PORTS) \
		--privileged \
		-i $(LTTNG_IMAGE)
	$(MAKE) lttng.prepare
	$(MKSTAMP)

lttng.create: lttng.create.$(LTTNG_TAG) # Create lttng container
	$(TRACE)

lttng.hostip:
	$(TRACE)
	$(ECHO) "export HOSTIP=$(LTTNG_HOSTIP)" > lttng/.bash_aliases
	$(DOCKER) cp lttng/.bash_aliases $(LTTNG_CONTAINER):/root/.bash_aliases

lttng.start: lttng.create # Start lttng container
	$(TRACE)
	$(DOCKER) start $(LTTNG_CONTAINER)
	$(MAKE) lttng.hostip

lttng.stop: # Stop lttng container
	$(TRACE)
	-$(DOCKER) stop -t 2 $(LTTNG_CONTAINER)

lttng.rm: lttng.stop # Remove lttng container
	$(TRACE)
	-$(DOCKER) rm $(LTTNG_CONTAINER)
	$(call rmstamp,lttng.create.$(LTTNG_TAG))

lttng.rmi: # Remove lttng image
	$(TRACE)
	-$(DOCKER) rmi $(LTTNG_IMAGE)
	$(call rmstamp,lttng.build.$(LTTNG_TAG))

lttng.shell: lttng.start # Start a shell in lttng container
	$(TRACE)
	$(call run-docker-exec, -it, "/bin/bash")

lttng.terminal: lttng.start # Start a gnome-terminal in lttng container
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $(LTTNG_CONTAINER) bash -c \"/bin/bash\"" &

lttng.test: lttng.start # run tests in lttng container
	$(TRACE)
	$(call run-docker-exec, -it, sh -c "make -C lttng-test test.lttng_tools")

lttng.run: lttng.start # run targettest in lttng container
	$(TRACE)
	$(call run-docker-exec, -it, bash -c "/root/lttng-test/test/test-live/targettest amarillo1")

lttng.update: lttng.start # Update lttng in the container
	$(TRACE)
	$(call run-docker-exec, -it, bash -c "cd lttng-test; git pull; make repo.pull")

lttng.rebuild: lttng.start # Rebuild lttng in the container
	$(TRACE)
	$(call run-docker-exec, -it, bash -c "make -C lttng-test install")

lttng.tag:
	$(DOCKER) tag $(LTTNG_IMAGE) $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

lttng.push: lttng.tag # Push image to local registry
	$(DOCKER) push $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

lttng.pull: # Pull image from local registry
	$(DOCKER) pull $(REGISTRY_SERVER)/$(LTTNG_IMAGE)

lttng.distclean: lttng.RM lttng.RMI

lttng.help:
	$(TRACE)
	$(call run-help, lttng.mk)
	$(call run-note, "- Use the LTTNG_TAG(=$(LTTNG_TAG)) to define image/container")
	$(call run-note, "- Supported LTTNGS_TAGS are: $(LTTNG_TAGS)")
	$(call run-note, "- LTTNG_HOSTIP = $(LTTNG_HOSTIP)")

################################################################

pull:: lttng.pull

help:: lttng.help

include lttng.cc.mk
