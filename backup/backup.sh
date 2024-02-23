#!/usr/bin/bash
_help(){ cat <<E0F
WARNING: This is outdated. A rewrite was in progress, now stalled.:
Caution: Much hardcoded, therefore mostly useless to anyone but me.

Usage: backup [OPTION] ...
With no OPTION, do the auto backup

Options:
                Auto bakup to external device(s)
  ssd           Specific backup to external ssd.
  canvio        Full system backup to external hdd.
  data          Backup data on ssd to external hdd.

  -q, --quiet    do not print anything to stdout
  -v, --verbose  increase verbosity
  -h, --help     display this help and exit
E0F
}
# [ref for absolute and relative](https://unix.stackexchange.com/questions/83394/rsync-exclude-directory-not-working)
#rsync --exclude=/home/ben/build/ --exclude=/home/ben/.ccache -arv /home home-all/   #absolute work but not recommended
#rsync --exclude=/build --exclude=/.ccache -arv /home/ben/ home/ben/                 #recommended relative

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
            _auto $1
        fi
        return
    fi

    if _verify ssd; then
        #_auto crucial
        user_h2crucial
    fi

    if _verify canvio; then
        _auto canvio
        media_nvme2canvio

        if _verify ssd; then
            data_ssd2canvio
        fi
        if _verify expansion; then
            canvio_canvio2expansion
        fi
    fi
}

_auto(){
    sudo rsync -vhaHAXS --delete \
        --exclude-from="/media/$1/media/rsync_exclude.list" \
        / /media/$1
}

_verify(){
    case $1 in
    nvme)
        uuid=$uuid_nvme
        uuid_boot=$uuid_boot_nvme
        target=".."
        ;;
    ssd|crucial)
        uuid=$uuid_ssd
        uuid_boot=$uuid_boot_ssd
        target="crucial"
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
    expansion)
        uuid=$uuid_exp
        uuid_boot=$uuid_boot_exp
        target="expansion"
        ;;

    *) echo "[err] unknown: $@" && exit 1 ;;
    esac

    if [[ ! -L /dev/disk/by-uuid/$uuid ]]; then
        return 1
    fi

    # These doesn't have boot
    if [[ $target == 'expansion' || $target == 'kingston' || $target == 'crucial']]; then
        return 0
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

user_h2crucial(){
    sudo rsync -vhaHAXS --delete \
        /home/h/ /media/crucial/home/h
}

data_ssd2canvio(){
    if [[ -d /media/crucial/home/data && \
        -d /media/canvio/home/data ]]; then
        :
    else
        status="Error: data on ssd or canvio is missing"
        if $verbose; then echo "$status"; fi
        exit
    fi

    sudo rsync -vhaHAXS --delete \
        /media/crucial/home/data/ /media/canvio/home/data
}

media_nvme2canvio(){
    if [[ -d /media/git && \
        -d /media/canvio/home/media ]]; then
        :
    else
        status="Error: data on ssd or canvio is missing"
        if $verbose; then echo "$status"; fi
        exit
    fi

    # this is the way, absolute and relative
    sudo rsync -vhaHAXS --delete \
        --include={'/download','/git','/qemu'} \
		--exclude "/*" \
        /media/ /media/canvio/home/media/
}

canvio_canvio2expansion(){
    if [[ -d /media/expansion/home/canvio && \
        -d /media/canvio/home/canvio ]]; then
        :
    else
        status="Error: folder canvio on expansion or canvio is missing"
        if $verbose; then echo "$status"; fi
        exit
    fi

    sudo rsync -vhaHAXS --delete \
        /media/canvio/home/canvio/ /media/expansion/home/canvio
}
_menu(){
    if ! _verify nvme; then
        return 1
    fi

    case $1 in
        '') _main;;
        ssd) _main crucial ;;
        hdd|canvio) _main canvio ;;
        data) data_ssd2canvio ;;
        expansion) canvio_canvio2expansion ;;
        -h|--help|help) _help ;;
        *) echo "[err] unknon arg: $@" ;;
    esac
}

[[ $0 == "$BASH_SOURCE" ]] && _menu "$@"
