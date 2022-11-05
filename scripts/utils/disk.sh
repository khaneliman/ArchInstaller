# @description Disk selection for drive to be used with installation.
diskpart() {
    echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
    Please make sure you know what you are doing because
    after formating your disk there is no way to get data back
------------------------------------------------------------------------

"

    PS3='
Select the disk to install on: '
    options=("$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}')")

    select_option $? 1 "${options[@]}"
    disk=${options[$?]%|*}

    echo -e "\n${disk%|*} selected \n"
    set_option DISK "${disk%|*}"
    if [[ "$(lsblk -n --output TYPE,ROTA | awk '$1=="disk"{print $2}')" -eq "0" ]]; then
        set_option "MOUNT_OPTION" "noatime,compress=zstd,ssd,commit=120"
    else
        set_option "MOUNT_OPTION" "noatime,compress=zstd,commit=120"
    fi

}

do_btrfs() {
    mkfs.btrfs -L "$1" "$2" -f
    mount -t btrfs "$2" "$MOUNTPOINT"

    echo "Creating subvolumes and directories"
    for x in "${SUBVOLUMES[@]}"; do
        btrfs subvolume create "$MOUNTPOINT"/"${x}" >/dev/null 2>&1
    done

    umount "$MOUNTPOINT"
    mount -o "$MOUNT_OPTIONS",subvol=@ "$2" "$MOUNTPOINT"

    for z in "${SUBVOLUMES[@]:1}"; do
        w="${z[*]//@/}"
        mkdir /mnt/"${w}"
        mount -o "$MOUNT_OPTIONS",subvol="${z}" "$2" "$MOUNTPOINT"/"${w}"
    done
}
