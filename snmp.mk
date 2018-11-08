# snmp.mk

DISTRO			?= ubuntu
DISTRO_TAG		?= 16.04
DISTRO_TAGS		?= 16.04 18.04
export DISTRO_NAME	= $(DISTRO)_$(DISTRO_TAG)

SNMP_REGISTRY_SERVER	= $(DOCKER_ID_USER)

SNMP_TAG		?= AW_master
SNMP_TAGS_16.04		= AW_master WR8_prime
SNMP_TAGS_18.04		= AW_master
SNMP_TAGS_18.10		= AW_master
SNMP_TAGS		= $(SNMP_TAGS_$(DISTRO_TAG))

SNMP_REMOTE_IMAGE	?= $(SNMP_REGISTRY_SERVER)/snmp_$(DISTRO_NAME):$(SNMP_TAG)
SNMP_IMAGE		?= snmp_$(DISTRO_NAME):$(SNMP_TAG)
SNMP_CONTAINER_0	= snmp_$(DISTRO_NAME)_0_$(SNMP_TAG)
SNMP_CONTAINER_1	= snmp_$(DISTRO_NAME)_1_$(SNMP_TAG)
SNMP_CONTAINER		?= $(SNMP_CONTAINER_0)
SNMP_CONTAINERS		= $(SNMP_CONTAINER_0) $(SNMP_CONTAINER_1)
SNMP_GITROOT		= $(shell git rev-parse --show-toplevel)
################################################################

snmp.all: snmp.BUILD # Build all snmp images

snmp.ALL: # Build all images for all supported distributions
	$(Q)$(foreach distro_tag,$(DISTRO_TAGS),make -s V=$(V) snmp.BUILD DISTRO_TAG=$(distro_tag); )

snmp.build.latest: # Build snmp base image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig snmp/
	$(Q)sed -i '/signingkey/d' snmp/.gitconfig
	$(Q)sed -i '/gpg/d' snmp/.gitconfig
	$(CP) $(HOME)/.tmux.conf snmp/
	$(DOCKER) build --pull -f snmp/Dockerfile.$(DISTRO_NAME) -t "snmp_$(DISTRO_NAME)" .
	$(MAKE) snmp.tag SNMP_IMAGE=snmp_$(DISTRO_NAME):latest

snmp.build.$(DISTRO_NAME).latest:
	$(TRACE)
	$(MAKE) snmp.build.latest DISTRO_NAME=$(DISTRO_NAME)
	$(MKSTAMP)

snmp.build.%: snmp.build.$(DISTRO_NAME).latest
	$(TRACE)
	$(eval dockerfile=snmp/Dockerfile.$*)
	$(ECHO) "FROM snmp_$(DISTRO_NAME):latest" > $(dockerfile)
	$(ECHO) "MAINTAINER Anders Wallin" >> $(dockerfile)
	$(ECHO) "RUN (cd net-snmp; git fetch --all; git checkout -b $* wayline/$*)" >> $(dockerfile)
	$(ECHO) 'RUN [ "/bin/bash", "-c", "/root/build &> /root/build.out" ]' >> $(dockerfile)
	$(DOCKER) build -q -f $(dockerfile) -t "snmp_$(DISTRO_NAME):$*" .
	$(RM) $(dockerfile)
	$(MAKE) snmp.tag SNMP_IMAGE=snmp_$(DISTRO_NAME):$*

snmp.build.$(DISTRO_NAME).%:
	$(MAKE) snmp.build.$* DISTRO_NAME=$(DISTRO_NAME)
	$(MKSTAMP)

snmp.build: # Build snmp image for SNMP_TAG
	$(MAKE) snmp.build.$(DISTRO_NAME).$(SNMP_TAG)

snmp.BUILD: # Build net-snmp for ALL images
	$(Q)$(foreach tag,$(SNMP_TAGS), make -s V=$(V) snmp.build.$(tag); )

snmp.update.%:
	$(eval dockerfile=snmp/Dockerfile.$*)
	$(MAKE) snmp.build.$(DISTRO_NAME).$*
	$(ECHO) "FROM snmp_$(DISTRO_NAME):$*" > $(dockerfile)
	$(ECHO) "MAINTAINER Anders Wallin" >> $(dockerfile)
	$(ECHO) "RUN (cd net-snmp; git pull; make install > make_install.out)" >> $(dockerfile)
	$(DOCKER) build -f $(dockerfile) -t "snmp_$(DISTRO_NAME):$*" .
	$(RM) $(dockerfile)
	$(MAKE) snmp.tag SNMP_IMAGE=snmp_$(DISTRO_NAME):$*

snmp.update: # Update snmp image for SNMP_TAG
	$(MAKE) snmp.update.$(SNMP_TAG)

snmp.UPDATE: # Update net-snmp for ALL images
	$(Q)$(foreach tag,$(SNMP_TAGS),make snmp.update.$(tag); )

snmp.prepare.%:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $*
	$(DOCKER) exec -u root $* \
		sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
	$(DOCKER) exec $* \
		sh -c "if [ ! -e /root/.ssh/id_rsa ]; then ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''; fi"

snmp.create.%: network.create
	$(TRACE)
	$(DOCKER) create -P --name=$* \
		-h $*.eprime.com \
		--network=$(DOCKER_NETWORK_1) \
		--dns=8.8.8.8 \
		-v $(SNMP_GITROOT):/root/snmp-test \
		--privileged=true \
		-i \
		$(SNMP_REMOTE_IMAGE)
	$(MAKE) snmp.prepare.$*
	$(MKSTAMP)

snmp.create: # Create a snmp containers
	$(TRACE)
	$(Q)$(foreach container,$(SNMP_CONTAINERS),make -s snmp.create.$(container); )

snmp.start.%:
	$(TRACE)
	$(MAKE) network.connect.$* DOCKER_NETWORK=$(DOCKER_NETWORK_2)
	$(DOCKER) start $*
	$(DOCKER) exec -it $* sh -c "/etc/init.d/ssh start"
	$(MKSTAMP)

snmp.start: snmp.create # Start snmp containers
	$(TRACE)
	$(Q)$(foreach container,$(SNMP_CONTAINERS),make -s snmp.start.$(container); )

snmp.START:  # Start ALL snmp containers
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.start SNMP_TAG=$(tag); )

snmp.stop.%:
	$(TRACE)
	$(DOCKER) stop $* || true
	$(call rmstamp,snmp.start.$*)

snmp.stop: # Stop snmp containers
	$(TRACE)
	$(Q)$(foreach container,$(SNMP_CONTAINERS), make -s snmp.stop.$(container); )

snmp.STOP: # Stop ALL snmp containers
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.stop SNMP_TAG=$(tag); )

snmp.rm.%:
	$(TRACE)
	$(DOCKER) rm $* || true
	$(call rmstamp,snmp.create.$*)

snmp.rm: # Remove snmp container
	$(TRACE)
	$(Q)$(foreach container,$(SNMP_CONTAINERS), make -s snmp.rm.$(container); )

snmp.RM: snmp.STOP # Remove ALL snmp containers
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.rm SNMP_TAG=$(tag); )

snmp.rmi: # Remove snmp image
	$(TRACE)
	$(DOCKER) rmi $(SNMP_IMAGE) || true
	$(call rmstamp,snmp.build.$(DISTRO_NAME).$(SNMP_TAG))

snmp.RMI: # Remove ALL snmp images
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.rmi SNMP_TAG=$(tag); )
	$(MAKE) snmp.rmi SNMP_TAG=$(DISTRO_NAME).latest

snmp.remote.rmi: snmp.rm # Remove downloaded snmp image
	$(TRACE)
	$(DOCKER) rmi $(SNMP_REMOTE_IMAGE) || true

snmp.remote.RMI: # Remove ALL remote snmp images
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.remote.rmi SNMP_TAG=$(tag); )
	$(MAKE) snmp.rmi SNMP_TAG=$(DISTRO_NAME).latest

snmp.shell.%:
	$(TRACE)
	$(DOCKER) exec -it $* sh -c "/bin/bash"

snmp.shell: # Start a shell in snmp container
	$(TRACE)
	$(MAKE) snmp.shell.$(SNMP_CONTAINER_0)

snmp.terminal: snmp.start # Start a gnome-terminal in snmp container
	$(TRACE)
	$(MAKE) snmp.terminal.$(SNMP_CONTAINER_0)

snmp.terminal.%:
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $* sh -c \"/bin/bash\"" &

snmp.tag:
	$(DOCKER) tag $(SNMP_IMAGE) $(SNMP_REMOTE_IMAGE)

snmp.push: snmp.tag # Push image to registry
	$(TRACE)
	$(DOCKER) push $(SNMP_REMOTE_IMAGE)

snmp.PUSH: # Push ALL snmp images to registry
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.push SNMP_TAG=$(tag); )

snmp.pull: # Pull image from registry
	$(DOCKER) pull $(SNMP_REMOTE_IMAGE)

snmp.PULL: # Pull ALL snmp images from registry
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.pull SNMP_TAG=$(tag); )

pull:: snmp.PULL

snmp.distclean: snmp.remote.RMI snmp.RMI network.rm

distclean:: snmp.distclean

snmp.help:
	$(TRACE)
	$(call run-help, snmp.mk)

help:: snmp.help
	$(GREEN)
	$(ECHO) -e "\nDISTRO_NAME=$(DISTRO_NAME)"
	$(ECHO) -e "Set SNMP_TAG(default=$(SNMP_TAG)) to run container, available SNMP_TAGS=<$(SNMP_TAGS)>"
	$(NORMAL)
