# CoreOS & Kubernetes Config Files

This repo holds a collection of config files for my homelab. I use:

- [CoreOS](http://coreos.com/) as a base for all nodes
- [btrfs](https://btrfs.wiki.kernel.org/index.php/Main_Page) as the underlying filesystem on all disks (which [saves me](https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices) from needing RAID controllers)
- [Ceph](http://ceph.com/) for distributed cluster-wide storage (on top of btrfs)
- [Kubernetes](http://kubernetes.io/) For scheduling Docker/rkt containers to nodes & managing storage volumes / secrets
- [OpenWrt](https://openwrt.org/) for my routers.
- [Elasticsearch](https://github.com/elastic/elasticsearch) / [Kibana](https://github.com/elastic/kibana) for log & statistics aggregation / analysis.

There's still proprietary software running on my network switches, the BIOS of all nodes that don't support [libreboot](http://libreboot.org/), and the HDD/SSD firmware. Besides those flaws, all the software running on the cluster is free.

SSH keys go in `./ssh-keys`. Any `*.pub` files will be added to the authorized keys list, all other files will be considered private keys and added to the `.ssh` directory on the nodes.

Servers are started & configured via PXE boot using CoreOS's Matchbox & Ignition. I run pfsense on my router right now, which doesn't include a TFTP server, so I use a separate instance of dnsmasq with a TFTP server on my desktop and proxy any non-PXE requests it gets to the pfsense router. The router is configured so "next-server" is my desktop and the correct filenames for each PXE file is set. Start matchbox & dnsmasq with:

```sh
docker run --name matchbox -d -p 8080:8080 -v $(pwd)/matchbox:/var/lib/matchbox quay.io/coreos/matchbox:latest -address=0.0.0.0:8080 -log-level=debug
docker run --name dnsmasq -d --net=host --cap-add=NET_ADMIN -v $(pwd)/matchbox-dnsmasq.conf:/etc/dnsmasq.conf:Z quay.io/coreos/dnsmasq:v0.5.0 -d
```
