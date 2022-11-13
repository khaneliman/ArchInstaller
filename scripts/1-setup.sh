#!/usr/bin/env bash
#github-action genshdoc
#
# @file Setup
# @brief Configures installed system, installs base packages, and creates user.
# @stdout Output routed to install.log
# @stderror Output routed to install.log

# source utility scripts
for filename in /root/archinstaller/scripts/utils/*.sh; do
    [ -e "$filename" ] || continue
    # shellcheck source=./utils/*.sh
    source "$filename"
done
source "$HOME"/archinstaller/configs/setup.conf

logo

network_install

pacman -S --noconfirm --needed --color=always pacman-contrib curl
pacman -S --noconfirm --needed --color=always rsync grub arch-install-scripts git

mirrorlist_update

cpu_config

locale_config

# Add sudo no password rights
sed -Ei 's/^# (%wheel ALL=\(ALL(:ALL)?\) NOPASSWD: ALL)/\1/' /etc/sudoers

#Add parallel downloading
sed -i '/^#ParallelDownloads/s/^#//' /etc/pacman.conf

extra_repos

base_install

microcode_install

graphics_install

# If this file run without configuration, ask for basic user info before setting up user
if ! source "$HOME"/archinstaller/configs/setup.conf; then
    user_info
fi

add_user

if [[ "${FS}" == "luks" ]]; then
    # Making sure to edit mkinitcpio conf if luks is selected
    # add encrypt in mkinitcpio.conf before filesystems in hooks
    sed -i 's/filesystems/encrypt &/g' /etc/mkinitcpio.conf
    # making mkinitcpio with linux kernel
    mkinitcpio -p linux
fi
echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 2-user.sh
-------------------------------------------------------------------------
"
