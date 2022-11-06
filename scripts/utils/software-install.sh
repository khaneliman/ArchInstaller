#!/usr/bin/env bash
#github-action genshdoc
#
# @file Software Install
# @brief Contains the functions to install software
# @stdout Output routed to install.log
# @stderror Output routed to install.log

# @description Installs software from the AUR
# @noargs
aur_helper_install() {
    echo -ne "
-------------------------------------------------------------------------
                    Installing AUR Software  
-------------------------------------------------------------------------
"
    if [[ ! $AUR_HELPER == none ]]; then
        cd ~
        git clone "https://aur.archlinux.org/$AUR_HELPER.git"
        cd ~/$AUR_HELPER
        makepkg -si --noconfirm
        # sed $INSTALL_TYPE is using install type to check for MINIMAL installation, if it's true, stop
        # stop the script and move on, not installing any more packages below that line
        sed -n '/'$INSTALL_TYPE'/q;p' ~/ArchInstaller/pkg-files/aur-pkgs.txt | while read line; do
            if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
                # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
                continue
            fi
            echo "INSTALLING: ${line}"
            $AUR_HELPER -S --noconfirm --needed --color=always ${line}
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
    if [[ ! $INSTALL_TYPE == SERVER ]]; then
        sed -n '/'$INSTALL_TYPE'/q;p' $HOME/ArchInstaller/pkg-files/pacman-pkgs.txt | while read line; do
            if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
                # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
                continue
            fi
            echo "INSTALLING: ${line}"
            sudo pacman -S --noconfirm --needed --color=always ${line}
        done
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
    sed -n '/'$INSTALL_TYPE'/q;p' ~/ArchInstaller/pkg-files/${DESKTOP_ENV}.txt | while read line; do
        if [[ ${line} == '--END OF MINIMAL INSTALL--' ]]; then
            # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
            continue
        fi
        echo "INSTALLING: ${line}"
        sudo pacman -S --noconfirm --needed --color=always ${line}
    done
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
    if grep -E "NVIDIA|GeForce" <<<${gpu_type}; then
        pacman -S --noconfirm --needed --color=always nvidia
        nvidia-xconfig
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        pacman -S --noconfirm --needed --color=always xf86-video-amdgpu
    elif grep -E "Integrated Graphics Controller" <<<${gpu_type}; then
        pacman -S --noconfirm --needed --color=always libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    elif grep -E "Intel Corporation UHD" <<<${gpu_type}; then
        pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
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
    if grep -E "GenuineIntel" <<<${proc_type}; then
        echo "Installing Intel microcode"
        pacman -S --noconfirm --needed --color=always intel-ucode
        proc_ucode=intel-ucode.img
    elif grep -E "AuthenticAMD" <<<${proc_type}; then
        echo "Installing AMD microcode"
        pacman -S --noconfirm --needed --color=always amd-ucode
        proc_ucode=amd-ucode.img
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
    pacman -S --noconfirm --needed --color=always networkmanager dhclient
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
    if [[ $INSTALL_TYPE == "FULL" ]]; then
        if [[ $DESKTOP_ENV == "kde" ]]; then
            cp -r ~/ArchInstaller/configs/.config/* ~/.config/
            pip install konsave
            konsave -i ~/ArchInstaller/configs/kde.knsv
            sleep 1
            konsave -a kde
        elif [[ $DESKTOP_ENV == "openbox" ]]; then
            cd ~
            git clone https://github.com/stojshic/dotfiles-openbox
            ./dotfiles-openbox/install-titus.sh
        fi
    fi
}
