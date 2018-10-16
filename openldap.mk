# openldap.mk
OPENLDAP_REMOTE_IMAGE	= osixia/openldap
OPENLDAP_IMAGE		= openldap
OPENLDAP_CONTAINER	= eprime_openldap
OPENLDAP_TAG		= latest


define listcert
	echo -e "\n--- $(1)"
	openssl crl2pkcs7 -nocrl -certfile $(1) | openssl pkcs7 -print_certs -text -noout | grep -e "Subject:" -e "Public Key Algorithm" -e "ASN"
endef

define listcertfull
	echo -e "\n--- $(1)"
	openssl crl2pkcs7 -nocrl -certfile $(1) | openssl pkcs7 -print_certs -text -noout
endef

################################################################

openldap.all:
	$(MAKE) openldap.pull
	$(MAKE) openldap.create
	$(MAKE) openldap.start
	$(MAKE) openldap.listcerts
	$(MAKE) openldap.test

openldap.prepare:
	$(TRACE)
	$(eval host_timezone=$(shell cat /etc/timezone))
	$(DOCKER) start $(OPENLDAP_CONTAINER)
	$(DOCKER) exec -u root $(OPENLDAP_CONTAINER) apt-get update
	$(DOCKER) exec -u root $(OPENLDAP_CONTAINER) apt-get install -y net-tools tree

openldap.create:
	$(TRACE)
	$(DOCKER) create -P --name=$(OPENLDAP_CONTAINER) \
		-h ldap.eprime.com \
		-v $(PWD)/openldap:/root/openldap \
		--dns=$(DNS) \
		-p 636:636 \
		--privileged=true \
		--volume $(PWD)/openldap/certs:/container/service/slapd/assets/certs \
		--env LDAP_TLS_CRT_FILENAME=ldapserver.crt \
		--env LDAP_TLS_KEY_FILENAME=ldapserver.key \
		--env LDAP_TLS_CA_CRT_FILENAME=CAchain.pem \
		-i \
		$(OPENLDAP_REMOTE_IMAGE)
	$(MAKE) openldap.prepare
	$(DOCKER) commit $(OPENLDAP_CONTAINER) $(OPENLDAP_IMAGE):$(OPENLDAP_TAG)
	$(MKSTAMP)

openldap.start: openldap.create # Start openldap container
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

openldap.logs:
	$(TRACE)
	$(DOCKER) logs $(OPENLDAP_CONTAINER)

openldap.pull: # Update openldap image
	$(TRACE)
	$(DOCKER) pull $(OPENLDAP_REMOTE_IMAGE)

openldap.validate:
	$(DOCKER) exec $(OPENLDAP_CONTAINER) ldapsearch -x -H ldap://localhost -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w admin

CERTS=CAchain.pem ldapserverCA.pem ldapserver.crt malte_key_and_cert_brainpoolP160r1.pem
openldap.listcert:
	$(TRACE)
	$(Q)$(call listcert, $(cert))

openldap.listcerts:
	$(Q)$(foreach cert,$(CERTS), make -s openldap.listcert cert=openldap/certs/$(cert) ; )

openldap.test:
	$(MKDIR) -p out
	$(DOCKER) exec $(OPENLDAP_CONTAINER)  sh -c "/root/openldap/test.run" &> out/test.run.out.1.1.0 || true
	$(Q)./openldap/test.run &> out/test.run.out.1.0.2 || true
	$(MAKE) openldap.logs &> out/openldap.log
	$(Q)diff -U 1 out/test.run.out.1.0.2 out/test.run.out.1.1.0 || true

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
