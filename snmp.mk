# snmp.mk

SNMP_TAG		?= latest
SNMP_IMAGE		= snmp:$(SNMP_TAG)
SNMP_CONTAINER		= snmp_$(SNMP_TAG)
SNMP_GITROOT		= $(shell git rev-parse --show-toplevel)
################################################################

snmp.build: # Build snmp image
	$(TRACE)
	$(CP) $(HOME)/.gitconfig snmp/
	$(DOCKER) build --pull -f snmp/Dockerfile -t "snmp" .
	$(MKSTAMP)

snmp.prepare:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $(SNMP_CONTAINER)
	$(DOCKER) exec -u root $(SNMP_CONTAINER) \
		sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
	$(DOCKER) exec $(SNMP_CONTAINER) \
		sh -c "if [ ! -e /root/.ssh/id_rsa ]; then ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''; fi"

snmp.create: snmp.build # Create a snmp container
	$(TRACE)
	$(MAKE) snmp.create.$(SNMP_TAG) 

snmp.create.%:
	$(TRACE)
	$(DOCKER) create -P --name=$(SNMP_CONTAINER) \
		-h snmp.eprime.com \
		--dns=8.8.8.8 \
		-v $(SNMP_GITROOT):/root/snmp-test \
		-i \
		$(SNMP_IMAGE)
	$(MAKE) snmp.prepare
	$(MKSTAMP)

snmp.start: snmp.create # Start snmp container
	$(TRACE)
	$(DOCKER) start $(SNMP_CONTAINER)

snmp.stop: # Stop snmp container
	$(TRACE)
	$(DOCKER) stop $(SNMP_CONTAINER)

snmp.rm: # Remove snmp container
	$(TRACE)
	$(DOCKER) rm $(SNMP_CONTAINER) || true
	$(call rmstamp,snmp.create.$(SNMP_TAG))

snmp.rmi: # Remove snmp image
	$(TRACE)
	$(DOCKER) rmi $(SNMP_IMAGE)
	$(call rmstamp,snmp.build)

snmp.shell: # Start a shell in snmp container
	$(TRACE)
	$(DOCKER) exec -it $(SNMP_CONTAINER) sh -c "/bin/bash"

snmp.terminal: # Start a gnome-terminal in snmp container
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $(SNMP_CONTAINER) sh -c \"/bin/bash\"" &

snmp.build_net_snmp: # Build and install net-snmp in the snmp container
	$(TRACE)
	$(DOCKER) exec -it $(SNMP_CONTAINER) sh -c "./build"

snmp.commit:
	$(DOCKER) commit snmp_latest $(SNMP_IMAGE)

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
