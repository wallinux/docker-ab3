# jenkins.mk
################################################################
JENKINS_REMOTE_TAG ?= lts
JENKINS_REMOTE_IMAGE = jenkins/jenkins:$(JENKINS_REMOTE_TAG)
JENKINS_IMAGE 	  = jenkins
JENKINS_CONTAINER = rcs_eprime_jenkins
JENKINS_TAG 	  = $(JENKINS_CONTAINER)
JENKINS_PORT	  ?= 8091
JENKINS_HOME	  ?= /var/jenkins_home
JENKINS_CLI	  = java -jar $(JENKINS_HOME)/war/WEB-INF/jenkins-cli.jar -auth jenkins_cli:jenkins_cli -s http://localhost:$(JENKINS_PORT)/

JENKINS_OPTS	  = --httpPort=$(JENKINS_PORT)
JENKINS_LOG	  = log.properties

JENKINS_EXEC_jenkins = $(DOCKER) exec -u jenkins $(JENKINS_CONTAINER)
JENKINS_EXEC_root    = $(DOCKER) exec -u root    $(JENKINS_CONTAINER)
################################################################

.PHONY: jenkins.*

jenkins.log:
	$(MKDIR) jenkins/
	$(ECHO) "handlers=java.util.logging.ConsoleHandler" > jenkins/$(JENKINS_LOG)
	$(ECHO) "jenkins.level=FINEST" >> jenkins/$(JENKINS_LOG)
	$(ECHO) "java.util.logging.ConsoleHandler.level=FINEST" >> jenkins/$(JENKINS_LOG)

jenkins.prepare:
	$(TRACE)
	$(eval users_gid=$(shell getent group users  | cut -d: -f3))
	$(eval docker_gid=$(shell getent group docker | cut -d: -f3))
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $(JENKINS_CONTAINER)
	$(JENKINS_EXEC_root) apt-get update
	$(JENKINS_EXEC_root) apt-get install make bsdmainutils libltdl7
	$(JENKINS_EXEC_root) usermod -g users jenkins
	$(JENKINS_EXEC_root) groupadd --gid $(docker_gid) docker
	$(JENKINS_EXEC_root) usermod -aG docker jenkins
	$(JENKINS_EXEC_root) sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
	$(DOCKER) stop $(JENKINS_CONTAINER)
	$(DOCKER) commit $(JENKINS_CONTAINER) $(JENKINS_IMAGE):$(JENKINS_TAG)

jenkins.dockerhost:
	$(TRACE)
	$(ECHO) $$(hostname) > $(JENKINS_HOME)/dockerhost

jenkins.create: # Create jenkins container
	$(TRACE)
	$(eval docker_bin=$(shell which docker))
	$(DOCKER) create -P --name $(JENKINS_CONTAINER) \
		-v $(JENKINS_HOME):$(JENKINS_HOME) \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(docker_bin):/usr/bin/docker \
		-h jenkins.eprime.com \
		-u jenkins \
		--dns=$(DNS) \
		--dns-search=wrs.com \
		-p $(JENKINS_PORT):$(JENKINS_PORT) \
		-e "JENKINS_OPTS=$(JENKINS_OPTS)" \
		-it $(JENKINS_REMOTE_IMAGE)
	$(MAKE) jenkins.prepare
	$(MKSTAMP)

jenkins.start: jenkins.create # Start jenkins container
	$(TRACE)
	$(DOCKER) start $(JENKINS_CONTAINER)

jenkins.stop: # Stop jenkins container
	$(TRACE)
	-$(DOCKER) stop -t 2 $(JENKINS_CONTAINER)

jenkins.logs: # Show jenkins container logs
	$(TRACE)
	$(DOCKER) logs $(JENKINS_CONTAINER)

jenkins.rm: # Remove jenkins container
	$(TRACE)
	-$(DOCKER) rm $(JENKINS_CONTAINER)

jenkins.rmi: # Remove jenkins image
	$(TRACE)
	-$(DOCKER) rmi $(JENKINS_IMAGE):$(JENKINS_TAG)
	$(call rmstamp,jenkins.create)

jenkins.clean:
	$(MAKE) jenkins.stop
	$(MAKE) jenkins.rm
	$(MAKE) jenkins.rmi

jenkins.update.apt: jenkins.start
	$(TRACE)
	$(JENKINS_EXEC_root) apt-get update
	$(JENKINS_EXEC_root) apt-get upgrade -y

jenkins.update.plugins: jenkins.start
	$(TRACE)
	$(JENKINS_EXEC_jenkins) $(JENKINS_CLI) list-plugins | grep -e ')$$' | awk '{ print $$1 }' > $(JENKINS_HOME)/plugin_updatelist
	$(ECHO) "#!/bin/bash" >$(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) "if [ -s $(JENKINS_HOME)/plugin_updatelist ]; then"  >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) '  update_pluginlist=$$(cat $(JENKINS_HOME)/plugin_updatelist)' >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) '  $(JENKINS_CLI) install-plugin $$update_pluginlist' >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(ECHO) 'fi' >> $(JENKINS_HOME)/plugin_updatelist.sh
	$(Q)chmod 777 $(JENKINS_HOME)/plugin_updatelist.sh
	$(JENKINS_EXEC_jenkins) cat $(JENKINS_HOME)/plugin_updatelist
	$(JENKINS_EXEC_jenkins) sh -c $(JENKINS_HOME)/plugin_updatelist.sh
	$(JENKINS_EXEC_jenkins) $(JENKINS_CLI) safe-restart
	$(JENKINS_EXEC_jenkins) rm -f $(JENKINS_HOME)/plugin_updatelist.sh $(JENKINS_HOME)/plugin_updatelist

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
	$(DOCKER) pull $(JENKINS_REMOTE_IMAGE)

pull:: jenkins.pull
	$(TRACE)

jenkins.help:
	$(TRACE)
	$(call run-help, jenkins.mk)

help:: jenkins.help
