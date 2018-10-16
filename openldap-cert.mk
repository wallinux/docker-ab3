CERTTOOL 	= $(Q)certtool
CERTDIR 	= $(PWD)/openldap/awcerts

CA_TEMPLATE 	= $(CERTDIR)/ca.cfg
CA_KEY		= $(CERTDIR)/ca.key
CA_CERT		= $(CERTDIR)/cacert.pem

SLAPD_TEMPLATE 	= $(CERTDIR)/eprime_slapd.cfg
SLAPD_KEY	= $(CERTDIR)/eprime_slapd.key
SLAPD_CERT 	= $(CERTDIR)/eprime_slapd.pem

CERTINFO	= $(CERTDIR)/certinfo.ldif

define listcert
	echo -e "\n--- $(1)"
	openssl crl2pkcs7 -nocrl -certfile $(1) | openssl pkcs7 -print_certs -text -noout | grep -e "Subject:" -e "Public Key Algorithm" -e "ASN"
endef

define listcertfull
	echo -e "\n--- $(1)"
	openssl crl2pkcs7 -nocrl -certfile $(1) | openssl pkcs7 -print_certs -text -noout
endef

###################################################################################
#if 0
$(CERTDIR):
	$(MKDIR) $@

$(CA_TEMPLATE): | $(CERTDIR)
# 	Create the template file to define the CA
	$(ECHO) "cn = Eprime Inc" > $@
	$(ECHO) "ca" >> $@
	$(ECHO) "cert_signing_key" >> $@

$(CA_KEY):
#	Create a private key for the Certificate Authority
	$(CERTTOOL) --generate-privkey > $@

$(CA_CERT): $(CA_TEMPLATE) $(CA_KEY)
#	Create the self-signed CA certificate:
	$(CERTTOOL) --generate-self-signed --load-privkey $(CA_KEY) --template $(CA_TEMPLATE) --outfile $@ 2> $@.txt 

$(SLAPD_KEY):
#	Make a private key for the server:
	$(CERTTOOL) --generate-privkey --sec-param Low --outfile $@ 
#	Adjust permissions and ownership
	#$(Q)chgrp openldap $@
	#$(Q)chmod 0640 $@
	#gpasswd -a openldap ssl-cert

$(SLAPD_TEMPLATE): | $(CERTDIR) 
#	Create the slapd info file
	$(ECHO) "organization = Eprime Inc" > $@
	$(ECHO) "cn = ldap.eprime.com" >> $@
	$(ECHO) "tls_www_server" >> $@
	$(ECHO) "encryption_key" >> $@
	$(ECHO) "signing_key" >> $@
	$(ECHO) "expiration_days = 3650" >> $@

$(SLAPD_CERT): $(SLAPD_TEMPLATE) $(SLAPD_KEY) $(CA_CERT)
	$(CERTTOOL) --generate-certificate --load-privkey $(SLAPD_KEY) \
		--load-ca-certificate $(CA_CERT) --load-ca-privkey $(CA_KEY) \
		--template $(SLAPD_TEMPLATE) --outfile $@ 2> $@.txt 

$(CERTINFO):
#	example assumes we created certs using https://www.cacert.org):
	$(ECHO) "dn: cn=config" > $@
	$(ECHO) "add: olcTLSCACertificateFile" >> $@
	$(ECHO) "olcTLSCACertificateFile: $(CA_CERT)" >> $@
	$(ECHO) "-" >> $@
	$(ECHO) "add: olcTLSCertificateFile" >> $@
	$(ECHO) "olcTLSCertificateFile: $(SLAPD_CERT)" >> $@
	$(ECHO) "-" >> $@
	$(ECHO) "add: olcTLSCertificateKeyFile" >> $@
	$(ECHO) "olcTLSCertificateKeyFile: $(SLAPD_KEY)" >> $@
#	ldapmodify -Y EXTERNAL -H ldapi:/// -f $(CERTINFO)

openldap.certs.create: $(CA_CERT) $(SLAPD_CERT) $(CERTINFO)
openldap.certs.lists: # List certificates
	$(MAKE) openldap.cert.list cert=$(CA_CERT)
	$(MAKE) openldap.cert.list cert=$(SLAPD_CERT)

openldap.certs.clean:
	$(RM) -r $(CERTDIR)
#endif

openldap.cert.list:
	$(TRACE)
	$(Q)$(call listcertfull, $(cert))

#if 1
BP=brainpoolP160r1
openldap.cert.create: # Create certificate
	$(Q)openssl ecparam -genkey -name $(BP) -out openldap/certs/eprime_$(BP)_privatekey.pem
	$(Q)openssl req -new -x509 -days 365 -subj '/CN=ldap.eprime.com' -key openldap/certs/eprime_$(BP)_privatekey.pem -out openldap/certs/eprime_$(BP)_cert.pem
	$(Q)cat openldap/certs/eprime_$(BP)_privatekey.pem openldap/certs/eprime_$(BP)_cert.pem > openldap/certs/eprime_key_and_cert_$(BP).pem
	#$(Q)openssl x509 -req -CAkey CAchain.pem -CA ca.cert -CAcreateserial -in $t.csr -out $t.cert
	$(MAKE) openldap.cert.list cert=openldap/certs/eprime_key_and_cert_$(BP).pem

CERTS=CAchain.pem ldapserverCA.pem ldapserver.crt malte_key_and_cert_brainpoolP160r1.pem
openldap.listcerts: # List all certificates
	$(Q)$(foreach cert,$(CERTS), make -s openldap.cert.list cert=openldap/certs/$(cert) ; )
#endif
