#!/usr/bin/env bash
#github-action genshdoc
#
# @file Configuration
# @brief This script will ask users about their prefrences like disk, file system, timezone, keyboard layout, user name, password, etc.
# @stdout Output routed to install.log
# @stderror Output routed to install.log

# @setting-header General Settings
# @setting CONFIG_FILE string[$CONFIGS_DIR/setup.conf] Location of setup.conf to be used by set_option and all subsequent scripts.
[ -f $CONFIG_FILE ] || touch -f $CONFIG_FILE # create $CONFIG_FILE if it doesn't exist

# Starting functions
background_checks
clear
logo
user_info
clear
logo
install_type
if [[ ! "$INSTALL_TYPE" == SERVER ]]; then
    clear
    logo
    aur_helper
    clear
    logo
    desktop_environment
fi
clear
logo
disk_select
clear
logo
filesystem
clear
logo
timezone
clear
logo
keymap

cat "$CONFIG_FILE"
