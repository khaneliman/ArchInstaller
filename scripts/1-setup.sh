#!/usr/bin/env bash
#github-action genshdoc
#
# @file Setup
# @brief Configures installed system, installs base packages, and creates user.
# @stdout Output routed to install.log
# @stderror Output routed to install.log

logo
source $HOME/ArchInstaller/configs/setup.conf

network_install

pacman -S --noconfirm --needed --color=always pacman-contrib curl
pacman -S --noconfirm --needed --color=always rsync grub arch-install-scripts git

mirrorlist_update

cpu_config

locale_config

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed --color=always

base_install

microcode_install

graphics_install

# If this file run without configuration, ask for basic user info before setting up user
if ! source $HOME/ArchInstaller/configs/setup.conf; then
    user_info
fi

add_user

if [[ ${FS} == "luks" ]]; then
    # Making sure to edit mkinitcpio conf if luks is selected
    # add encrypt in mkinitcpio.conf before filesystems in hooks
    sed -i 's/filesystems/encrypt filesystems/g' /etc/mkinitcpio.conf
    # making mkinitcpio with linux kernel
    mkinitcpio -p linux
fi
echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 2-user.sh
-------------------------------------------------------------------------
"
