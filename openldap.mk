# openldap.mk
OPENLDAP_REMOTE_IMAGE  	= osixia/openldap
OPENLDAP_IMAGE  	= openldap
OPENLDAP_CONTAINER	= eprime_openldap
OPENLDAP_TAG		= latest

################################################################

openldap.prepare:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $(OPENLDAP_CONTAINER)
#	$(DOCKER) exec -u root $(OPENLDAP_CONTAINER) \
#		sh -c "echo $(host_timezone) >/etc/timezone && ln -sf /usr/share/zoneinfo/$(host_timezone) /etc/localtime && dpkg-reconfigure -f noninteractive tzdata"
#	$(DOCKER) exec $(OPENLDAP_CONTAINER) \
#		sh -c "if [ ! -e /root/.ssh/id_rsa ]; then ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''; fi"

openldap.create:
	$(TRACE)
	$(DOCKER) create -P --name=$(OPENLDAP_CONTAINER) \
		-h openldap.eprime.com \
		-v $(PWD)/openldap:/root/openldap \
		--dns=$(DNS) \
		-p 636:636 \
		--privileged=true \
		-i \
		$(OPENLDAP_REMOTE_IMAGE)
	$(MAKE) openldap.prepare
	$(DOCKER) commit $(OPENLDAP_CONTAINER) $(OPENLDAP_IMAGE):$(OPENLDAP_TAG)
	$(MKSTAMP)

openldap.start: # Start openldap container
	$(TRACE)
	$(DOCKER) start $(OPENLDAP_CONTAINER)

openldap.stop: # Stop openldap container
	$(TRACE)
	$(DOCKER) stop $(OPENLDAP_CONTAINER)

openldap.rm: # Remove openldap container
	$(TRACE)
	$(DOCKER) rm $(OPENLDAP_CONTAINER)

openldap.rmi: # Remove openldap image
	$(TRACE)
	$(DOCKER) rmi $(OPENLDAP_IMAGE)
	$(call rmstamp,openldap.create)

openldap.pull: # Update openldap image
	$(TRACE)
	$(DOCKER) pull $(OPENLDAP_REMOTE_IMAGE)

openldap.validate:
	$(DOCKER) exec $(OPENLDAP_CONTAINER) ldapsearch -x -H ldap://localhost -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w admin

openldap.test:
	$(DOCKER) exec $(OPENLDAP_CONTAINER)  sh -c "cd /root/openldap/; ./test.run > test.run.out.1.1.0" || true
	$(Q)cd openldap/; ./test.run > test.run.out.1.0.2 || true

openldap.shell: # Start a shell in openldap container
	$(TRACE)
	$(DOCKER) exec -it $(OPENLDAP_CONTAINER) sh -c "/bin/bash"

openldap.terminal: # Start a gnome-terminal in openldap container
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $(OPENLDAP_CONTAINER) sh -c \"/bin/bash\"" &

openldap.help:
	$(TRACE)
	$(call run-help, openldap.mk)

help:: openldap.help

pull:: openldap.pull
