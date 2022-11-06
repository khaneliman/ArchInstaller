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

if [[ -d "/sys/firmware/efi" ]]; then
  grub-install --efi-directory=/boot "${DISK}"
fi

grub_config

display_manager

essential_services

echo -ne "
-------------------------------------------------------------------------
                    Cleaning
-------------------------------------------------------------------------
"

echo "Cleaning up sudoers file"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "Cleaning up installation files"
rm -r "$HOME"/archinstaller
rm -r /home/"$USERNAME"/archinstaller

# Replace in the same state
clear
