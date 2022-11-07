#!/usr/bin/env bash
#github-action genshdoc
#
# @file Post-Setup
# @brief Finalizing installation configurations and cleaning up after script.
# @stdout Output routed to install.log
# @stderror Output routed to install.log

# source utility scripts
for filename in "$HOME"/archinstaller/scripts/utils/*.sh; do
  [ -e "$filename" ] || continue
  # shellcheck source=./utils/*.sh
  source "$filename"
done
source $HOME/archinstaller/configs/setup.conf

logo

echo -ne "
Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"

[[ -d "/sys/firmware/efi" ]] && grub-install --efi-directory=/boot "${DISK}"

grub_config

display_manager

essential_services

echo -ne "
-------------------------------------------------------------------------
                    Cleaning
-------------------------------------------------------------------------
"

echo "Cleaning up sudoers file"
# Remove no password sudo rights, add sudo rights
sed -Ei 's/^%wheel ALL=\(ALL(:ALL)?\) NOPASSWD: ALL/# &/;
s/^# (%wheel ALL=\(ALL(:ALL)?\) ALL)/\1/' /etc/sudoers

echo "Cleaning up installation files"
rm -r "$HOME"/archinstaller /home/"$USERNAME"/archinstaller

# Replace in the same state
clear
