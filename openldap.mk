# openldap.mk
OPENLDAP_REMOTE_IMAGE	= osixia/openldap
OPENLDAP_IMAGE		= openldap
OPENLDAP_CONTAINER	= eprime_openldap
OPENLDAP_TAG		= latest

################################################################

openldap.all:  # Download image and run tests
	$(MAKE) openldap.pull
	$(MAKE) openldap.create
	$(MAKE) openldap.start
	$(MAKE) openldap.listcerts
	$(MAKE) openldap.test

openldap.prepare:
	$(TRACE)
	$(DOCKER) start $(OPENLDAP_CONTAINER)
	$(DOCKER) exec -u root $(OPENLDAP_CONTAINER) apt-get update
	$(DOCKER) exec -u root $(OPENLDAP_CONTAINER) apt-get install -y \
		net-tools tcpdump gnutls-bin ssl-cert vim

openldap.create:
	$(TRACE)
	$(DOCKER) create -P --name=$(OPENLDAP_CONTAINER) \
		--hostname ldap.example.org \
		-v $(PWD)/openldap:/root/openldap \
		--dns=$(DNS) \
		-p 636:636 \
		--privileged=true \
		--volume $(PWD)/openldap/certs:/container/service/slapd/assets/certs \
		--env LDAP_TLS_CRT_FILENAME=ldapserver.crt \
		--env LDAP_TLS_KEY_FILENAME=ldapserver.key \
		--env LDAP_TLS_CA_CRT_FILENAME=CAchain.pem \
		--env LDAP_LOG_LEVEL=-1 \
		-i \
		$(OPENLDAP_REMOTE_IMAGE) --loglevel debug

	$(MAKE) openldap.prepare
	$(DOCKER) commit $(OPENLDAP_CONTAINER) $(OPENLDAP_IMAGE):$(OPENLDAP_TAG)
	$(MKSTAMP)

openldap.start: openldap.create # Start openldap container
	$(TRACE)
	$(DOCKER) start $(OPENLDAP_CONTAINER)

openldap.stop: # Stop openldap container
	$(TRACE)
	$(DOCKER) stop $(OPENLDAP_CONTAINER)

openldap.restart: # Restart openldap container
	$(DOCKER) stop $(OPENLDAP_CONTAINER)
	$(DOCKER) start $(OPENLDAP_CONTAINER)

openldap.rm: # Remove openldap container
	$(TRACE)
	$(DOCKER) rm $(OPENLDAP_CONTAINER)

openldap.rmi: # Remove openldap image
	$(TRACE)
	$(DOCKER) rmi $(OPENLDAP_IMAGE)
	$(call rmstamp,openldap.create)

openldap.logs:
	$(TRACE)
	$(DOCKER) logs $(OPENLDAP_CONTAINER)

openldap.pull: # Update openldap image
	$(TRACE)
	$(DOCKER) pull $(OPENLDAP_REMOTE_IMAGE)

openldap.test: # Run tests and compare result
	$(MKDIR) -p out
	$(DOCKER) exec $(OPENLDAP_CONTAINER)  sh -c "/root/openldap/test.run" &> out/test.run.out.1.1.0 || true
	$(Q)./openldap/test.run &> out/test.run.out.1.0.2 || true
	$(MAKE) openldap.logs &> out/openldap.log
	$(Q)diff -U 1 out/test.run.out.1.0.2 out/test.run.out.1.1.0 || true

openldap.test2: # Run tests with $(BP) and compare result
	$(MKDIR) -p out
	$(DOCKER) exec $(OPENLDAP_CONTAINER)  sh -c "/root/openldap/test.run $(BP).pem" &> out/test.run.out.1.1.0 || true
	$(Q)./openldap/test.run $(BP).pem &> out/test.run.out.1.0.2 || true
	$(MAKE) openldap.logs &> out/openldap.log
	$(Q)diff -U 1 out/test.run.out.1.0.2 out/test.run.out.1.1.0 || true

openldap.shell: # Start a shell in openldap container
	$(TRACE)
	$(DOCKER) exec -it $(OPENLDAP_CONTAINER) sh -c "/bin/bash"

openldap.terminal: # Start a gnome-terminal in openldap container
	$(TRACE)
	$(Q)gnome-terminal --command "docker exec -it $(OPENLDAP_CONTAINER) sh -c \"/bin/bash\"" &

openldap.clean: # Stop and remove openldap images/containers
	$(MAKE) -i openldap.stop
	$(MAKE) -i openldap.rm
	$(MAKE) -i openldap.rmi
	$(RM) -r out

openldap.help:
	$(TRACE)
	$(call run-help, openldap.mk)

help:: openldap.help

pull:: openldap.pull

include openldap-cert.mk
