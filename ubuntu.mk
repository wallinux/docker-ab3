# ubuntu.mk

UBUNTU			= ubuntu
UBUNTU_TAG		= 19.10
UBUNTU_TAGS		= 16.04 18.04 19.10

################################################################

ubuntu.pull: # Pull image from dockerhub
	$(TRACE)
	$(DOCKER) pull $(UBUNTU):$(UBUNTU_TAG)

ubuntu.PULL: # Pull ALL ubuntu images from dockerhub
	$(TRACE)
	$(Q)$(foreach tag,$(UBUNTU_TAGS),make -s ubuntu.pull UBUNTU_TAG=$(tag); )

pull:: ubuntu.PULL

ubuntu.help:
	$(TRACE)
	$(call run-help, ubuntu.mk)
	$(GREEN)
	$(ECHO) -e "\n-----------------------"
	$(ECHO) -e "UBUNTU=$(UBUNTU)"
	$(ECHO) -e "UBUNTU_TAG=$(UBUNTU_TAG), available UBUNTU_TAGS=<$(UBUNTU_TAGS)>"
	$(NORMAL)

help:: ubuntu.help

