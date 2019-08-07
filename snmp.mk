# snmp.mk

DISTRO			?= ubuntu
DISTRO_TAG		?= 18.10
DISTRO_TAGS		?= 16.04 18.10 19.04
DISTRO_NAME		= $(DISTRO)_$(DISTRO_TAG)

SNMP_REGISTRY_SERVER	= $(DOCKER_ID_USER)

SNMP_TAG		?= AW_master
SNMP_TAGS_16.04		= AW_master WR8_prime
SNMP_TAGS_18.04		= AW_master WR8_prime
SNMP_TAGS_18.10		= AW_master WR8_prime
SNMP_TAGS		= $(SNMP_TAGS_$(DISTRO_TAG))

SNMP_REMOTE_IMAGE	?= $(SNMP_REGISTRY_SERVER)/snmp_$(DISTRO_NAME):$(SNMP_TAG)
SNMP_IMAGE		?= snmp_$(DISTRO_NAME):$(SNMP_TAG)
SNMP_CONTAINER_0	= $(SNMP_TAG).snmp_0_$(DISTRO_NAME)
SNMP_CONTAINER_1	= $(SNMP_TAG).snmp_1_$(DISTRO_NAME)
SNMP_CONTAINER		?= $(SNMP_CONTAINER_0)
SNMP_CONTAINERS		= $(SNMP_CONTAINER_0) $(SNMP_CONTAINER_1)
SNMP_GITROOT		= $(shell git rev-parse --show-toplevel)

export DISTRO_NAME
export DISTRO_TAG
export SNMP_TAG

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
ifeq ($(V),1)
	$(DOCKER) build -f $(dockerfile) -t "snmp_$(DISTRO_NAME):$*" .
else
	$(DOCKER) build -q -f $(dockerfile) -t "snmp_$(DISTRO_NAME):$*" .
endif
	$(RM) $(dockerfile)
	$(MAKE) snmp.tag SNMP_TAG=$*

snmp.build.$(DISTRO_NAME).%:
	$(TRACE)
	$(MAKE) snmp.build.$* DISTRO_NAME=$(DISTRO_NAME)
	$(MKSTAMP)

snmp.build: # Build snmp image for SNMP_TAG
	$(TRACE)
	$(MAKE) snmp.build.$(DISTRO_NAME).$(SNMP_TAG)

snmp.BUILD: # Build net-snmp for ALL images
	$(TRACE)
	$(Q)$(foreach tag,$(SNMP_TAGS), make -s V=$(V) snmp.build.$(tag); )

snmp.update.%:
	$(TRACE)
	$(eval dockerfile=snmp/Dockerfile.$*)
	$(MAKE) snmp.build.$(DISTRO_NAME).$*
	$(ECHO) "FROM snmp_$(DISTRO_NAME):$*" > $(dockerfile)
	$(ECHO) "MAINTAINER Anders Wallin" >> $(dockerfile)
	$(ECHO) "RUN (apt-get update -y; apt-get upgrade -y)" >> $(dockerfile)
	$(ECHO) "RUN (cd net-snmp; git fetch; make install > make_install.out)" >> $(dockerfile)
	$(DOCKER) build -f $(dockerfile) -t "snmp_$(DISTRO_NAME):$*" .
	$(RM) $(dockerfile)
	$(MAKE) snmp.tag SNMP_IMAGE=snmp_$(DISTRO_NAME):$*

snmp.update: # Update snmp image for SNMP_TAG
	$(TRACE)
	$(MAKE) snmp.update.$(SNMP_TAG)

snmp.UPDATE: # Update net-snmp for ALL images
	$(TRACE)
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
	$(DOCKER) stop -t 2 $* || true
	$(call rmstamp,snmp.start.$*)

snmp.stop: # Stop snmp containers
	$(TRACE)
	$(Q)$(foreach container,$(SNMP_CONTAINERS), make -s snmp.stop.$(container); )

snmp.STOP: # Stop ALL snmp containers
	$(TRACE)
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.stop SNMP_TAG=$(tag); )

snmp.rm.%:
	$(TRACE)
	$(DOCKER) rm $* || true
	$(call rmstamp,snmp.create.$*)

snmp.rm: # Remove snmp container
	$(TRACE)
	$(Q)$(foreach container,$(SNMP_CONTAINERS), make -s snmp.rm.$(container); )

snmp.RM: snmp.STOP # Remove ALL snmp containers
	$(TRACE)
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.rm SNMP_TAG=$(tag); )

snmp.rmi: # Remove snmp image
	$(TRACE)
	$(DOCKER) rmi $(SNMP_IMAGE) || true
	$(call rmstamp,snmp.build.$(DISTRO_NAME).$(SNMP_TAG))

snmp.RMI: # Remove ALL snmp images
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.rmi SNMP_TAG=$(tag); )
	$(MAKE) snmp.rmi SNMP_TAG=latest

snmp.remote.rmi: snmp.rm # Remove downloaded snmp image
	$(TRACE)
	$(DOCKER) rmi $(SNMP_REMOTE_IMAGE) || true

snmp.remote.RMI: # Remove ALL remote snmp images
	$(TRACE)
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.remote.rmi SNMP_TAG=$(tag); )
	$(MAKE) snmp.rmi SNMP_TAG=latest

snmp.shell.%:
	$(TRACE)
	$(DOCKER) exec -it $* sh -c "/bin/bash"

snmp.shell: snmp.start # Start a shell in snmp container
	$(TRACE)
	$(MAKE) snmp.shell.$(SNMP_CONTAINER_0)

snmp.terminal: snmp.start # Start a gnome-terminal in snmp container
	$(TRACE)
	$(MAKE) snmp.terminal.$(SNMP_CONTAINER_0)

snmp.terminal.%:
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $* sh -c \"/bin/bash\"" &

snmp.tag:
	$(TRACE)
	echo "docker tag $(SNMP_IMAGE) $(SNMP_REMOTE_IMAGE)"
	$(DOCKER) tag $(SNMP_IMAGE) $(SNMP_REMOTE_IMAGE)

snmp.push: snmp.tag # Push image to registry
	$(TRACE)
	$(DOCKER) push $(SNMP_REMOTE_IMAGE)

snmp.PUSH: # Push ALL snmp images to registry
	$(TRACE)
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.push SNMP_TAG=$(tag); )

snmp.pull: # Pull image from registry
	$(TRACE)
	$(DOCKER) pull $(SNMP_REMOTE_IMAGE)

snmp.PULL: # Pull ALL snmp images from registry
	$(TRACE)
	$(Q)$(foreach tag,$(SNMP_TAGS),make -s snmp.pull SNMP_TAG=$(tag); )

snmp.lsi:
	$(TRACE)
	$(DOCKER) images -f reference=snmp*:* -f reference=*/snmp*:*
	$(DOCKER) images -f reference=*/snmp*:*

pull:: snmp.PULL

snmp.distclean: snmp.remote.RMI snmp.RMI network.rm

distclean:: snmp.distclean

snmp.help:
	$(TRACE)
	$(call run-help, snmp.mk)
	$(GREEN)
	$(ECHO) -e "\n-----------------------"
	$(ECHO) -e "DISTRO=$(DISTRO)"
	$(ECHO) -e "DISTRO_TAG=$(DISTRO_TAG), available DISTRO_TAGS=<$(DISTRO_TAGS)>"
	$(ECHO) -e "SNMP_TAG=$(SNMP_TAG), available SNMP_TAGS=<$(SNMP_TAGS)>"
	$(NORMAL)

help:: snmp.help

