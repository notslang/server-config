# Server Config Files

This repo holds a collection of config files for my homelab and other servers. I use:

- [btrfs](https://btrfs.wiki.kernel.org/) as the underlying filesystem on all disks (which [saves me](https://btrfs.wiki.kernel.org/index.php/Using_Btrfs_with_Multiple_Devices) from needing RAID controllers)
- [Docker](https://www.docker.com/) for most applications.
- [OpenWrt](https://openwrt.org/) for my routers.

There's still proprietary software running on my network switches, the BIOS of all nodes that don't support [libreboot](http://libreboot.org/), and the HDD/SSD firmware. Besides those flaws, all the software running on the cluster is free.

SSH keys go in `./ssh-keys`. Any `*.pub` files will be added to the authorized keys list, all other files will be considered private keys and added to the `.ssh` directory on the nodes.

Each server has at least one disk and 2 partitions.

partition  | type  | why?
---------- | ----- | --------------------------------------------------------------
/data      | btrfs | data that needs to stay around & can be made of multiple disks
/ephemeral | ext4  | data that's destroyed on reboot, including a swap file

Creating these partitions isn't automated yet, so I use parted & manual disk labeling:

```bash
sudo parted /dev/sda
(parted) mklabel gpt
(parted) mkpart primary ext4 0% 50%
(parted) mkpart primary btrfs 50% 100%
(parted) name 1 EPHEMERAL
(parted) name 2 DATA
sudo mkfs.ext4 /dev/sda1
sudo mkfs.btrfs -f /dev/sda2
sudo btrfs fi label /dev/sda2 DATA
```
