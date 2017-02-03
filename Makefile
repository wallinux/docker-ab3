# arn-build3 docker

default: help

include common.mk

export TERM xterm

################################################################
DOCKER_IMAGES += jenkins
DOCKER_IMAGES += saxofon/wrlinux_builder:5_8
DOCKER_IMAGES += gitea/gitea

DOCKER_PATH 	=""
DOCKER		= $(Q)docker

JENKINS_CONTAINER = rcs_eprime_jenkins
JENKINS_PORT	  = 8091
JENKINS_HOME	  = /var/jenkins_home

GITEA_CONTAINER   = eprime_gitea

WRLINUX8_IMAGE 	   = rcs_eprime_wrlinux8
WRLINUX8_CONTAINER = rcs_eprime_wrlinux8

GITEA_CONTAINER   = eprime_gitea

################################################################
docker.pull: # Fetch all images
	$(Q)$(foreach image,$(DOCKER_IMAGES), \
		docker pull $(image); )

docker.update: docker.pull # Update all images
	$(TRACE)

docker.ps:
	$(TRACE)
	$(DOCKER) ps -a

docker.%: # $ docker %
	$(TRACE)
	$(DOCKER) $*

docker.list: docker.images docker.ps # List all images and containers
	$(ECHO) ""

$(WRLINUX8_IMAGE).dir:
	$(MKDIR) $@

wrlinux8-builder.start:
	$(TRACE)
	# TODO remove docker image

wrlinux8-builder.clean:
	$(TRACE)
	$(RM) -r  $(WRLINUX8_IMAGE).dir
	# TODO remove docker image

wrlinux8-builder.create: $(WRLINUX8_IMAGE).dir
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(ECHO) "FROM saxofon/wrlinux_builder:5_8" > $</Dockerfile
	$(ECHO) "MAINTAINER Anders Wallin" >> $</Dockerfile
	$(ECHO) "RUN useradd --shell /bin/bash -d $(HOME) -u $(shell id -u) $(USER)" >> $</Dockerfile
	$(ECHO) "RUN apt-get update" >> $</Dockerfile
	$(ECHO) "RUN apt-get install -y apt-utils" >> $</Dockerfile
	$(ECHO) "RUN apt-get upgrade -y" >> $</Dockerfile
	$(ECHO) "RUN apt-get install -y apt-utils xsltproc" >> $</Dockerfile
	$(ECHO) "ENTRYPOINT bin/bash -c echo Starting $(WRLINUX8_IMAGE).dir" >> $</Dockerfile
	$(ECHO) "CMD ln -sfn /usr/share/zoneinfo/$(host_timezone) /etc/localtime" >> $</Dockerfile
	$(ECHO) "CMD echo $(host_timezone) > dpkg-reconfigure -f noninteractive tzdata" >> $</Dockerfile
#TODO
# Add image name and tag
# Fixa TERM
# Lägg till image clean rule
#	$(ECHO) "CMD grep -v -e "^WIND_INSTALL_BASE" -e "^\#" make/hostconfig-$(HOSTNAME).mk > make/hostconfig-$(DOCKER_HOSTNAME).mk" >> $</Dockerfile
#	$(ECHO) "CMD echo "WIND_LX_HOME = $(WIND_LX_HOME)" >> make/hostconfig-$(DOCKER_HOSTNAME).mk" >> $</Dockerfile
	$(DOCKER) build $<

jenkins.create:
	$(TRACE)
	$(eval docker_bin=$(shell which docker))
	$(eval docker_gid=$(shell getent group docker | cut -d: -f3))
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) create -P --name $(JENKINS_CONTAINER) \
	-v $(JENKINS_HOME):$(JENKINS_HOME):shared \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v $(docker_bin):/usr/bin/docker \
	-h jenkins.eprime.com \
	--dns=128.224.92.11 \
	--dns-search=wrs.com \
	-p $(JENKINS_PORT):8080 \
	-p 50000:50000 \
	-it jenkins
	$(DOCKER) start $(JENKINS_CONTAINER)
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) apt-get update
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) apt-get install make bsdmainutils
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) groupadd --gid $(docker_gid) docker
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) usermod -aG docker jenkins
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) echo $(host_timezone) >/etc/timezone && > dpkg-reconfigure -f noninteractive tzdata
	$(DOCKER) stop $(JENKINS_CONTAINER)
	$(MKSTAMP)

jenkins.start: jenkins.create # Start jenkins container
	$(TRACE)
	$(DOCKER) start $(JENKINS_CONTAINER)

jenkins.stop: # Stop jenkins container
	$(TRACE)
	$(DOCKER) stop $(JENKINS_CONTAINER)

jenkins.rm: # Remove jenkins container
	$(TRACE)
	$(DOCKER) rm $(JENKINS_CONTAINER)
	$(RM) $(TOP)/.stamps/jenkins.create

jenkins.shell: # Start a shell in jenkins container
	$(TRACE)
	$(DOCKER) exec -it $(JENKINS_CONTAINER) /bin/bash -c "cd $(JENKINS_HOME); exec '$${SHELL:-sh}'"

jenkins.rootshell: # Start a shell as root user in jenkins container
	$(TRACE)
	$(DOCKER) exec -u root -it $(JENKINS_CONTAINER) /bin/bash

jenkins.dockertest: # Test to run a docker image inside jenkins
	$(TRACE)
	$(DOCKER) exec -it $(JENKINS_CONTAINER) docker run --rm hello-world

docker.jenkins: jenkins.create jenkins.start # Create and start jenkins container
	$(TRACE)

docker.gitea: # Create and start gitea container
	$(TRACE)
	$(DOCKER) create -P --name eprime_gitea \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v /opt/gitea:/data \
	-h gitea.eprime.com \
	-p 3000:3000 \
	-p 10022:22 \
	-it gitea/gitea
	$(DOCKER) start eprime_gitea

docker.export:
	$(TRACE)

docker.help:
	$(GREEN)
	$(ECHO) -e "\n----- $@ -----"
	$(Q)grep ":" Makefile | grep -v -e grep | grep -e "\#" | sed 's/:/#/' | cut -d'#' -f1,3 | sort | column -s'#' -t 
	$(NORMAL)

help: docker.help

docker.todo: # Steps to run manually on ab3
	$(ECHO) cp /opt/jenkins from my laptop
	$(ECHO) sudo ln -sfn /opt/jenkins /var/jenkins_home
	$(ECHO) add awallin and jenkins to docker group
