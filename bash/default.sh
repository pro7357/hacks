#!/usr/bin/bash
_help(){ cat <<E0F
Usage: default [OPTION]... [FILE]...
Do default thing to FILE(s). Output to standard output.

With no FILE, or when FILE is -, read standard input.

  -q, --quiet    do not print anything to stdout
  -v, --verbose  increase verbosity
  -h, --help     display this help and exit
E0F
}

_main(){
    echo "This is main"
}

_menu(){
    #see notdefault.sh for more complex options.
    if [[ $1 == '-h' || $1 == --help ]]; then
        _help
    elif [[ "${@:(-1)}" == '-' ]]; then
        echo "see _stdin in notdefault.sh"
    elif [[ -z $1 ]]; then
        #_main "$(date +%F)"
        _main
    else
        #_main "$@"
        echo "$@"
    fi
}
_source(){ :;}
[[ $0 == "$BASH_SOURCE" ]] && _menu "$@" || _source
