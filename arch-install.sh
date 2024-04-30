#!/bin/bash

# Ensure that we're running as root
if [[ "$UID" -ne 0 ]]; then
    echo "You must run this script as root." >&2
    exit -1
fi

#######################################
# Configuration
#######################################
RootDisk   = "/dev/sdb"
HomeDisk   = "/dev/sdb"
OtherDisks = ("/dev/sda")

Username="arubini"
Hostname="arch"
Keymap="it"
Locale="en_US.UTF-8"
Timezone="Europe/Rome"
#######################################



#######################################
# Disk Partition
#######################################
echo "[ 1/10] Creating partition on ${RootDisk}"

# sgdisk: https://linux.die.net/man/8/sgdisk
sgdisk -Z "$RootDisk"

# gdisk's code (https://wiki.archlinux.org/title/GPT_fdisk#partition_type)
#   * ef00: efi-partition
#   * 8304: Linux x86-64 root
sgdisk \
    -n 1:2048:+512M -t 1:ef00  -c 1:EFIPART \
    -N 2            -t 2:8304  -c 2:ROOTPART \
    "$RootDisk"

# reload partition table
sleep 2
partprobe -s "$RootDisk"



#######################################
# Creating FileSystem
#######################################
echo "[ 2/10] Creating filesystem"
mkfs.fat  -F 32 -n EFIPART  /dev/disk/by-partlabel/EFIPART
mkfs.ext4 -L       ROOTPART /dev/disk/by-partlabel/ROOTPART


#######################################
# Mouting FileSystem
#######################################
echo "[ 3/10] Mouting filesystem"
mount /dev/disk/by-partlabel/ROOTPART /mnt
mkdir /mnt/efi -p
mount -t fat /dev/disk/by-partlabel/EFIPART /mnt/efi
