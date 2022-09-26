#!/usr/bin/bash
_help(){ cat <<E0F
Caution: Much hardcoded, therefore mostly useless to anyone but me.

Usage: backup [OPTION] ...
With no OPTION, do the basic backup

Options:
                Basic backup to ssd or/and pendrive.
  ssd           Mostly full system backup to external ssd.
  canvio        Full system backup to external hdd.
  data          Backup data on ssd to external hdd.

  -q, --quiet    do not print anything to stdout
  -v, --verbose  increase verbosity
  -h, --help     display this help and exit

Status: This is an ongoing remake.
        Also experimenting with .env
- [x] Basic backup on usb pendrive
- [x] move backup setting on external/target -done on usb
- [ ] refactor the rest
E0F
}

verbose=true
debug=true
base="$HOME/hacks/backup"
source "$base/.env"

_init(){
    # Mostly for readablity
    uuid_nvme=$uuid_nvme
    uuid_boot_nvme=$uuid_boot_nvme
    uuid_ssd=$uuid_ssd
    uuid_boot_ssd=$uuid_boot_ssd
    uuid_hdd=$uuid_hdd
    uuid_boot_hdd=$uuid_boot_hdd
    uuid_usb=$uuid_usb
    uuid_boot_usb=$uuid_boot_usb

    # Verify loading .env
    if [[ -z $uuid_ssd ]]; then
        status="Error: fail sourcing .env"
        if $verbose; then echo "$status"; fi
        exit 1
    fi
}
_init

_main(){
    if verify_usb; then
        min_system2usb
    fi

    basic_system2ssd
}

#https://wiki.archlinux.org/title/Rsync#As_a_backup_utility
# /dev/*            # only dir "dev" and not content. dev will be populated on boot.
# "/home/data"      # will totally ignore /home/data
#        --include "/home/private" \    # include first
#        --exclude "/home/*" \          # then exclude

basic_system2ssd(){
    verify_ssd

    sudo rsync -vhaHAXS --delete \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
        --exclude={"/etc/fstab","/etc/default/grub","/boot/grub/grub.cfg"} \
        --exclude={"/home/data","/home/backup","/home/expansion"} \
        --exclude={"/home/*/.data","/home/*/.tmp","/home/*/tmp"} \
        --exclude={"/home/d/qemu","/var/lib/libvirt/images"} \
        --exclude={"/home/*/.cache/chromium","/home/*/.config/chromium","/home/d/.local/opt/tor-browser"} \
        --exclude "/home/*/.cache/mesa_shader_cache" \
        --exclude="/home/d/video" \
        / /media/arch
}

# full except qemu image
full_system2ssd(){
    verify_ssd

    sudo rsync -vhaHAXS --delete \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
        --exclude={"/etc/fstab","/etc/default/grub","/boot/grub/grub.cfg"} \
        --exclude={"/home/data","/home/backup","/home/expansion"} \
        --exclude={"/home/d/qemu","/var/lib/libvirt/images"} \
        / /media/arch
}

full_system2canvio(){
    verify_hdd

    sudo rsync -vhaHAXS --delete \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
        --exclude={"/etc/fstab","/etc/default/grub","/boot/grub/grub.cfg"} \
        --exclude={"/home/data","/home/backup","/home/expansion"} \
        / /media/canvio
}

min_system2usb(){

    sudo rsync -vhaHAXS --delete \
        --exclude-from="/media/kingston/media/rsync_exclude.list" \
        / /media/kingston
}

verify_nvme(){
    if [[ -e /dev/disk/by-uuid/$uuid_nvme && \
        -f /home/d/.bashrc ]]; then
        return 0
    else
        status="Error: nvme not found"
        if $verbose; then echo "$status"; fi
        exit 3
    fi

    # Prep boot
    if [[ ! -f /boot/initramfs-linux-fallback.img ]]; then
        sudo mount -t ext4 /dev/disk/by-uuid/$uuid_boot_nvme /boot
    fi

    # Verify boot
    if [[ ! -f /boot/initramfs-linux-fallback.img ]]; then
        status="Error: fail mounting backup boot"
        if $verbose; then echo "$status"; fi
        exit 2
    fi
}

verify_ssd(){
    # Full system backup which is bootable on external ssd.
    if [[ -e /dev/disk/by-uuid/$uuid_ssd && \
        -f /media/arch/home/d/.bashrc ]]; then
        :
    else
        status="Error: ssd not found"
        if $verbose; then echo "$status"; fi
        exit 3
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

verify_hdd(){
    if [[ -e /dev/disk/by-uuid/$uuid_hhd && \
        -f /media/canvio/home/d/.bashrc ]]; then
        :
    else
        status="Error: external hdd not found"
        if $verbose; then echo "$status"; fi
        exit 3
    fi

    # Prep boot
    if [[ ! -f /media/canvio/boot/initramfs-linux-fallback.img ]]; then
        sudo mount -t ext4 /dev/disk/by-uuid/$uuid_boot_hdd /media/canvio/boot
    fi

    # Verify boot
    if [[ ! -f /media/canvio/boot/initramfs-linux-fallback.img ]]; then
        status="Error: fail mounting backup boot"
        if $verbose; then echo "$status"; fi
        exit 2
    fi
}

verify_usb(){
    if [[ ! -e /dev/disk/by-uuid/$uuid_usb ]]; then
        echo "err"
        return 1
    fi
    # Prep boot
    if [[ ! -f /media/kingston/boot/initramfs-linux-fallback.img ]]; then
        sudo mount -t ext4 /dev/disk/by-uuid/$uuid_boot_usb /media/kingston/boot
    fi

    # Verify boot
    if [[ ! -f /media/kingston/boot/initramfs-linux-fallback.img ]]; then
        status="Error: fail mounting backup boot"
        if $verbose; then echo "$status"; fi
        return 2
    fi

    # Verify mounted
    if [[ ! -f /media/kingston/media/rsync_exclude.list ]]; then
        status="Error: external usb not found"
        if $verbose; then echo "$status"; fi
        return 3
    fi

    return 0
}

data_ssd2canvio(){
    if [[ -d /media/arch/home/data && \
        -d /media/canvio/home/data ]]; then
        :
    else
        status="Error: data on ssd or canvio is missing"
        if $verbose; then echo "$status"; fi
        exit
    fi

    sudo rsync -vhaHAXS --delete \
        /media/arch/home/data/ /media/canvio/home/data
}

_menu(){
    verify_nvme

    if [[ $1 == '-h' || $1 == --help ]]; then
        _help
    elif [[ -z $1 ]]; then
        _main
    elif [[ $1 == 'ssd' || $1 == 'full' ]]; then
        full_system2ssd
    elif [[ $1 == 'canvio' ]]; then
        full_system2canvio
    elif [[ $1 == 'usb' ]]; then
        if verify_usb; then
            min_system2usb
        fi
    elif [[ $1 == 'data' ]]; then
        data_ssd2canvio
    else
        echo "unknown: $@"
    fi
}

[[ $0 == "$BASH_SOURCE" ]] && _menu "$@"
