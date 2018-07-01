.PRECIOUS: ssh-host-keys/%/ssh_host_rsa_key
ssh-host-keys/%/ssh_host_rsa_key:
	mkdir -p "$(dir $@)"
	ssh-keygen -f "$@" -N '' -C "root@$*" -t rsa

.PRECIOUS: ssh-host-keys/%/ssh_host_dsa_key
ssh-host-keys/%/ssh_host_dsa_key:
	mkdir -p "$(dir $@)"
	ssh-keygen -f "$@" -N '' -C "root@$*" -t dsa

.PRECIOUS: ssh-host-keys/%/ssh_host_ecdsa_key
ssh-host-keys/%/ssh_host_ecdsa_key:
	mkdir -p "$(dir $@)"
	ssh-keygen -f "$@" -N '' -C "root@$*" -t ecdsa

.PRECIOUS: ssh-host-keys/%/ssh_host_ed25519_key
ssh-host-keys/%/ssh_host_ed25519_key:
	mkdir -p "$(dir $@)"
	ssh-keygen -f "$@" -N '' -C "root@$*" -t ed25519

ssh-host-keys/%: ssh-host-keys/%/ssh_host_rsa_key \
                 ssh-host-keys/%/ssh_host_dsa_key \
                 ssh-host-keys/%/ssh_host_ecdsa_key \
                 ssh-host-keys/%/ssh_host_ed25519_key
	#

.PRECIOUS: tinc-keys/%.priv
tinc-keys/%.priv:
	openssl genpkey -algorithm RSA -out "tinc-keys/$*.priv" -pkeyopt rsa_keygen_bits:2048
	openssl rsa -pubout -in "tinc-keys/$*.priv" -out "tinc-keys/$*.pub"

.PRECIOUS: matchbox/groups/%.json
matchbox/groups/%.json: $(wildcard ./generate-config/*)
	mkdir -p "$(dir $@)"
	./node_modules/.bin/coffee ./generate-config/ignition-group.coffee $* > $@

.PRECIOUS: matchbox/profiles/%.json
matchbox/profiles/%.json: $(wildcard ./generate-config/*)
	mkdir -p "$(dir $@)"
	./node_modules/.bin/coffee ./generate-config/ignition-profile.coffee $* > $@

.PRECIOUS: matchbox/ignition/%.json
matchbox/ignition/%.json: $(wildcard ./generate-config/*) tinc-keys \
                          $(wildcard ./ssh-keys/*) $(wildcard ./ssh-keys/*) \
                          $(wildcard ./bash-profile/*)
	mkdir -p "$(dir $@)"
	./node_modules/.bin/coffee ./generate-config/ignition.coffee $* > $@

.PHONY: matchbox-%
matchbox-%: matchbox/profiles/%.json matchbox/groups/%.json matchbox/ignition/%.json ssh-host-keys/% tinc-keys/%.priv
	#

.PHONY: matchbox
matchbox: matchbox-coreos0 matchbox-coreos1 matchbox-coreos3 matchbox-coreos4

BACKUP_DIR = "./backups/$(shell date +'%Y-%m-%d_%H:%M:%S')"

.PHONY: backup
backup:
	mkdir -p $(BACKUP_DIR)/matchbox
	cp -R -t $(BACKUP_DIR) ./ssh-keys ./tinc-keys ./ssh-host-keys
	cp -R -t $(BACKUP_DIR)/matchbox ./matchbox/groups ./matchbox/ignition ./matchbox/profiles
