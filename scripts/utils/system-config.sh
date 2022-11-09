#!/usr/bin/env bash
#github-action genshdoc
#
# @file System Config
# @brief Contains the functions used to modify the system
# @stdout Output routed to install.log
# @stderror Output routed to install.log

# @description Adds user that was setup prior to installation
# @noargs
add_user() {
    echo -ne "
-------------------------------------------------------------------------
                    Adding User
-------------------------------------------------------------------------
"
    if [ $(whoami) = "root" ]; then
        groupadd libvirt
        useradd -m -G wheel,libvirt -s /bin/bash "$USERNAME"
        echo "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"

        # use chpasswd to enter $USERNAME:$password
        echo "$USERNAME":"$PASSWORD" | chpasswd
        echo "$USERNAME password set"

        cp -R "$HOME"/archinstaller /home/"$USERNAME"/
        chown -R "$USERNAME": /home/"$USERNAME"/archinstaller
        echo "archinstaller copied to home directory"

        # enter $NAME_OF_MACHINE to /etc/hostname
        echo "$NAME_OF_MACHINE" >/etc/hostname
    else
        echo "You are already a user proceed with aur installs"
    fi
}

# @description Configures makepkg settings dependent on cpu cores
# @noargs
cpu_config() {
    nc=$(grep -c ^processor /proc/cpuinfo)
    echo -ne "
-------------------------------------------------------------------------
                    You have " $nc" cores. And
			changing the makeflags for "$nc" cores. Aswell as
				changing the compression settings.
-------------------------------------------------------------------------
"
    TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[ "$TOTAL_MEM" -gt 8000000 ]]; then
        sed -i "s/^#\(MAKEFLAGS=\"-j\)2\"/\1$nc\"/;
        /^COMPRESSXZ=(xz -c -z -)/s/-c /&-T $nc /" /etc/makepkg.conf
    fi
}

# @description Create the filesystem on the drive selected for installation
# @noargs
create_filesystems() {
    echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"
    set -e

    if [[ "${DISK}" =~ "nvme" || "${DISK}" =~ "mmc" ]]; then
        partition2="${DISK}"p2
        partition3="${DISK}"p3
    else
        partition2="${DISK}"2
        partition3="${DISK}"3
    fi

    echo "Creating FAT32 boot filesystem on ${partition2}"
    mkfs.vfat -F32 -n "EFIBOOT" "${partition2}"

    if [[ "${FS}" == "btrfs" ]]; then
        do_btrfs "ROOT" "${partition3}"

    elif [[ "${FS}" == "ext4" ]]; then
        echo "Creating EXT4 root filesystem on ${partition3}"
        mkfs.ext4 -L ROOT "${partition3}"
        mount -t ext4 "${partition3}" /mnt

    elif [[ "${FS}" == "luks" ]]; then
        # enter luks password to cryptsetup and format root partition
        echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat "${partition3}" -
        # open luks container and ROOT will be place holder
        echo -n "${LUKS_PASSWORD}" | cryptsetup open "${partition3}" ROOT -

        do_btrfs "ROOT" "${partition3}"

        # store uuid of encrypted partition for grub
        echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value "${partition3}") >>"$CONFIGS_DIR"/setup.conf
    fi

    set +e
}

# @description Install and enable display manager depending on desktop environment chosen
# @noargs
display_manager() {
    echo -ne "
-------------------------------------------------------------------------
               Enabling (and Theming) Login Display Manager
-------------------------------------------------------------------------
"
    if [[ "${DESKTOP_ENV}" == "kde" ]]; then
        systemctl enable sddm.service
        if [[ "${INSTALL_TYPE}" == "FULL" ]]; then
            echo -e "Setting SDDM Theme..."
            echo [Theme] >>/etc/sddm.conf
            echo Current=Nordic >>/etc/sddm.conf
        fi

    elif [[ "${DESKTOP_ENV}" == "gnome" ]]; then
        systemctl enable gdm.service

    elif [[ "${DESKTOP_ENV}" == "lxde" ]]; then
        systemctl enable lxdm.service

    elif [[ "${DESKTOP_ENV}" == "openbox" || "${DESKTOP_ENV}" == "awesome" ]]; then
        systemctl enable lightdm.service
        if [[ "${INSTALL_TYPE}" == "FULL" ]]; then
            echo -e "Setting LightDM Theme..."
            # Set default lightdm-webkit2-greeter theme to Litarvan
            sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = litarvan #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
            # Set default lightdm greeter to lightdm-webkit2-greeter
            sed -i 's/#greeter-session=example.*/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
        fi
    # If none of the above, use lightdm as fallback
    else
        if [[ ! "${INSTALL_TYPE}" == "SERVER" ]]; then
            sudo pacman -S --noconfirm --needed --color=always lightdm lightdm-gtk-greeter
            systemctl enable lightdm.service
        fi
    fi
}

# @description Perform the btrfs filesystem configuration
# @noargs
do_btrfs() {
    echo -ne "
-------------------------------------------------------------------------
                    Creating btrfs device
-------------------------------------------------------------------------
"
    echo -e "Creating btrfs device $1 on $2 \n"
    mkfs.btrfs -L "$1" "$2" -f

    echo -e "Mounting $2 on $MOUNTPOINT \n"
    mount -t btrfs "$2" "$MOUNTPOINT"

    echo "Creating subvolumes and directories"
    for x in "${SUBVOLUMES[@]}"; do
        btrfs subvolume create "$MOUNTPOINT"/"${x}"
    done

    umount "$MOUNTPOINT"
    mount -o "$MOUNT_OPTIONS",subvol=@ "$2" "$MOUNTPOINT"

    for z in "${SUBVOLUMES[@]:1}"; do
        w="${z[*]//@/}"
        mkdir -p /mnt/"${w}"

        echo -e "\n Mounting $z at /$MOUNTPOINT/$w"
        mount -o "$MOUNT_OPTIONS",subvol="${z}" "$2" "$MOUNTPOINT"/"${w}"
    done
}

# @description Format disk before creatign filesystem
# @noargs
format_disk() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
    pacman -S --noconfirm --needed --color=always gptfdisk glibc
    echo -ne "
-------------------------------------------------------------------------
                    Formatting ${DISK}
-------------------------------------------------------------------------
"

    mkdir -p /mnt &>/dev/null              # Hiding error message if any
    umount -A --recursive /mnt &>/dev/null # make sure everything is unmounted before we start

    set -e

    # disk prep
    sgdisk -Z "${DISK}"         # zap all on disk
    sgdisk -a 2048 -o "${DISK}" # new gpt disk 2048 alignment

    # create partitions
    echo -e "\n Creating first partition: BIOSBOOT"
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' "${DISK}" # partition 1 (BIOS Boot Partition)

    echo -e "\n Creating second partition: EFIBOOT"
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' "${DISK}" # partition 2 (UEFI Boot Partition)

    echo -e "\n Creating third partition: ROOT"
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' "${DISK}" # partition 3 (Root), default start, remaining

    [[ ! -d "/sys/firmware/efi" ]] && sgdisk -A 1:set:2 "${DISK}"

    partprobe "${DISK}" # reread partition table to ensure it is correct

    set +e
}

# @description Theme grub
# @noargs
grub_config() {
    echo -ne "
-------------------------------------------------------------------------
               Creating (and Theming) Grub Boot Menu
-------------------------------------------------------------------------
"
    # set kernel parameter for decrypting the drive
    if [[ "${FS}" == "luks" ]]; then
        sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
    fi
    # set kernel parameter for adding splash screen
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

    echo -e "Installing Vimix Grub theme..."
    THEME_DIR="/boot/grub/themes"
    THEME_NAME=Vimix

    echo -e "\n Creating the theme directory..."
    mkdir -p "${THEME_DIR}"/"${THEME_NAME}"

    echo -e "\n Copying the theme..."
    cd "${HOME}"/archinstaller || return
    cp -a configs/base"${THEME_DIR}"/"${THEME_NAME}"/* "${THEME_DIR}"/"${THEME_NAME}"

    echo -e "\n Backing up Grub config..."
    cp -an /etc/default/grub /etc/default/grub.bak

    echo -e "\n Setting the theme as the default..."
    grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
    echo "GRUB_THEME=\"${THEME_DIR}"/"${THEME_NAME}"/theme.txt\" >>/etc/default/grub

    echo -e "\n Updating grub..."
    grub-mkconfig -o /boot/grub/grub.cfg

    echo -e "\n All set!"
}

# @description Set locale, timezone, and keymap
# @noargs
locale_config() {
    echo -ne "
-------------------------------------------------------------------------
                    Setup Language to US and set locale  
-------------------------------------------------------------------------
"
    sed -i '/^#en_US.UTF-8 /s/^#//' /etc/locale.gen
    locale-gen
    timedatectl --no-ask-password set-timezone "${TIMEZONE}"
    timedatectl --no-ask-password set-ntp 1
    localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"
    ln -s /usr/share/zoneinfo/"${TIMEZONE}" /etc/localtime
    # Set keymaps
    localectl --no-ask-password set-keymap "${KEYMAP}"
}

# @description Confgiure swap on low memory systems
# @noargs
low_memory_config() {
    echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <8G
-------------------------------------------------------------------------
"
    TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[ "$TOTAL_MEM" -lt 8000000 ]]; then
        # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
        mkdir -p /mnt/opt/swap  # make a dir that we can apply NOCOW to to make it btrfs-friendly.
        chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
        dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
        chmod 600 /mnt/opt/swap/swapfile # set permissions.
        chown root /mnt/opt/swap/swapfile
        mkswap /mnt/opt/swap/swapfile
        swapon /mnt/opt/swap/swapfile
        # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
        echo "/opt/swap/swapfile	none	swap	sw	0	0" >>/mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
    fi
}

# @description Update mirrorlist to improve download speeds
# @noargs
mirrorlist_update() {
    pacman -S --noconfirm --needed --color=always reflector
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    echo -ne "
-------------------------------------------------------------------------
                    Setting up mirrors for faster downloads
-------------------------------------------------------------------------
"
    reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
}

# @description Install plymouth splash
# @noargs
plymouth_config() {
    echo -ne "
  -------------------------------------------------------------------------
                Enabling (and Theming) Plymouth Boot Splash
  -------------------------------------------------------------------------
  "
    PLYMOUTH_THEMES_DIR="$HOME"/archinstaller/configs/base/usr/share/plymouth/themes
    PLYMOUTH_THEME="arch-glow" # can grab from config later if we allow selection
    mkdir -p "/usr/share/plymouth/themes"

    echo -e "Installing Plymouth theme... \n"

    cp -rf "${PLYMOUTH_THEMES_DIR}"/"${PLYMOUTH_THEME}" /usr/share/plymouth/themes
    if [[ "${FS}" == "luks" ]]; then
        sed -i 's/HOOKS=(base udev*/& plymouth/' /etc/mkinitcpio.conf             # add plymouth after base udev
        sed -i 's/HOOKS=(base udev \(.*block\) /&plymouth-/' /etc/mkinitcpio.conf # create plymouth-encrypt after block hook
    else
        sed -i 's/HOOKS=(base udev*/& plymouth/' /etc/mkinitcpio.conf # add plymouth after base udev
    fi
    plymouth-set-default-theme -R arch-glow # sets the theme and runs mkinitcpio

    echo -e "\n Plymouth theme installed"
}

# @description Configure snapper default setup
# @noargs
snapper_config() {
    echo -ne "
  -------------------------------------------------------------------------
                      Creating Snapper Config
  -------------------------------------------------------------------------
  "

    SNAPPER_CONF="$HOME"/archinstaller/configs/base/etc/snapper/configs/root
    mkdir -p /etc/snapper/configs/
    cp -rfv "${SNAPPER_CONF}" /etc/snapper/configs/

    SNAPPER_CONF_D="$HOME"/archinstaller/configs/bse/etc/conf.d/snapper
    mkdir -p /etc/conf.d/
    cp -rfv "${SNAPPER_CONF_D}" /etc/conf.d/
}
