#!/usr/bin/env bash
#github-action genshdoc
#
# @file Preinstall
# @brief Contains the steps necessary to configure and pacstrap the install to selected drive.
# @stdout Output routed to install.log
# @stderror Output routed to install.log

logo

iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm --color=always archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed --color=always pacman-contrib reflector rsync grub
sed -i '/^#ParallelDownloads/s/^#//' /etc/pacman.conf

# Update mirrors
mirrorlist_update

# Format Disk
format_disk

# Make filesystems
create_filesystems

# mount target
mkdir -p /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

mount_check

arch_install

echo -e "\n Adding keyserver to gpg.conf"
echo "keyserver hkp://keyserver.ubuntu.com" >>/mnt/etc/pacman.d/gnupg/gpg.conf

echo -e "\n Copying $SCRIPT_DIR to /mnt/root/archinstaller"
cp -R "${SCRIPT_DIR}" /mnt/root/archinstaller

echo -e "\n Copying mirrorlist to /mnt/etc/pacman.d/mirrorlist"
cp "/etc/pacman.d/mirrorlist" "/mnt/etc/pacman.d/mirrorlist"

echo -e "\n Generating fstab"
genfstab -L /mnt >>/mnt/etc/fstab

echo " 
  Generated /etc/fstab:
"
cat /mnt/etc/fstab

bootloader_install

low_memory_config

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 1-setup.sh
-------------------------------------------------------------------------
"
