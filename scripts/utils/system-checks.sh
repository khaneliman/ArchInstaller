#!/usr/bin/env bash
#github-action genshdoc
#
# @file System Checks
# @brief Contains the functions used to perform various checks to safely run program
# @stdout Output routed to install.log
# @stderror Output routed to install.log

# @description Check if script is being ran in an arch linux distro
# @noargs
arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        echo -ne "ERROR! This script must be run in Arch Linux!\n"
        exit 0
    fi
}

# @description Check if script is run with root
# @noargs
root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -ne "ERROR! This script must be run under the 'root' user!\n"
        exit 0
    fi
}

# @description Checks if script run inside docker container
# @noargs
docker_check() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    elif [[ -f /.dockerenv ]]; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    fi
}

# @description Checks if pacman lock exists
# @noargs
pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo "ERROR! Pacman is blocked."
        echo -ne "If not running remove /var/lib/pacman/db.lck.\n"
        exit 0
    fi
}

# @description Run all checks necessary before running script
# @noargs
background_checks() {
    root_check
    arch_check
    pacman_check
    docker_check
}
