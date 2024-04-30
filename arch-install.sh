#!/bin/bash

set -e

##############################################################################
# Config
##############################################################################

# Term colors
W='\033[0m'  # White (No Color)
R='\033[1;31m' # Red
G='\033[0;32m' # Green
C='\033[0;36m' # Cyan
Y='\033[1;33m' # Yellow

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
    echo -e ${C}"info:"${W} $1
} 

function log_warning() {
    echo -e ${Y}"warning:"${W} $1
}

function log_error() {
    echo -e ${R}"error:"${W} $1
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

log_info "choose a disk:"
parted -l | column -t | paste -d " " - - | sed 's,ATA, ,' | awk '$0 ~ /Model/ { print "\033[1;33m"$(NF - 1)"\033[0m "$2" "$3" "$NF}' | column -t
read -r -p "disk (e.g. sda): " Disk

Disk = "/dev/${Disk}"

log_warning "disk ${C}${Disk}${W} will be ${R}erased${W}"
read -r -p "are you sure you want to proceed? (Y/n) " Confirmation 

if [[ "${Confirmation}" != "Y" ]]; then
    log_info "installation aborted."
    exit 0
fi

echo

log_info "[ 1/10] creating partition on ${Disk}"

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