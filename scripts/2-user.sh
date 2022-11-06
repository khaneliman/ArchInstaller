#!/usr/bin/env bash
#github-action genshdoc
#
# @file User
# @brief User customizations and AUR package installation.
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

desktop_environment_install

aur_helper_install

user_theming

echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 3-post-setup.sh
-------------------------------------------------------------------------
"
exit
