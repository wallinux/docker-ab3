# docker.mk

#################################################################


DOCKER			?= $(Q)docker


DOCKER_FILE		?= Dockerfile
DOCKER_DIR		?= docker_dir
DOCKER_CONTAINER	?= docker_container
DOCKER_IMAGE		?= docker_image
#DOCKER_BUILDARGS	?= --no-cache
#DOCKER_OPTS 		?= --ipc host --net host --privileged
DOCKER_MOUNTS		?= -v $(PWD):$(PWD)

DOCKER_NAME_RUNNING	= $(eval container_running=$(shell docker inspect -f {{.State.Running}} $(DOCKER_CONTAINER)))
DOCKER_CONTAINER_ID	= $(eval container_id=$(shell docker ps -a -q -f name="^$(DOCKER_CONTAINER)$$"))
DOCKER_IMAGE_ID		= $(eval image_id=$(shell docker images -q $(DOCKER_IMAGE) 2> /dev/null))

ifneq ($(V),1)
DEVNULL			?= > /dev/null
endif
#######################################################################

.PHONY:: docker.*

docker.build: $(DOCKER_DIR)/$(DOCKER_FILE) # build docker image
	$(TRACE)
	$(DOCKER_IMAGE_ID)
ifneq ($(V),1)
	$(eval quiet=-q)
endif
	$(IF) [ -z "$(image_id)" ]; then \
		docker build $(quiet) $(DOCKER_BUILDARGS) --pull -f $< \
		-t "$(DOCKER_IMAGE)" $(DOCKER_DIR); \
	fi

docker.create: docker.build
	$(TRACE)
	$(DOCKER_CONTAINER_ID)
	$(IF) [ -z "$(container_id)" ]; then \
		docker create -P --name $(DOCKER_CONTAINER) \
		$(DOCKER_MOUNTS) \
		$(DOCKER_OPTS) \
		-i $(DOCKER_IMAGE) $(DEVNULL); \
	fi

docker.start: docker.create # start docker docker
	$(TRACE)
	$(DOCKER) start $(DOCKER_CONTAINER) $(DEVNULL)

docker.stop: # stop docker docker
	$(TRACE)
	-$(DOCKER) stop -t 1 $(DOCKER_CONTAINER) $(DEVNULL)

docker.rm: docker.stop # remove docker docker
	$(TRACE)
	-$(DOCKER) rm $(DOCKER_CONTAINER) $(DEVNULL)

docker.rmi: # remove docker image
	$(TRACE)
	-$(DOCKER) rmi $(DOCKER_IMAGE) $(DEVNULL)

docker.logs: # show docker logs
	$(TRACE)
	$(DOCKER) logs $(DOCKER_CONTAINER)

docker.shell: docker.start # start docker shell
	$(TRACE)
	$(DOCKER) exec -it $(DOCKER_CONTAINER) /bin/sh -c "bash"

docker.clean: # stop and remove docker docker and remove configs
	$(TRACE)
	$(MAKE) docker.rm

docker.distclean: docker.clean # remove image
	$(TRACE)
	$(MAKE) docker.rmi

docker.help:
	$(DOCKER_IMAGE_ID)
	$(DOCKER_CONTAINER_ID)
	$(call run-help, docker.mk)
	$(GREEN)
	$(ECHO) " IMAGE: $(DOCKER_IMAGE) id=$(image_id)"
	$(ECHO) " DOCKER: $(DOCKER_NAME) id=$(container_id) running=$(shell docker inspect -f {{.State.Running}} $(container_id))"
	$(NORMAL)
