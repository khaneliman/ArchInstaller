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

echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"
# services part of the base installation
echo "Enabling NetworkManager"
systemctl enable NetworkManager.service
echo "NetworkManager enabled \n"

echo "Enabling Periodic Trim"
systemctl enable fstrim.timer
echo "Periodic Trim enabled \n"

if [[ ${INSTALL_TYPE} == "FULL" ]]; then

  # services part of full installation
  echo "Enabling Cups"
  systemctl enable cups.service
  echo "  Cups enabled \n"

  echo "Syncing time with ntp"
  ntpd -qg
  echo "Time synced \n"

  echo "Enabling ntpd"
  systemctl enable ntpd.service
  echo "NTP enabled \n"

  echo "Disabling DHCP"
  systemctl disable dhcpcd.service
  echo "DHCP disabled \n"

  echo "Stopping DHCP"
  systemctl stop dhcpcd.service
  echo "DHCP stopped \n"

  echo "Enabling Bluetooth"
  systemctl enable bluetooth
  echo "Bluetooth enabled \n"

  echo "Enabling Avahi"
  systemctl enable avahi-daemon.service
  echo "Avahi enabled \n"

  if [[ "${FS}" == "luks" || "${FS}" == "btrfs" ]]; then
    snapper_config
  fi

  plymouth_config

fi

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
