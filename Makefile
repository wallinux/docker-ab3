# arn-build3 docker

default: docker.help

include common.mk

################################################################
DOCKER_IMAGES += jenkins
DOCKER_IMAGES += saxofon/wrlinux_builder:5_8
DOCKER_IMAGES += gitea/gitea

DOCKER_CONTAINERS += docker.jenkins
DOCKER_CONTAINERS += docker.gitea
DOCKER_CONTAINERS += docker.wrlinux6
DOCKER_CONTAINERS += docker.wrlinux8

DOCKER_PATH 	=""
DOCKER		= $(Q)docker

################################################################
docker.pull: # Fetch all images
	$(foreach image,$(DOCKER_IMAGES), \
		docker pull $(image); )

docker.update: docker.pull # Update all images

docker.%:
	$(TRACE)
	$(DOCKER) $*

docker.list: docker.images docker.ps # List all images and containers
	$(ECHO) ""

docker.jenkins: # Start jenkins container 
	$(TRACE)

docker.gitea: # Start gitea container
	$(TRACE)

docker.wrlinux6:
	$(TRACE)

docker.wrlinux8:
	$(TRACE)

docker.run: $(DOCKER_CONTAINERS)

docker.export:
	$(TRACE)

docker.help:
	$(GREEN)
	$(ECHO) -e "\n----- $@ -----"
	$(Q)grep ":" Makefile | grep -v -e grep | grep -e "\#" | sed 's/:/#/' | cut -d'#' -f1,3 | sort | column -s'#' -t 
	$(NORMAL)
