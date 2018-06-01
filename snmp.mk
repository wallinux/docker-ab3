# snmp.mk

SNMP_REGISTRY_SERVER	= $(DOCKER_ID_USER)
SNMP_TAG		?= AW_master
SNMP_TAGS		= AW_master AW_v5-7 WR8 WR8_prime WR8_wip
SNMP_REMOTE_IMAGE	?= $(SNMP_REGISTRY_SERVER)/snmp:$(SNMP_TAG)
SNMP_IMAGE		?= snmp:$(SNMP_TAG)
SNMP_CONTAINER_0	= snmp_0_$(SNMP_TAG)
SNMP_CONTAINER_1	= snmp_1_$(SNMP_TAG)
SNMP_CONTAINER		?= $(SNMP_CONTAINER_0)
SNMP_CONTAINERS		= $(SNMP_CONTAINER_0) $(SNMP_CONTAINER_1)
SNMP_GITROOT		= $(shell git rev-parse --show-toplevel)
################################################################

snmp.all: snmp.build.ALL # Build ALL images

snmp.build.latest: # Build snmp base image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig snmp/
	$(Q)sed -i '/signingkey/d' snmp/.gitconfig
	$(Q)sed -i '/gpg/d' snmp/.gitconfig
	$(CP) $(HOME)/.tmux.conf snmp/
	$(DOCKER) build --pull -f snmp/Dockerfile -t "snmp" .
	$(MKSTAMP)

snmp.build.%: snmp.build.latest # Build snmp image for SNMP_TAG
	$(eval dockerfile=snmp/Dockerfile.$*)
	$(ECHO) "FROM snmp" > $(dockerfile)
	$(ECHO) "MAINTAINER Anders Wallin" >> $(dockerfile)
	$(ECHO) "RUN (cd net-snmp; git fetch --all; git checkout -b $* wayline/$*)" >> $(dockerfile)
	$(ECHO) 'RUN [ "/bin/bash", "-c", "/root/build &> /root/build.out" ]' >> $(dockerfile)
	$(DOCKER) build -f $(dockerfile) -t "snmp:$*" .
	$(RM) $(dockerfile)
	$(MAKE) snmp.tag SNMP_TAG=$*
	$(MKSTAMP)

snmp.build.ALL: # Build net-snmp for all images
	$(Q)$(foreach tag,$(SNMP_TAGS),make snmp.build.$(tag); )

snmp.update.%: # Update snmp image for SNMP_TAG
	$(eval dockerfile=snmp/Dockerfile.$*)
	$(MAKE) snmp.build.$*
	$(ECHO) "FROM snmp:$*" > $(dockerfile)
	$(ECHO) "MAINTAINER Anders Wallin" >> $(dockerfile)
	$(ECHO) "RUN (cd net-snmp; git pull; make install > make_install.out)" >> $(dockerfile)
	$(DOCKER) build -f $(dockerfile) -t "snmp:$*" .
	$(RM) $(dockerfile)
	$(MAKE) snmp.tag SNMP_TAG=$*

snmp.update.ALL: # Update net-snmp for all images
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
	$(call rmstamp,snmp.build)

snmp.RMI: # Remove ALL snmp images
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.rmi SNMP_TAG=$(tag); )
	$(MAKE) snmp.rmi SNMP_TAG=latest

snmp.remote.rmi: snmp.rm # Remove downloaded snmp image
	$(TRACE)
	$(DOCKER) rmi $(SNMP_REMOTE_IMAGE) || true

snmp.remote.RMI: # Remove ALL remote snmp images
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.remote.rmi SNMP_TAG=$(tag); )
	$(MAKE) snmp.rmi SNMP_TAG=latest

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
	$(ECHO) -e "\nSet SNMP_TAG(default=$(SNMP_TAG)) to run container, available SNMP_TAGS=<$(SNMP_TAGS)>"
	$(NORMAL)
