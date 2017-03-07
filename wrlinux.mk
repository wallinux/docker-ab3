# wrlinux.mk

WRLINUX_IMAGE 	   += saxofon/wrlinux_builder

################################################################

wrlinux.rmi: # Remove all wrlinux images
	$(TRACE)
	#$(DOCKER) images | grep $(WRLINUX_IMAGE) | xargs docker rmi

wrlinux.pull: # Update all wrlinux images
	$(TRACE)
	$(DOCKER) pull -a $(WRLINUX_IMAGE)

wrlinux.help:
	$(TRACE)
	$(call run-help, wrlinux.mk)

help:: wrlinux.help

pull:: wrlinux.pull
