# arn-build3 docker

default: docker.help

include common.mk

################################################################
DOCKER_IMAGES += jenkins
DOCKER_IMAGES += saxofon/wrlinux_builder:5_8
DOCKER_IMAGES += gitea/gitea

DOCKER_CONTAINERS += docker.jenkins
DOCKER_CONTAINERS += docker.gitea

DOCKER_PATH 	=""
DOCKER		= $(Q)docker

################################################################
docker.pull: # Fetch all images
	$(Q)$(foreach image,$(DOCKER_IMAGES), \
		docker pull $(image); )

docker.update: docker.pull # Update all images
	$(TRACE)

docker.%: #
	$(TRACE)
	$(DOCKER) $*

docker.list: docker.images docker.ps # List all images and containers
	$(ECHO) ""

jenkins.create:
	$(TRACE)
	$(DOCKER) create -P --name eprime_jenkins \
	-v /opt/jenkins:/var/jenkins_home:shared \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-h jenkins.eprime.com \
	-p 8080:8080 \
	-p 50000:50000 \
	-it jenkins
	$(MKSTAMP)

jenkins.start: # Start jenkins container
	$(TRACE)
	$(DOCKER) start eprime_jenkins

jenkins.stop: # Stop jenkins container
	$(TRACE)
	$(DOCKER) stop eprime_jenkins

jenkins.rm: # Remove jenkins container
	$(TRACE)
	$(DOCKER) rm eprime_jenkins
	$(RM) $(BUILDDIR)/stamps/jenkins.create

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

docker.run: $(DOCKER_CONTAINERS)

docker.export:
	$(TRACE)

docker.help:
	$(GREEN)
	$(ECHO) -e "\n----- $@ -----"
	$(Q)grep ":" Makefile | grep -v -e grep | grep -e "\#" | sed 's/:/#/' | cut -d'#' -f1,3 | sort | column -s'#' -t 
	$(NORMAL)
