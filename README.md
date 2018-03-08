# CoreOS & Kubernetes Config Files

This repo holds a collection of config files for my homelab. I use:

- [CoreOS](http://coreos.com/) as a base for all nodes
- [btrfs](https://btrfs.wiki.kernel.org/index.php/Main_Page) as the underlying filesystem on all disks (which [saves me](https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices) from needing RAID controllers)
- [Ceph](http://ceph.com/) for distributed cluster-wide storage (on top of btrfs)
- [Kubernetes](http://kubernetes.io/) For scheduling Docker/rkt containers to nodes & managing storage volumes / secrets
- [OpenWrt](https://openwrt.org/) for my routers.
- [Elasticsearch](https://github.com/elastic/elasticsearch) / [Kibana](https://github.com/elastic/kibana) for log & statistics aggregation / analysis.

There's still proprietary software running on my network switch, the BIOS of all nodes that don't support [libreboot](http://libreboot.org/), and the HDD/SSD firmware. Besides those flaws, all the software running on the cluster is free.

SSH keys go in `./ssh-keys`. Any `*.pub` files will be added to the authorized keys list, all other files will be considered private keys and added to the `.ssh` directory on the nodes.
