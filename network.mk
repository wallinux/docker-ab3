DOCKER_NETWORK_1 = snmp_network_1
DOCKER_NETWORK_2 = snmp_network_2
DOCKER_NETWORK	 ?= $(DOCKER_NETWORK_1)
DOCKER_NETWORKS	 = $(DOCKER_NETWORK_1) $(DOCKER_NETWORK_2)

################################################################

network.create: # Create docker networks
	$(DOCKER) network create --ipv6 --driver=bridge $(DOCKER_NETWORK_1) --subnet=172.19.0.0/24 --subnet=2001:db8:2::/64
	$(DOCKER) network create --ipv6 --driver=bridge $(DOCKER_NETWORK_2) --subnet=172.19.1.0/24 --subnet=2001:db8:3::/64
	$(MKSTAMP)

network.rm: # Remove docker networks
	$(Q)$(foreach network, $(DOCKER_NETWORKS), docker network rm $(network) || true; )
	$(call rmstamp,network.create)

network.connect.%: # Connect network to container=%
	$(TRACE)
	$(DOCKER) network connect $(DOCKER_NETWORK) $*

network.disconnect.%: # Disconnect network to container=%
	$(TRACE)
	$(DOCKER) network disconnect $(DOCKER_NETWORK) $*
