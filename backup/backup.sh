#!/usr/bin/bash
_help(){ cat <<E0F
Caution: Much hardcoded, therefore mostly useless to anyone but me.

Usage: backup [OPTION] ...
With no OPTION, do the basic backup

Options:
                Basic backup to external device(s)
  ssd | full    Full system backup (minus qemu related) to external ssd.
  canvio        Full system backup to external hdd.
  data          Backup data on ssd to external hdd.

  -q, --quiet    do not print anything to stdout
  -v, --verbose  increase verbosity
  -h, --help     display this help and exit
E0F
}

#- [x] move backup setting to external target
#- [x] refactor: from ~300 to ~150 lines
#- [ ] usb -more specific
#- [ ] expansion

verbose=true
debug=true
base="$HOME/hacks/backup"
source "$base/.env"

_init(){
    # Verify loading .env
    if [[ -z $uuid_ssd ]]; then
        status="Error: fail sourcing .env"
        if $verbose; then echo "$status"; fi
        exit 1
    fi
}
_init

_main(){
    if [[ -n $1 ]]; then
        if _verify $1; then
            _auto $1 $2
        fi
        return
    fi

    if _verify usb; then
        _auto kingston
    fi

    if _verify ssd; then
        _auto arch
    fi

    if _verify hdd; then
        _auto canvio
    fi
}

_auto(){
    sudo rsync -vhaHAXS --delete \
        --exclude-from="/media/$1/media/${2}rsync_exclude.list" \
        / /media/$1
}

_verify(){
    case $1 in
    nvme)
        uuid=$uuid_nvme
        uuid_boot=$uuid_boot_nvme
        target=".."
        ;;
    ssd|arch)
        uuid=$uuid_ssd
        uuid_boot=$uuid_boot_ssd
        target="arch"
        ;;
    hdd|canvio)
        uuid=$uuid_hdd
        uuid_boot=$uuid_boot_hdd
        target="canvio"
        ;;
    usb|kingston)
        uuid=$uuid_usb
        uuid_boot=$uuid_boot_usb
        target="kingston"
        ;;
    *) echo "[err] unknown: $@" && exit 1 ;;
    esac

    if [[ ! -L /dev/disk/by-uuid/$uuid ]]; then
        return 1
    fi
    # Prep boot
    if [[ ! -f /media/$target/boot/initramfs-linux-fallback.img ]]; then
        sudo mount -t ext4 /dev/disk/by-uuid/$uuid_boot /media/$target/boot
    fi

    # Verify boot
    if [[ ! -f /media/$target/boot/initramfs-linux-fallback.img ]]; then
        status="Error: fail mounting backup boot"
        if $verbose; then echo "$status"; fi
        return 2
    fi

    # Verify mounted
    if [[ ! -f /media/$target/media/rsync_exclude.list ]]; then
        status="Error: $target not found"
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
    if ! _verify nvme; then
        return 1
    fi

    case $1 in
        '') _main;;
        usb) _main usb ;;
        ssd|full) _main arch full ;;
        hdd|canvio) _main canvio ;;
        data) data_ssd2canvio ;;
        -h|--help|help) _help ;;
        *) echo "[err] unknon arg: $@" ;;
    esac
}

[[ $0 == "$BASH_SOURCE" ]] && _menu "$@"
