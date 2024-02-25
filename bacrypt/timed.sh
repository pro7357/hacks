#!/usr/bin/bash
_help(){ cat <<E0F
Backup and encrypt files.

## To see stdout:
journalctl -p5 --user-unit bacrypt.service
journalctl -p5 -n15 --user
E0F
}

load_config(){
    local config_file="$HOME/.config/bacrypt/config"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        if [[ -z "$bacrypt" || -z "$key_id" || ${#base_paths[@]} -eq 0 ]]; then
            logger -p 2 "[bacrypt] Critical: Configuration not properly loaded."
            exit 1
        fi
    else
        logger -p 2 "[bacrypt] Critical: Config file not found at $config_file."
        exit 1
    fi
}

_encrypt(){
    local base="$1"
    # Backup and encrypt files newer than marker file
    find "$base" -type f -newer "$base/grass" | while read -r file; do
        name=$(sha256sum <<< "$key_id/${file#$base/}" | head -c 64)
        logger "$name $file"
        tar -P --transform="s|$base/||" -c "$file" \
            | gpg --encrypt --recipient $key_id > "$bacrypt/${base##*/}/${name::2}/${name:2}"

        # Update the marker file
        touch "$base/grass"
    done
}

_main(){
    load_config
    for p in "${base_paths[@]}"; do
        _encrypt "$p"
    done
}
_main(){
    load_config
    for p in "${base_paths[@]}"; do
        [ -d "$p" ] && _encrypt "$p"
    done
}
_main
