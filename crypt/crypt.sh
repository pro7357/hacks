#!/usr/bin/bash
_help(){ cat <<E0F
Usage: $alias_name [OPTION]... [COMMAND]
Command:
  open          Decrypt
  save          Encrypt
  delete        Delete plain folder
  autosave      Run autosave. default is already running every 10minute.
  close         Close autosave
Option:
  -h, --help    Display this usage message and exit.
  -d, --debug   Debugging.
  -v, --verbose No effect. This is the default.
  -q, --quiet   do not print anything to stdout. only stderr.
Status:
- [x] .env
- [ ] update readme
E0F
}

base="$HOME/hacks/crypt"
source "$base/.env"

_env_variable(){
    # Mostly for readability
    public_key_id=$public_key_id
    dry=$dry
    alias_name=$alias_name
    verbose=$verbose
    debug=$debug

    # default folder name is .crypt
    folder_name=$folder_name
    encrypted_folder="$encrypted_folder"
    unit=$unit

    # Variable for plain, decrypted stuff
    plain_folder="$plain_folder"
    plain_unit=$plain_unit

    # Autosave frequency in second. 0 to disable autosave
    # Default == 600 == 600 seconds == 10 minutes"
    saving_timer=$saving_timer
    # File to open after decryption.
    openfile=$openfile

    # Verify
    if [[ -z $folder_name ]]; then
        status="Error: fail sourcing .env"
        if $verbose; then echo "$status"; fi
        exit 1
    fi
    if [[ ! -e $encrypted_folder ]]; then
        status="Error: the encrypted folder is missing"
        if $verbose; then echo "$status"; fi
        exit 2
    fi
}
_env_variable

_main(){
    if [[ -e /tmp/$folder_name ]]; then
        # will save plain files as encrypted one
        _encrypt
        return
    fi

    _decrypt
    _autosave
    _openfile
}

_openfile(){
    if [[ -n $openfile && -f $plain_folder/$openfile ]]; then
        cd $plain_folder
        nvim $openfile
    fi
}

_encrypt(){
    ## safety check
    _safety_check

    ## New folder
    find /tmp/$folder_name -type d -newer /tmp/$folder_name/updatemark | \
        while read -r folder; do
            mkdir -p "$encrypted_folder/${folder:$plain_unit}"

            status="Found new folder: ${folder:$plain_unit}"
            if $verbose; then echo "$status"; fi
        done

    ## Encrypt
    find /tmp/$folder_name -type f -newer /tmp/$folder_name/updatemark | \
        gpg --multifile -eu $public_key_id -r $public_key_id

    ## Update Crypt
    find /tmp/$folder_name -type f -iname '*.gpg' | \
        while read -r file; do
            status="Update file: ${file:$plain_unit}"
            if $verbose; then echo "$status"; fi

            mv "$file" "$encrypted_folder/${file:$plain_unit}"
        done

    ## handle deletion
    find $encrypted_folder | \
        while read -r all; do
            a=${all:$unit}
            if [[ ! -e "/tmp/$folder_name/${a%.gpg}" ]]; then
                echo "not exist: /tmp/$folder_name/${a%.gpg}"
                if $dry; then
                    echo "Removing recursively $all"
                else
                    rm -dr "$all"
                fi
                status="Deleted: ${all:$unit}"
                if $verbose; then echo "$status"; fi
            fi
        done

    date +'%Y%m%d_%H:%M:%S' >> /tmp/$folder_name/updatemark
    #status="Done updating"
    #if $verbose; then echo "$status"; fi
}

_autosave(){
    if (( saving_timer == 0 )); then
        status="autosave is disabled."
        if $verbose; then echo "$status"; fi
        return
    fi
    if (( $(pgrep crypt.sh | wc -l) < 1 )); then
        $base/crypt.sh autosave > /dev/null &
    else
        status="autosave seems to be already running. pls verify"
        if $verbose; then echo "$status"; fi
    fi
}

_auto_encrypt(){
    status="running autosave"
    if $verbose; then echo "$status"; fi

    while true; do
        _encrypt
        sleep  $saving_timer
    done
}

_decrypt(){
    # copy to plain_folder
    if [[ -e /tmp/$folder_name ]]; then
        echo "/tmp/$folder_name already exist"
        echo "delete or move it first to continue"
        exit
    fi
    cp -r "$encrypted_folder" "/tmp/$folder_name"

    # decrypt
    echo "Caution: DO NOT continue re-enter phrase if entered wrong once"
    echo "         simply cancel ctrl+c, and restart again."
    # because multifile will skip the file with the wrong phrase.

    find /tmp/$folder_name -iname '*.gpg' | \
        gpg --multifile --decrypt

    #remove encrypted files
    find /tmp/$folder_name -iname '*.gpg' -delete

    # create a new mark
    date +'%Y%m%d_%H:%M:%S' > /tmp/$folder_name/updatemark
}

_delete(){
    if (( $(pgrep crypt.sh | wc -l) >= 1 )); then
        status="Error: Some $alias_name still running. close it first"
        if $verbose; then echo "$status"; fi

        return
    fi

    rm -r /tmp/$folder_name
}

_close(){
    pkill crypt.sh
    if (( $(pgrep crypt.sh | wc -l) >= 1 )); then
        status="Fail to close $alias_name."
        if $verbose; then echo "$status"; fi
    fi
}

_safety_check(){
    # this will verify specific file(s) exist before continue
    # hardcoded. pls ask me to fix this.
    if [[ ! -e /tmp/$folder_name ]]; then
        status="Error: Missing /tmp/$folder_name . Try open again"
        if $verbose; then echo "$status"; fi
        exit 4
    fi
    if [[ ! -f /tmp/$folder_name/Vim.md ]]; then
        status="WARNING: Failed safety check. \n \
         recommended to delete and open again"
        if $verbose; then echo -e "$status"; fi
        exit 4
    fi
    if [[ ! -f /tmp/$folder_name/Home.md ]]; then
        status="WARNING: Failed safety check. \n \
         recommended to delete and open again"
        if $verbose; then echo -e "$status"; fi
        exit 4
    fi
}

_menu(){
    if [[ $1 == '-h' || $1 == --help ]]; then
        _help
    elif [[ $1 == 'open' || $1 == 'decrypt' ]]; then
        _decrypt
    elif [[ $1 == 'save' || $1 == 'encrypt' ]]; then
        _encrypt
    elif [[ $1 == 'autosave' ]]; then
        _auto_encrypt
    elif [[ $1 == 'delete' ]]; then
        _delete
    elif [[ $1 == 'close' || $1 == 'exit' ]]; then
        _close
    elif [[ -z $1 ]]; then
        _main
    else
        #_main "$@"
        echo "$@"
    fi
}

[[ $0 == "$BASH_SOURCE" ]] && _menu "$@"
