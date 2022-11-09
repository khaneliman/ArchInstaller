#!/usr/bin/env bash
#github-action genshdoc
#
# @file Software Install
# @brief Contains the functions to install software
# @stdout Output routed to install.log
# @stderror Output routed to install.log

arch_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
    pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed --color=always
}

# @description Installs software from the AUR
# @noargs
aur_helper_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing AUR Software  
-------------------------------------------------------------------------
"
    if [[ ! "$AUR_HELPER" == none ]]; then
        git clone https://aur.archlinux.org/"$AUR_HELPER".git ~/"$AUR_HELPER"
        cd ~/"$AUR_HELPER" || return
        makepkg -si --noconfirm
        # sed $INSTALL_TYPE is using install type to check for MINIMAL installation, if it's true, stop
        # stop the script and move on, not installing any more packages below that line
        sed -n '/'"$INSTALL_TYPE"'/q;p' ~/archinstaller/packages/aur.txt | while read line; do
            [[ "${line}" == '--END OF MINIMAL INSTALL--' ]] && continue
            echo "INSTALLING: ${line}"
            "$AUR_HELPER" -S --noconfirm --needed --color=always "${line}"
        done

        sed -n '/'"$INSTALL_TYPE"'/q;p' ~/archinstaller/packages/desktop-environments/aur/"$DESKTOP_ENV".txt | while read line; do
            [[ "${line}" == '--END OF MINIMAL INSTALL--' ]] && continue
            echo "INSTALLING: ${line}"
            "$AUR_HELPER" -S --noconfirm --needed --color=always "${line}"
        done
    fi
}

# @description Installs base arch linux system
# @noargs
base_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing Base System  
-------------------------------------------------------------------------
"
    # sed $INSTALL_TYPE is using install type to check for MINIMAL installation, if it's true, stop
    # stop the script and move on, not installing any more packages below that line
    if [[ ! "$INSTALL_TYPE" == SERVER ]]; then
        INSTALL_STRING="pacman -S --noconfirm --needed --color=always "

        sed -n '/'"$INSTALL_TYPE"'/q;p' "$HOME"/archinstaller/packages/pacman.txt | (
            while read line; do
                # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
                [[ "${line}" == '--END OF MINIMAL INSTALL--' ]] && continue
                INSTALL_STRING+=" $line"
            done

            echo "Installing base packages"
            eval "$INSTALL_STRING"
        )
    fi
}

# @description Install bootloader
# @noargs
bootloader_install() {
    echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
    if [[ ! -d "/sys/firmware/efi" ]]; then
        grub-install --boot-directory=/mnt/boot "${DISK}"
    else
        pacstrap /mnt efibootmgr --noconfirm --needed --color=always
    fi

}

# @description Installs btrfs packages
# @noargs
btrfs_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing Btrfs Packages
-------------------------------------------------------------------------
"
    if [[ ! "$FS" == btrfs ]]; then
        INSTALL_STRING="pacman -S --noconfirm --needed --color=always "

        # sed $INSTALL_TYPE is using install type to check for MINIMAL installation, if it's true, stop
        # stop the script and move on, not installing any more packages below that line
        sed -n '/'"$INSTALL_TYPE"'/q;p' "$HOME"/archinstaller/packages/btrfs.txt | (
            while read line; do
                # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
                [[ "${line}" == '--END OF MINIMAL INSTALL--' ]] && continue
                INSTALL_STRING+=" $line"
            done

            echo "Installing Btrfs Packages"
            eval "$INSTALL_STRING"
        )
    fi
}

# @description Installs desktop environment packages from base repositories
# @noargs
desktop_environment_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing Desktop Environment Software  
-------------------------------------------------------------------------
"
    INSTALL_STRING="sudo pacman -S --noconfirm --needed --color=always "
    sed -n '/'"$INSTALL_TYPE"'/q;p' ~/archinstaller/packages/desktop-environments/"${DESKTOP_ENV}".txt | (
        while read line; do
            # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
            [[ "${line}" == '--END OF MINIMAL INSTALL--' ]] && continue
            INSTALL_STRING+=" $line"
        done

        echo "Installing $DESKTOP_ENV"
        eval "$INSTALL_STRING"
    )
}

# @description Enable essential services
# @noargs
essential_services() {
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
}

# @description Installs graphics drivers depending on detected gpu
# @noargs
graphics_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing Graphics Drivers
-------------------------------------------------------------------------
"
    # Graphics Drivers find and install
    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<<"${gpu_type}"; then
        pacman -S --noconfirm --needed --color=always nvidia-dkms nvidia-settings
        nvidia-xconfig
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        pacman -S --noconfirm --needed --color=always xf86-video-amdgpu
    elif grep -E "Integrated Graphics Controller|Intel Corporation UHD" <<<"${gpu_type}"; then
        pacman -S --noconfirm --needed --color=always libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    else
        echo "No graphics drivers required"
    fi
}

# @description Installs cpu microcode depending on detected cpu
# @noargs
microcode_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing Microcode
-------------------------------------------------------------------------
"
    # determine processor type and install microcode
    proc_type=$(lscpu)
    if grep -E "GenuineIntel" <<<"${proc_type}"; then
        echo "Installing Intel microcode"
        pacman -S --noconfirm --needed --color=always intel-ucode
    elif grep -E "AuthenticAMD" <<<"${proc_type}"; then
        echo "Installing AMD microcode"
        pacman -S --noconfirm --needed --color=always amd-ucode
    fi
}

# @description Installs network management software
# @noargs
network_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Network Setup 
-------------------------------------------------------------------------
"
    pacman -S --noconfirm --needed --color=always networkmanager dhclient networkmanager-openvpn
    systemctl enable --now NetworkManager
}

# @description Perform desktop environment specific theming
# @noargs
user_theming() {
    echo -ne "
-------------------------------------------------------------------------
                    Theming Desktop Environment  
-------------------------------------------------------------------------
"
    # cd ~
    # mkdir "$HOME/.cache"
    # touch "$HOME/.cache/zshhistory"
    # git clone "https://github.com/ChrisTitusTech/zsh"
    # git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    # ln -s "$HOME/zsh/.zshrc" ~/.zshrc

    # Theming DE if user chose FULL installation
    if [[ "$INSTALL_TYPE" == "FULL" ]]; then
        if [[ "$DESKTOP_ENV" == "kde" ]]; then
            cp -r ~/archinstaller/configs/kde/home/. ~/
            pip install konsave
            konsave -i ~/archinstaller/configs/kde/kde.knsv
            sleep 1
            konsave -a kde
        elif [[ "$DESKTOP_ENV" == "openbox" ]]; then
            git clone https://github.com/stojshic/dotfiles-openbox ~/dotfiles-openbox
            ./dotfiles-openbox/install-titus.sh
        elif [[ "$DESKTOP_ENV" == "awesome" ]]; then
            git submodule update --init
            cp -r ~/archinstaller/configs/awesome/home/. ~/
            sudo cp -r ~/archinstaller/configs/etc/xdg/awesome /etc/xdg/awesome
        else
            echo -e "No theming setup for $DESKTOP_ENV"
        fi
    fi
}
