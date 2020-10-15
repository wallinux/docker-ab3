# cc_server.mk

CC_SERVER_WORKSPACE	?= $(TOP)/codechecker-web
CC_SERVER_REL		?= latest
CC_SERVER_IMAGE		?= codechecker/codechecker-web:$(CC_SERVER_REL)
CC_SERVER_CONTAINER	?= codechecker-web

CC_SERVER_ID		= $(eval cc_server_id=$(shell docker ps -a -q -f name=$(CC_SERVER_CONTAINER)))

CC_SERVER_IP		?= localhost
CC_SERVER_PORT		?= 8001

define run-cc-exec
	$(DOCKER) exec $(1) $(CC_SERVER_CONTAINER) $(2)
endef

#######################################################################

$(CC_SERVER_WORKSPACE):
	$(MKDIR) $@

cc_server.prepare:
	$(TRACE)
	$(DOCKER) start $(CC_SERVER_CONTAINER)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(call run-cc-exec, , sh -c "echo $(host_timezone) > /etc/timezone" )
	$(call run-cc-exec, , ln -sfn /usr/share/zoneinfo/$(host_timezone) /etc/localtime )
	$(call run-cc-exec, , dpkg-reconfigure -f noninteractive tzdata 2> /dev/null)
	$(MAKE) cc_server.stop

cc_server.create: | $(CC_SERVER_WORKSPACE) # create codechecker server container
	$(TRACE)
	$(CC_SERVER_ID)
	$(IF) [ -z "$(cc_server_id)" ]; then \
		docker create -P --name $(CC_SERVER_CONTAINER) \
		-v $(CC_SERVER_WORKSPACE):/workspace \
		-p $(CC_SERVER_PORT):8001 \
		-i $(CC_SERVER_IMAGE); \
		make cc_server.prepare; \
	fi

cc_server.start: cc_server.create # start codechecker server container
	$(TRACE)
	$(DOCKER) start $(CC_SERVER_CONTAINER)

cc_server.stop: # stop codechecker server container
	$(TRACE)
	-$(DOCKER) stop -t 2 $(CC_SERVER_CONTAINER)

cc_server.rm: cc_server.stop # remove codechecker server container
	$(TRACE)
	-$(DOCKER) rm $(CC_SERVER_CONTAINER)

cc_server.rmi: # remove codechecker server image
	$(TRACE)
	-$(DOCKER) rmi $(CC_SERVER_IMAGE)

cc_server.logs: # show codechecker server container log
	$(TRACE)
	$(DOCKER) logs $(CC_SERVER_CONTAINER)

cc_server.shell: # start shell in container
	$(TRACE)
	$(call run-cc-exec, -it, /bin/sh -c "/bin/bash")

cc_server.help:
	$(call run-help, cc_server.mk)
	$(GREEN)
	$(ECHO) " SERVER: http://$(CC_SERVER_IP):$(CC_SERVER_PORT)/Default"
	$(NORMAL)

cc_server.distclean: cc_server.rm cc_server.rmi
	$(TRACE)
	$(RM) -r $(CC_SERVER_WORKSPACE)

#######################################################################

help:: cc_server.help

distclean:: cc_server.distclean
