# arn-build3 docker

default: help

include common.mk

################################################################
JENKINS_IMAGE 	  = jenkins
JENKINS_CONTAINER = eprime_jenkins
JENKINS_PORT	  = 8091
JENKINS_HOME	  = /var/jenkins_home
JENKINS_CLI	  = java -jar $(JENKINS_HOME)/war/WEB-INF/jenkins-cli.jar -s http://127.0.0.1:8080/
JENKINS_OPTS	  = --httpPort=$(JENKINS_PORT)

GITEA_IMAGE   	  = gitea/gitea
GITEA_CONTAINER   = eprime_gitea

DOCKER_IMAGES 	+= $(JENKINS_IMAGE)
DOCKER_IMAGES 	+= $(GITEA_CONTAINER)
DOCKER_IMAGES 	+= saxofon/wrlinux_builder:5_8

DOCKER_RUN 	+= jenkins.start
DOCKER_RUN 	+= gitea.start

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

jenkins.create:
	$(TRACE)
	$(eval docker_bin=$(shell which docker))
	$(eval docker_gid=$(shell getent group docker | cut -d: -f3))
	$(eval users_gid=$(shell getent group users  | cut -d: -f3))
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) create -P --name $(JENKINS_CONTAINER) \
	-v $(JENKINS_HOME):$(JENKINS_HOME):shared \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v $(docker_bin):/usr/bin/docker \
	-h jenkins.eprime.com \
	-u jenkins \
	--dns=128.224.92.11 \
	--dns-search=wrs.com \
	-p $(JENKINS_PORT):$(JENKINS_PORT) \
	-p 50000:50000 \
	-e "JENKINS_OPTS=$(JENKINS_OPTS)" \
	-it $(JENKINS_IMAGE)
	$(DOCKER) start $(JENKINS_CONTAINER)
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) apt-get update
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) apt-get install make bsdmainutils
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) usermod -g users jenkins
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) groupadd --gid $(docker_gid) docker
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) usermod -aG docker jenkins
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
	$(DOCKER) stop $(JENKINS_CONTAINER)
	$(MKSTAMP)

jenkins.start: jenkins.create # Start jenkins container
	$(TRACE)
	$(DOCKER) start $(JENKINS_CONTAINER)

jenkins.stop: # Stop jenkins container
	$(TRACE)
	$(DOCKER) stop $(JENKINS_CONTAINER)

jenkins.restart: # Restart jenkins container
	$(TRACE)
	$(DOCKER) stop $(JENKINS_CONTAINER)
	$(DOCKER) start $(JENKINS_CONTAINER)

jenkins.logs: # Log from jenkins container
	$(TRACE)
	$(DOCKER) logs $(JENKINS_CONTAINER)

jenkins.rm: # Remove jenkins container
	$(TRACE)
	$(DOCKER) rm $(JENKINS_CONTAINER)
	$(RM) $(TOP)/.stamps/jenkins.create

jenkins.update.apt: jenkins.start
	$(TRACE)
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) apt-get update
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) apt-get upgrade -y

jenkins.update.plugins: jenkins.start
	$(TRACE)
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) $(JENKINS_CLI) list-plugins | grep -e ')$$' | awk '{ print $$1 }' > $(JENKINS_HOME)/plugin_updatelist
	$(ECHO) "#!/bin/bash" >$(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) "if [ -s $(JENKINS_HOME)/plugin_updatelist ]; then"  >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) '  update_pluginlist=$$(cat $(JENKINS_HOME)/plugin_updatelist)' >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) '  $(JENKINS_CLI) install-plugin $$update_pluginlist' >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) 'fi' >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(Q)chmod +x $(JENKINS_HOME)/plugin_updatelist.sh
	$(Q)cat $(JENKINS_HOME)/plugin_updatelist.sh
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) sh -c $(JENKINS_HOME)/plugin_updatelist.sh
	$(DOCKER) exec -u root $(JENKINS_CONTAINER) $(JENKINS_CLI) safe-restart
	$(RM) $(JENKINS_HOME)/plugin_updatelist.sh $(JENKINS_HOME)/plugin_updatelist

jenkins.update: jenkins.update.apt jenkins.update.plugins # Update rpm packages and jenkins plugins
	$(TRACE)

jenkins.shell: # Start a shell in jenkins container
	$(TRACE)
	$(DOCKER) exec -u jenkins -it $(JENKINS_CONTAINER) /bin/bash -c "cd $(JENKINS_HOME); exec '$${SHELL:-sh}'"

jenkins.rootshell: # Start a shell as root user in jenkins container
	$(TRACE)
	$(DOCKER) exec -u root -it $(JENKINS_CONTAINER) /bin/bash

jenkins.dockertest: # Test to run a docker image inside jenkins
	$(TRACE)
	$(DOCKER) exec -it $(JENKINS_CONTAINER) docker run --rm hello-world

jenkins.pull:
	$(TRACE)
	$(DOCKER) pull $(JENKINS_IMAGE)

jenkins.%:
	$(TRACE)
	$(DOCKER) $* $(JENKINS_CONTAINER)

gitea.start: # Create and start gitea container
	$(TRACE)
	$(DOCKER) create -P --name $(GITEA_CONTAINER) \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v /opt/gitea:/data \
	-h gitea.eprime.com \
	-p 3000:3000 \
	-p 10022:22 \
	-it $(GITEA_IMAGE)
	$(DOCKER) start eprime_gitea

docker.run: $(DOCKER_CONTAINERS)

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
