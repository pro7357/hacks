#!/usr/bin/bash
_help(){ cat <<E0F
Usage:
cd into target directory. execute.
   it will find all duplicate in the directory and sub-directories.
   it will keep 1 file and DELETE the rest of duplicate.

# 1. sort all the file by it size
# 2. checksum the file with the same size
# 3. keep one file, delete the rest

Note: I used these scripts just once.
      Roughly edited and put together into a single script file.
E0F
}

_main(){
    _dedup

    # Comment out below if you don't want auto delete.
    _dup_delete
}

# 1. sort all the file by it size
# 2. checksum the file with the same size
_dedup(){
    total=$(find . -type f | wc -l)
    n=0
    prev_size=""
    prev_path=""
    IFS=$'\n'
    for line in $(find . -type f -printf "%s %p\n"| sort); do
        (( n++ ))
        size=${line%% *}
        path=${line#* }
        if [[ $size == $prev_size ]]; then
            checksum=$(sha256sum $path | awk '{print $1}')
            prev_sum=$(sha256sum $prev_path | awk '{print $1}')
            if [[ $checksum == $prev_sum ]]; then
                sha256sum $path >> /tmp/duplicate.txt
                sha256sum $prev_path >> /tmp/duplicate.txt
            fi
        fi
        echo "$n/$total"
        prev_size=$size
        prev_path=$path
    done

    sort -u /tmp/duplicate.txt | tee -a dup_sorted.txt
}

# 3. keep one, delete the rest
_dup_delete(){
    IFS=$'\n'
    for line in $(< dup_sorted.txt); do
        hash=${line%% *}
        path=${line#*\./}
        if [[ $hash != $prev_hash ]]; then
            prev_hash=$hash
            echo "$path" >> /tmp/dup_keep.txt
        elif [[ $hash == $prev_hash ]]; then
            rm -v "$path"
            echo "$path" >> /tmp/dup_delete.txt
        else
            echo "error $hash $path"
            break
        fi
    done
}

_menu(){
    #see notdefault.sh for more complex options.
    if [[ $1 == '-h' || $1 == --help ]]; then
        _help
    elif [[ -z $1 ]]; then
        _main
    else
        #_main "$@"
        echo "$@"
    fi
}

[[ $0 == "$BASH_SOURCE" ]] && _menu "$@"
