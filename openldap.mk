# openldap.mk
OPENLDAP_REMOTE_IMAGE	= osixia/openldap
OPENLDAP_IMAGE		= openldap
OPENLDAP_CONTAINER	= eprime_openldap
OPENLDAP_TAG		= latest

OPENLDAP_EXEC		= $(DOCKER) exec $(OPENLDAP_CONTAINER)
OPENLDAP_EXEC_SH	= $(DOCKER) exec $(OPENLDAP_CONTAINER) sh -c
OPENLDAP_DIR		= /root/openldap
OPENLDAP_CERTDIR 	= openldap/newcerts

include openldap-cert.mk

################################################################

openldap.all: # Download image and run tests
	$(MAKE) openldap.pull
	$(MAKE) openldap.create
	$(MAKE) openldap.start
#	$(MAKE) openldap.listcerts
	$(MAKE) openldap.test

openldap.install_pkgs: openldap.start # Install extra packages
	$(TRACE)
	$(OPENLDAP_EXEC) apt-get update
	$(OPENLDAP_EXEC) apt-get install -y net-tools tcpdump gnutls-bin ssl-cert vim
	$(MKSTAMP)

openldap.create:
	$(TRACE)
	$(DOCKER) create -P --name=$(OPENLDAP_CONTAINER) \
		--hostname ldap.example.org \
		-v $(PWD)/openldap:$(OPENLDAP_DIR) \
		--dns=$(DNS) \
		-p 636:636 \
		--privileged=true \
		--volume $(PWD)/openldap/certs:/container/service/slapd/assets/certs \
		--env LDAP_TLS_CRT_FILENAME=ldapserver.crt \
		--env LDAP_TLS_KEY_FILENAME=ldapserver.key \
		--env LDAP_TLS_CA_CRT_FILENAME=CAchain.pem \
		--env LDAP_LOG_LEVEL=256 \
		--env LDAP_TLS_VERIFY_CLIENT=allow \
		-i \
		$(OPENLDAP_REMOTE_IMAGE) --loglevel debug
	$(DOCKER) commit $(OPENLDAP_CONTAINER) $(OPENLDAP_IMAGE):$(OPENLDAP_TAG)
	$(MKSTAMP)

openldap.start: openldap.create # Start openldap container
	$(TRACE)
	$(DOCKER) start $(OPENLDAP_CONTAINER)
	$(Q)sleep 3
	$(MKSTAMP)

openldap.stop: # Stop openldap container
	$(TRACE)
	$(DOCKER) stop $(OPENLDAP_CONTAINER)
	$(call rmstamp,openldap.start)

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
	$(call rmstamp,openldap.install_pkgs)

openldap.logs:
	$(TRACE)
	$(DOCKER) logs $(OPENLDAP_CONTAINER)

openldap.pull: # Update openldap image
	$(TRACE)
	$(DOCKER) pull $(OPENLDAP_REMOTE_IMAGE)

openldap.test: openldap.start # Run tests and compare result
	$(eval outdir=out/test1)
	$(MKDIR) $(outdir)
	$(RM) $(outdir)/*
	$(OPENLDAP_EXEC_SH) "$(OPENLDAP_DIR)/test.run" &> $(outdir)/test.run.out.1.1.0
	$(Q)./openldap/test.run &> $(outdir)/test.run.out.1.0.2
	$(MAKE) openldap.logs &> $(outdir)/openldap.log
	$(Q)diff -U 1 $(outdir)/test.run.out.1.0.2 $(outdir)/test.run.out.1.1.0 || true
	$(Q)tail -10 $(outdir)/openldap.log

openldap.test2: openldap.start openldap.certs.create # Run tests with $(BP) and compare result
	$(eval outdir=out/test2)
	$(MKDIR) $(outdir)
	$(RM) $(outdir)/*
	$(OPENLDAP_EXEC_SH) "$(OPENLDAP_DIR)/test.run /root/$(OPENLDAP_CERTDIR)/eprime_key_and_cert_$(BP).pem" &> $(outdir)/test.run.out.1.1.0
	$(Q)./openldap/test.run $(OPENLDAP_CERTDIR)/eprime_key_and_cert_$(BP).pem &> $(outdir)/test.run.out.1.0.2
	$(MAKE) openldap.logs &> $(outdir)/openldap.log
	$(Q)diff -U 1 $(outdir)/test.run.out.1.0.2 $(outdir)/test.run.out.1.1.0 || true
	$(Q)tail -10 $(outdir)/openldap.log

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

