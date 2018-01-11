# snmp.mk

SNMP_TAG		?= latest
SNMP_IMAGE		= snmp:$(SNMP_TAG)
SNMP_CONTAINER_0	= snmp_0
SNMP_CONTAINER_1	= snmp_1
SNMP_CONTAINERS		= $(SNMP_CONTAINER_0) $(SNMP_CONTAINER_1)
SNMP_NETWORK_0		= snmp_network_0
SNMP_NETWORK_1		= snmp_network_1
SNMP_NETWORKS		= $(SNMP_NETWORK_0) $(SNMP_NETWORK_1)
SNMP_GITROOT		= $(shell git rev-parse --show-toplevel)
################################################################

snmp.network.create: # Create docker networks
	$(DOCKER) network create --driver=bridge $(SNMP_NETWORK_0) --subnet=172.19.0.0/24
	$(DOCKER) network create --driver=bridge $(SNMP_NETWORK_1) --subnet=172.19.1.0/24
	$(MKSTAMP)

snmp.network.rm: # Remove docker networks
	$(Q)$(foreach network, $(SNMP_NETWORKS), docker network rm $(network); )
	$(call rmstamp,snmp.network.create)

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
	$(DOCKER) stop $*

snmp.create: snmp.build # Create a snmp containers
	$(TRACE)
	$(Q)$(foreach container, $(SNMP_CONTAINERS), make -s snmp.create.$(container); )
	$(MKSTAMP)

snmp.create.%: snmp.network.create
	$(TRACE)
	$(DOCKER) create -P --name=$* \
		-h snmp.eprime.com \
		--network=$(SNMP_NETWORK_0) \
		--dns=8.8.8.8 \
		-v $(SNMP_GITROOT):/root/snmp-test \
		--privileged=true \
		-i \
		$(SNMP_IMAGE)
	$(MAKE) snmp.prepare.$*

snmp.start: snmp.create # Start snmp containers
	$(TRACE)
	$(Q)$(foreach container, $(SNMP_CONTAINERS), make -s snmp.start.$(container); )

snmp.start.%:
	$(TRACE)
	$(DOCKER) network connect $(SNMP_NETWORK_1) $*
	$(DOCKER) start $*

snmp.stop: # Stop snmp containers
	$(TRACE)
	$(Q)$(foreach container, $(SNMP_CONTAINERS), make -s snmp.stop.$(container); )

snmp.stop.%: # Stop snmp container
	$(TRACE)
	$(DOCKER) stop $*

snmp.rm: # Remove snmp container
	$(TRACE)
	$(DOCKER) rm $(SNMP_CONTAINERS) || true
	$(call rmstamp,snmp.create)

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
	$(MAKE) snmp.build_net_snmp.AW_latest
	$(MAKE) snmp.build_net_snmp.AW_v5.7.3

snmp.build_net_snmp.%: # Build and install net-snmp in the snmp container
	$(TRACE)
	$(DOCKER) exec -it $(SNMP_CONTAINER_0) sh -c "cd net-snmp; git co -b $* wayline/$*" || true
	$(DOCKER) exec -it $(SNMP_CONTAINER_0) sh -c "./build"
	$(MAKE) snmp.commit.$(SNMP_CONTAINER_0) SNMP_TAG=$*

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

# NOTES
# Docker ipv6
# Add to /etc/docker/daemon.json
#
#{
#  "ipv6": true,
#  "fixed-cidr-v6": "2001:db8:1::/64"
#}
