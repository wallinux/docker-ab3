# snmp.mk

SNMP_TAG		?= latest
SNMP_IMAGE		= snmp:$(SNMP_TAG)
SNMP_CONTAINER_0	= snmp_0_$(SNMP_TAG)
SNMP_CONTAINER_1	= snmp_1_$(SNMP_TAG)
SNMP_CONTAINER		?= $(SNMP_CONTAINER)
SNMP_CONTAINERS		= $(SNMP_CONTAINER_0) $(SNMP_CONTAINER_1)
SNMP_GITROOT		= $(shell git rev-parse --show-toplevel)
################################################################

snmp.build: # Build snmp image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig snmp/
	$(CP) $(HOME)/.tmux.conf snmp/
	$(DOCKER) build --pull -f snmp/Dockerfile -t "snmp" .
	$(MKSTAMP)

snmp.prepare.%:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $*
	$(DOCKER) exec -u root $* \
		sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
	$(DOCKER) exec $* \
		sh -c "if [ ! -e /root/.ssh/id_rsa ]; then ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''; fi"

snmp.create: snmp.build # Create a snmp containers
	$(TRACE)
	$(Q)$(foreach container, $(SNMP_CONTAINERS), make -s snmp.create.$(container); )

snmp.create.%: network.create
	$(TRACE)
	$(DOCKER) create -P --name=$* \
		-h $*.eprime.com \
		--network=$(DOCKER_NETWORK_1) \
		--dns=8.8.8.8 \
		-v $(SNMP_GITROOT):/root/snmp-test \
		--privileged=true \
		-i \
		$(SNMP_IMAGE)
	$(MAKE) snmp.prepare.$*
	$(MKSTAMP)

snmp.start: snmp.create # Start snmp containers
	$(TRACE)
	$(Q)$(foreach container, $(SNMP_CONTAINERS), make -s snmp.start.$(container); )

snmp.start.%:
	$(TRACE)
	$(MAKE) network.connect.$* DOCKER_NETWORK=$(DOCKER_NETWORK_2)
	$(DOCKER) start $*
	$(DOCKER) exec -it $* sh -c "/etc/init.d/ssh start"
	$(MKSTAMP)

snmp.stop: # Stop snmp containers
	$(TRACE)
	$(Q)$(foreach container, $(SNMP_CONTAINERS), make -s snmp.stop.$(container); )

snmp.stop.%: # Stop snmp container
	$(TRACE)
	$(DOCKER) stop $*
	$(call rmstamp,snmp.start.$*)

snmp.rm: # Remove snmp container
	$(TRACE)
	$(Q)$(foreach container, $(SNMP_CONTAINERS), make -s snmp.rm.$(container); )

snmp.rm.%:
	$(TRACE)
	$(DOCKER) rm $* || true
	$(call rmstamp,snmp.create.$*)

snmp.rmi: # Remove snmp image
	$(TRACE)
	$(DOCKER) rmi $(SNMP_IMAGE)
	$(call rmstamp,snmp.build)

snmp.shell: # Start a shell in snmp container
	$(TRACE)
	$(MAKE) snmp.shell.$(SNMP_CONTAINER_0)

snmp.shell.%:
	$(TRACE)
	$(DOCKER) exec -it $* sh -c "/bin/bash"

snmp.terminal: # Start a gnome-terminal in snmp container
	$(TRACE)
	$(MAKE) snmp.terminal.$(SNMP_CONTAINER_0)

snmp.terminal.%:
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $* sh -c \"/bin/bash\"" &

snmp.build_net_snmp: # Build and install net-snmp in the snmp container
	$(MAKE) snmp.build_net_snmp.AW_latest SNMP_CONTAINER=$(SNMP_CONTAINER_0)
	$(MAKE) snmp.build_net_snmp.AW_v5.7.3 SNMP_CONTAINER=$(SNMP_CONTAINER_1)

snmp.build_net_snmp.%: # Build and install net-snmp in the snmp container
	$(TRACE)
	$(DOCKER) exec -it $(SNMP_CONTAINER) sh -c "cd net-snmp; git co -b $* wayline/$*" || true
	$(DOCKER) exec -it $(SNMP_CONTAINER) sh -c "./build"
	$(MAKE) snmp.commit.$(SNMP_CONTAINER) SNMP_TAG=$*
	$(MAKE) snmp.push SNMP_TAG=$*

snmp.commit.%:
	$(DOCKER) commit $* $(SNMP_IMAGE)

snmp.tag:
	$(DOCKER) tag $(SNMP_IMAGE) $(REGISTRY_SERVER)/$(SNMP_IMAGE)

snmp.push: snmp.tag # Push image to local registry
	$(DOCKER) push $(REGISTRY_SERVER)/$(SNMP_IMAGE)

snmp.pull: # Pull image from local registry
	$(DOCKER) pull $(REGISTRY_SERVER)/$(SNMP_IMAGE)

pull:: snmp.pull

snmp.distclean: snmp.rm snmp.rmi

snmp.help:
	$(TRACE)
	$(call run-help, snmp.mk)

help:: snmp.help
