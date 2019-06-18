docker run --name dnsmasq -d --rm \
        --net=host \
        --cap-add=NET_ADMIN \
        -v $(pwd)/matchbox-dnsmasq.conf:/etc/dnsmasq.conf:Z \
        quay.io/coreos/dnsmasq:v0.5.0
