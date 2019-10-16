#!/usr/bin/env bash
#
# Bash script to interact with rclone and a preconfigured
# remote through the argument actions available below:
#
# usage: rcloud {option} [input] [output] [-s]
# 
# options:
#   sync (y)      sync remote name and exit
#   copy (cp)     a specific file to remote
#   link (l)      get share link to file or folder
#   mount (m)     start sync and mount as folder
#   umount (u)    stop rclone remote syncing
#   remount (r)   try and refresh remote sync
#   status (s)    status for rclone remote mount
#   check (c)     differences between local and remote
#
# This is of course NOT intended as a desktop cloud solution.

#################################################

# required user settings

REMOTE=""
# name of remote as in rclone

DIR=""
# path for syncing files

#################################################

# define vars

ARG="$1"        # argument to execute
FILE="$2"       # file or folder to upload
FOLDER="$3"     # path to upload file or folder to

[[ "$FOLDER" = "" ]] &&
FOLDER="share" # default

[[ "$FOLDER" = "/" ]] &&
FOLDER="" # copy to root

#################################################

# define functions

function help {
    head -n 16 "$0" | tail -n 11 | sed 's/# //'; }

function getpid {
    PID="$(ps aux | grep -i "rclone mount " | grep -v grep | awk '{print $2}')"; }

function ismounted {
    ISMOUNTED="$(findmnt | grep rclone | grep "$REMOTE")"; }

function sync {
    printf "Sync data from:\n(L)ocal system\n(R)emote server\n> " && read S
    [[ ${S,,} = "l" ]] && syncfromlocal
    [[ ${S,,} = "r" ]] && syncfromremote; }

function syncfromlocal {
    echo "Syncing $DIR => ${REMOTE}:..."
    rclone -u sync "$DIR" "${REMOTE}:" -P; } # --drive-acknowledge-abuse

function syncfromremote {
    echo "Syncing $REMOTE => ${DIR}..."
    rclone -u sync "${REMOTE}:" "$DIR" -P; } # --drive-acknowledge-abuse

function check { 
    rclone check "${REMOTE}:" "$DIR" --size-only; }

function status {
    if [[ "$ISMOUNTED" != "" ]]; then
        echo "$REMOTE mounted in $DIR [$PID]"
    elif [[ "$PID" != "" && "$ISMOUNTED" = "" ]]; then
        echo "Killing remaining process $PID..."
        kill -9 "$PID"
    else
        echo "$REMOTE is not currently mounted"; fi; }

function mount {
    if [[ "$ISMOUNTED" != "" ]]; then
        echo "$REMOTE already mounted in $DIR [$PID]"
    else
        rclone mount "${REMOTE}:" "$DIR" -L --allow-non-empty & disown
        echo "Mounted as $DIR [$!]"; fi; }

function umount {
    if [[ "$ISMOUNTED" = "" && "$PID" = "" ]]; then
        echo "$REMOTE is not currently mounted"
    elif [[ "$PID" != "" && "$ISMOUNTED" = "" ]]; then
        echo "Killing remaining process $PID..."
        kill -9 "$PID"
    else
        fusermount -uz "$DIR" &&
        echo "$REMOTE umounted from $DIR [$PID]" &&
        [[ "$PID" != "" ]] &&
        kill -9 "$PID"; fi; }

function copy {
    rclone copyto "$FILE" "${REMOTE}:$FOLDER" &&
    echo "Sent $FILE to ${REMOTE}:${FOLDER}"; }

function share {
    if [[ -d "$FILE" ]]; then
        rclone link "${REMOTE}:${FOLDER}"
    elif [[ -f "$FILE" ]]; then
        rclone link "${REMOTE}:${FOLDER}/${FILE}"
    else
        rclone link "${REMOTE}:${FILE}"; fi; }

#################################################

# execute

getpid    # catch process ID if already running
ismounted # check if remote is mounted as folder

case "$ARG" in

    y|sync)
        sync
        ;;

    syncfromlocal)
        syncfromlocal
        ;;

    copyfromremote)
        syncfromremote
        ;;

    s|status)
        status
        ;;

    c|check)
        check
        ;;

    m|mount|start|s)
        mount
        ;;

    u|umount|stop|exit|quit|q)
        umount
        ;;

    r|remount|refresh|restart)
        umount
        sleep 0.5
        getpid
        ismounted
        mount
        ;;

    cp|copy|send)
        copy
        ;;

    l|link|share)
        copy
        share
        ;;

    *) # default
        help
        ;;

esac # finishes