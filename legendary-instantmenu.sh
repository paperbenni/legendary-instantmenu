#!/bin/bash

# simple instantmenu interface for legendary

checkcommand() {
    command -v "$1" &>/dev/null || {
        echo "$1 not found, please install $1"
        exit 1
    }
}

checkcommand legendary
checkcommand fzf
checkcommand imenu

export USECLIMENU=true
CACHEDIR="$HOME/.cache/legendary-instantmenu"

checkcache() {
    if ! [ -e "$CACHEDIR"/gamelist ]; then
        return 1
    fi
}

gencache() {
    [ -e "$CACHEDIR" ] || mkdir -p "$CACHEDIR"
    GAMELIST="$(legendary list-games)"
    if ! grep -iq "available games" <<<"$GAMELIST"; then
        {
            echo "failed to get game list"
            echo "please run legendary auth in a terminal"
        } | imenu -M
        exit 1
    fi

    echo "$GAMELIST" | grep ' *[+*]' | grep 'App name' |
        sed 's/| Version: .*)$//g' |
        sed 's/^ *[+*] *//g' | sed 's/(App name:/;:;/g' >"$CACHEDIR"/gamelist
}

selectgame() {
    if ! checkcache; then
        gencache || exit 1
    fi

    GAMESELECTION="$(
        {
            echo "Cancel"
            cat "$CACHEDIR/gamelist"
        } | imenu -l
    )"
    [ -z "$GAMESELECTION" ] && exit
    if [ "$GAMESELECTION" = "quit" ]; then
        echo "quiting launcher"
        exit
    fi
    GAMEID="$(grep -o ';:;.*' <<<"$GAMESELECTION" | sed 's/;:; *//g' | sed 's/ *//g')"
    [ -z "$GAMEID" ] && exit
    gencache &
    legendary install "$GAMEID"
    legendary launch "$GAMEID"
}

selectgame
