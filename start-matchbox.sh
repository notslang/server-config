docker run --name matchbox -d --rm \
        -p 8080:8080 \
        -v $PWD/examples:/var/lib/matchbox:Z \
        -v $PWD/examples/groups/etcd3:/var/lib/matchbox/groups:Z \
        quay.io/coreos/matchbox:latest -address=0.0.0.0:8080 -log-level=debug
