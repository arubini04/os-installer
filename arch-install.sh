#!/bin/bash

set -e

##############################################################################
# Config
##############################################################################

# Term colors
W='\e[0m'  # White
R='\e[91m' # Red
G='\e[92m' # Green
B='\e[96m' # Blue
Y='\e[93m' # Yellow

# System
Username="arubini"
Hostname="arch"
Keymap="it"
Locale="en_US.UTF-8"
Timezone="Europe/Rome"

##############################################################################
# Logger
##############################################################################

function log_info() {
    echo ${W}"info:"${W} $1
} 

function log_warning() {
    echo ${Y}"warning:"${W} $1
}

function log_error() {
    echo ${R}"error:"${W} $1
    exit -1
}

##############################################################################
# Setup
##############################################################################

# Ensure that we're running as root
if [[ "$UID" -ne 0 ]]; then
    log_error "you must run this script as ${B}root${W}."
fi

loadkeys ${Keymap}
timedatectl set-ntp true

#######################################
# Disk Partition
#######################################

log_info "choose a disk (eg. sda):"
parted -l | column -t | paste -d " " -- | sed 's,ATA, ,' | awk '$0 ~ /Model/ { print $(NF - 1)" "$2" "$3" "$NF}' | column -t
read -r -p "disk: " Disk

log_warning "disk ${B}/dev/${Disk} will be ${R}erased${W}"
read -r -p "are you sure you want to proceed? (Y/n)" Confirmation 

if [[ "${Confirmation}" != "Y"]] then
    log_info "installation aborted."
    exit 0
fi

echo "[ 1/10] creating partition on /dev/${Disk}"

# sgdisk: https://linux.die.net/man/8/sgdisk
sgdisk -Z "$Disk"

# gdisk's code (https://wiki.archlinux.org/title/GPT_fdisk#partition_type)
#   * ef00: efi-partition
#   * 8304: Linux x86-64 root
sgdisk \
    -n 1:2048:+512M -t 1:ef00  -c 1:EFIPART \
    -n 2:
    -N 3            -t 2:8304  -c 2:ROOTPART \
    "$Disk"

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