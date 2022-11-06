#!/usr/bin/env bash
#github-action genshdoc
#
# @file User
# @brief User customizations and AUR package installation.
# @stdout Output routed to install.log
# @stderror Output routed to install.log

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
