# codechecker.mk

codechecker.%: export DOCKER_IMAGE:=codechecker
codechecker.%: export DOCKER_CONTAINER:=codechecker
codechecker.%: export DOCKER_DIR=codechecker
codechecker.%: export DOCKER_FILE:=Dockerfile


codechecker.%:
	$(MAKE) docker.$*

#######################################################################

clean:: codechecker.clean

distclean:: codechecker.distclean

help:: codechecker.help
