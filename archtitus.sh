#!/bin/bash
#github-action genshdoc
#
# @file ArchTitus
# @brief Entrance script that launches children scripts for each phase of installation.
# shellcheck disable=SC1090,SC1091

# Find the name of the folder the scripts are in
set -a
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR"/scripts
CONFIGS_DIR="$SCRIPT_DIR"/configs
set +a

CONFIG_FILE="$CONFIGS_DIR"/setup.conf
LOG_FILE="$CONFIGS_DIR"/main.log

[[ -f "$LOG_FILE" ]] && rm -f "$LOG_FILE"

# source utility scripts
for filename in "$SCRIPTS"/utils/*.sh; do
    [ -e "$filename" ] || continue
    source "$filename"
done

clear
logo
echo -ne "
                Scripts are in directory named ArchTitus
"
. "$SCRIPTS_DIR"/startup.sh
source_file "$CONFIG_FILE"
sequence |& tee "$LOG_FILE"
logo
echo -ne "
                Done - Please Eject Install Media and Reboot
"
end
