#!/usr/bin/bash
_help(){ cat <<E0F
Caution: Much hardcoded, therefore mostly useless to anyone but me.

Usage: backup [OPTION]... [COMMAND]...
With no OPTION or COMMAND, do the basic backup

Commands:
  auto      Automatically choose backup options based on available media.
  all       Attempt to do all backup to all media.
  basic     Basic backup Bash, Crypt and .gnupg files to boot partition
            Opional to usb drive or expansion if available.
  home      Mostly /home/*
  unmount   Unmount and poweroff USB pendrive.

Options:
  -q, --quiet    do not print anything to stdout
  -v, --verbose  increase verbosity
  -h, --help     display this help and exit

Status: This is an ongoing remake.
        Also experimenting with .env
- [x] Full system backup to live ssd
- [ ] Basic backup, to be run daily
E0F
}

verbose=true
debug=true
base="$HOME/hacks/backup"
source "$base/.env"

_init(){
    # Mostly for readablity
    uuid_ssd=$uuid_ssd
    uuid_boot_ssd=$uuid_boot_ssd
    uuid_nvme=$uuid_nvme

    # Verify
    if [[ -z $uuid_ssd ]]; then
        status="Error: fail sourcing .env"
        if $verbose; then echo "$status"; fi
        exit 1
    fi

    # Prep boot
    if [[ ! -f /media/arch/boot/initramfs-linux-fallback.img ]]; then
        sudo mount -t ext4 /dev/disk/by-uuid/$uuid_boot_ssd /media/arch/boot
    fi

    # Verify boot
    if [[ ! -f /media/arch/boot/initramfs-linux-fallback.img ]]; then
        status="Error: fail mounting backup boot"
        if $verbose; then echo "$status"; fi
        exit 2
    fi

}
_init

_main(){
    verify_ssd

    if [[ $1 == 'full' ]]; then
        full_system
    elif [[ -z $1 ]]; then
        basic_backup
    else
        status="Unknown input: $@"
        if $verbose; then echo "$status"; fi
    fi
}

basic_backup(){
    sudo rsync -vaHAXS --delete \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
        --exclude={"/etc/fstab","/etc/default/grub","/boot/grub/grub.cfg"} \
        --exclude={"/home/*/.data","/home/*/.tmp"} \
        --exclude={"/home/d/music/*","/home/d/musics/*"} \
        --exclude={"/home/*/.cache/chromium","/home/*/.config/chromium","/home/d/.local/opt/tor-browser/*"} \
        --exclude "/home/*/.cache/mesa_shader_cache" \
        / /media/arch
}

full_system(){
    sudo rsync -vaHAXS --delete \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
        --exclude={"/etc/fstab","/etc/default/grub","/boot/grub/grub.cfg"} \
        --exclude={"/home/*/.data","/home/*/.tmp"} \
        --exclude={"/home/d/music/*","/home/d/musics/*"} \
        / /media/arch
}

verify_ssd(){
    # Full system backup which is bootable on external ssd.
    if [[ -e /dev/disk/by-uuid/$uuid_ssd && \
        -f /media/arch/home/d/.bashrc && \
        -e /dev/disk/by-uuid/$uuid_nvme && \
        -f /home/d/.bashrc ]]
    then
        return 0
    else
        status="Error: ssd not found"
        if $verbose; then echo "$status"; fi
        exit 3
    fi
}


_menu(){
    #see notdefault.sh for more complex options.
    if [[ $1 == '-h' || $1 == --help ]]; then
        _help
    elif [[ "${@:(-1)}" == '-' ]]; then
        echo "see _stdin in notdefault.sh"
    elif [[ -z $1 ]]; then
        _main
    else
        _main "$@"
    fi
}

[[ $0 == "$BASH_SOURCE" ]] && _menu "$@"
