# gitlab.mk
GITLAB_IMAGE   	  = gitlab/gitlab-ce
GITLAB_CONTAINER   = eprime_gitlab

################################################################

gitlab.run: # Run a gitlab container
	$(TRACE)
	$(DOCKER) run --detach \
		--hostname gitlab.example.com \
		--publish 443:443 \
		--publish 8080:80 \
		--publish 10022:22 \
		--name $(GITLAB_CONTAINER) \
		--restart always \
		--volume /srv/gitlab/config:/etc/gitlab \
		--volume /srv/gitlab/logs:/var/log/gitlab \
		--volume /srv/gitlab/data:/var/opt/gitlab \
		$(GITLAB_IMAGE)
	$(MKSTAMP)

gitlab.start: # Start gitlab container
	$(TRACE)
	$(DOCKER) start $(GITLAB_CONTAINER)

gitlab.stop: # Stop gitlab container
	$(TRACE)
	$(DOCKER) stop $(GITLAB_CONTAINER)

gitlab.rm: # Remove gitlab container
	$(TRACE)
	$(DOCKER) rm $(GITLAB_CONTAINER)
	$(call rmstamp,gitlab.run)

gitlab.rmi: # Remove gitlab image
	$(TRACE)
	$(DOCKER) rmi $(GITLAB_IMAGE)

gitlab.pull: # Update gitlab image
	$(TRACE)
	$(DOCKER) pull $(GITLAB_IMAGE)

gitlab.help:
	$(TRACE)
	$(call run-help, gitlab.mk)

help:: gitlab.help

pull:: gitlab.pull
