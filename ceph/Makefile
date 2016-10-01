secrets/fsid:
	uuidgen > "$@"

secrets/ceph-client-key:
	python ceph-key.py > "$@"

secrets/ceph.mds.keyring: templates/bootstrap.keyring.tmpl
	sigil -f "$<" service=mds key=$(shell python ceph-key.py) > "$@"

secrets/ceph.mon.keyring: templates/mon.keyring.tmpl
	sigil -f "$<" key=$(shell python ceph-key.py) > "$@"

secrets/ceph.osd.keyring: templates/bootstrap.keyring.tmpl
	sigil -f "$<" service=osd key=$(shell python ceph-key.py) > "$@"

secrets/ceph.rgw.keyring: templates/bootstrap.keyring.tmpl
	sigil -f "$<" service=rgw key=$(shell python ceph-key.py) > "$@"

secrets/ceph.client.admin.keyring: templates/admin.keyring.tmpl secrets/ceph-client-key
	sigil -f "$<" key=$(shell cat secrets/ceph-client-key) > "$@"

secrets/ceph.conf: templates/ceph.conf.tmpl secrets/fsid
	sigil -p -f "$<" fsid=$(shell cat secrets/fsid) "osd_cluster_network=10.2.99.0/24" "osd_public_network=10.2.99.0/24" > "$@"

ceph: secrets/ceph.mds.keyring secrets/ceph.mon.keyring \
	    secrets/ceph.osd.keyring secrets/ceph.rgw.keyring \
	    secrets/ceph.client.admin.keyring secrets/ceph.conf
	kubectl create namespace ceph
	kubectl create secret generic ceph-conf-combined --from-file=secrets/ceph.conf --from-file=secrets/ceph.client.admin.keyring --from-file=secrets/ceph.mon.keyring --namespace=ceph
	kubectl create secret generic ceph-bootstrap-rgw-keyring --from-file=ceph.keyring=secrets/ceph.rgw.keyring --namespace=ceph
	kubectl create secret generic ceph-bootstrap-mds-keyring --from-file=ceph.keyring=secrets/ceph.mds.keyring --namespace=ceph
	kubectl create secret generic ceph-bootstrap-osd-keyring --from-file=ceph.keyring=secrets/ceph.osd.keyring --namespace=ceph
	kubectl create secret generic ceph-client-key --from-file=secrets/ceph-client-key --namespace=ceph
