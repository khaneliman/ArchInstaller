#!/usr/bin/env bash

INSTALL_STRING="sudo pacman -S --noconfirm --needed --color=always "
DESKTOP_ENV=awesome
INSTALL_TYPE=full

sed -n '/'"$INSTALL_TYPE"'/q;p' ~/Documents/github/archinstaller/packages/desktop-environments/"${DESKTOP_ENV}"/base.txt | (
    while read line; do
        # If selected installation type is FULL, skip the --END OF THE MINIMAL INSTALLATION-- line
        [[ "${line}" == '--END OF MINIMAL INSTALL--' ]] && continue
        # echo "INSTALLING: ${line}"
        # sudo pacman -S --noconfirm --needed --color=always "${line}"
        INSTALL_STRING+=" $line"
        # echo $line
        # echo $INSTALL_STRING
    done
    echo "Installing $DESKTOP_ENV"
    eval "$INSTALL_STRING"
)
