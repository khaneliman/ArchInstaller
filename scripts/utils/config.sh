# @description Choose AUR helper.
aurhelper() {
    # Let the user choose AUR helper from predefined list
    echo -ne "Please enter your desired AUR helper:\n"
    options=(paru yay picaur aura trizen pacaur none)
    select_option $? 4 "${options[@]}"
    aur_helper=${options[$?]}
    set_option AUR_HELPER $aur_helper
}

# @description Choose Desktop Environment
desktopenv() {
    # Let the user choose Desktop Enviroment from predefined list
    echo -ne "Please select your desired Desktop Enviroment:\n"
    options=($(for f in pkg-files/*.txt; do echo "$f" | sed -r "s/.+\/(.+)\..+/\1/;/pkgs/d"; done))
    select_option $? 4 "${options[@]}"
    desktop_env=${options[$?]}
    set_option DESKTOP_ENV $desktop_env
}

# @description This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
filesystem() {
    echo -ne "
Please Select your file system for both boot and root
"
    options=("btrfs" "ext4" "luks" "exit")
    select_option $? 1 "${options[@]}"

    case $? in
    0)
        set_btrfs
        set_option FS btrfs
        ;;
    1) set_option FS ext4 ;;
    2)
        set_password "LUKS_PASSWORD"
        set_option FS luks
        ;;
    3) exit ;;
    *)
        echo "Wrong option please select again"
        filesystem
        ;;
    esac
}

# @description Choose whether to do full or minimal installation.
installtype() {
    echo -ne "Please select type of installation:\n\n
  Full install: Installs full featured desktop enviroment, with added apps and themes needed for everyday use\n
  Minimal Install: Installs only apps few selected apps to get you started\n"
    options=(FULL MINIMAL)
    select_option $? 4 "${options[@]}"
    install_type=${options[$?]}
    set_option INSTALL_TYPE $install_type
}

# @description Set user's keyboard mapping.
keymap() {
    echo -ne "
Please select key board layout from this list"
    # These are default key maps as presented in official arch repo archinstall
    options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)

    select_option $? 4 "${options[@]}"
    keymap=${options[$?]}

    echo -ne "Your key boards layout: ${keymap} \n"
    set_option KEYMAP $keymap
}

set_btrfs() {
    echo "Please enter your btrfs subvolumes separated by space"
    echo "usualy they start with @."
    echo "like @home, [defaults are @home, @var, @tmp, @.snapshots]"
    echo " "
    read -r -p "press enter to use default: " -a ARR
    if [[ -z "${ARR[*]}" ]]; then
        set_option "SUBVOLUMES" "(@ @home @var @tmp @.snapshots)"
    else
        NAMES=(@)
        for i in "${ARR[@]}"; do
            if [[ $i =~ [@] ]]; then
                NAMES+=("$i")
            else
                NAMES+=(@"${i}")
            fi
        done
        IFS=" " read -r -a SUBS <<<"$(tr ' ' '\n' <<<"${NAMES[@]}" | awk '!x[$0]++' | tr '\n' ' ')"
        set_option "SUBVOLUMES" "${SUBS[*]}"
        set_option "MOUNTPOINT" "/mnt"
    fi
}

set_password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        set_option "$1" "$PASSWORD1"
    else
        echo -ne "ERROR! Passwords do not match. \n"
        set_password
    fi
}

# @description Detects and sets timezone.
timezone() {
    # Added this from arch wiki https://wiki.archlinux.org/title/System_time
    time_zone="$(curl --fail https://ipapi.co/timezone)"
    echo -ne "
System detected your timezone to be '$time_zone' \n"
    echo -ne "Is this correct?
"
    options=("Yes" "No")
    select_option $? 1 "${options[@]}"

    case ${options[$?]} in
    y | Y | yes | Yes | YES)
        echo "${time_zone} set as timezone"
        set_option TIMEZONE $time_zone
        ;;
    n | N | no | NO | No)
        echo "Please enter your desired timezone e.g. Europe/London :"
        read new_timezone
        echo "${new_timezone} set as timezone"
        set_option TIMEZONE $new_timezone
        ;;
    *)
        echo "Wrong option. Try again"
        timezone
        ;;
    esac
}

# @description Gather username and password to be used for installation.
userinfo() {
    read -p "Please enter your username: " username
    set_option USERNAME ${username,,} # convert to lower case as in issue #109
    set_password "PASSWORD"
    read -rep "Please enter your hostname: " nameofmachine
    set_option NAME_OF_MACHINE $nameofmachine
}
