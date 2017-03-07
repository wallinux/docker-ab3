# gitea.mk
GITEA_IMAGE   	  = gitea/gitea
GITEA_CONTAINER   = eprime_gitea

################################################################

gitea.create: # Create a gitea container
	$(TRACE)
	$(DOCKER) create -P --name $(GITEA_CONTAINER) \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v /opt/gitea:/data \
	-h gitea.eprime.com \
	-p 3000:3000 \
	-p 10022:22 \
	-it $(GITEA_IMAGE)
	$(MKSTAMP)

gitea.start: gitea.start #Start gitea container
	$(TRACE)
	$(DOCKER) start $(GITEA_CONTAINER)

gitea.stop: # Stop gitea container
	$(TRACE)
	$(DOCKER) stop $(GITEA_CONTAINER)

gitea.rm: # Remove gitea container
	$(TRACE)
	$(DOCKER) rm $(GITEA_CONTAINER)
	$(call rmstamp,gitea.create)

gitea.rmi: # Remove gitea image
	$(TRACE)
	$(DOCKER) rmi $(GITEA_IMAGE)

gitea.pull: # Update gitea image
	$(TRACE)
	$(DOCKER) pull $(GITEA_IMAGE)

gitea.help:
	$(TRACE)
	$(call run-help, gitea.mk)

help:: gitea.help

pull:: gitea.pull
