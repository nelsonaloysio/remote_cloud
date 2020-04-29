#!/usr/bin/env bash
#
# Bash script to interact with rclone and a preconfigured
# remote through the argument actions available below:
#
# usage: rcloud {option} [input] [output]
#
# options:
#   sync (y)          sync remote name and exit
#   copy (cp)         input file to remote output
#   remove (rm)       input file from remote path
#   removedir (rmdir) input folder from remote path
#   makedir (mkdir)   new input folder in remote path
#   list (ls)         contents from input remote path
#   link (l)          share link to input file or folder
#   check (c)         differences between local and remote
#   mount (m)         mount remote directory (*)
#   umount (u)        stop remote mount syncing (*)
#   remount (r)       try and refresh remote mount (*)
#   status (s)        status for remote mount (*)
#
# Arguments marked with an asterisk are EXPERIMENTAL rclone features.
#
# This is of course NOT intended as a desktop cloud solution.
#
# Tested with rclone v1.49.5 on linux/amd64 (go1.13.1).

# REQUIRED: original remote name as in rclone
REMOTE=""

# REQUIRED: path to sync or mount files
DIR=""

# define vars
OPTION="$1"    # action to execute
INPUT="$2"     # file or folder as input
OUTPUT="$3"    # output path to upload to

if [[ "$OPTION" != "" && "$OPTION" != '-h' ]]; then

    # check user settings
    [[ "$REMOTE" = "" || "$DIR" = "" ]] &&
    echo "Error: missing user configuration (REMOTE/DIR)." && exit

    # create remote directory
    [[ ! -d "$DIR" ]] &&
    mkdir -p "$DIR"

    # check output parameter
    [[ "$OUTPUT" = "/" ]] &&
    OUTPUT=""

    # append root path to output
    [[ "$OUTPUT{0:1}" != "/" ]] &&
    OUTPUT="/${OUTPUT}"; fi

# define functions

function help {
    head -n 20 "$0" | tail -n 15 | sed 's/# //;s/ (\*)//;2d'; }

function sync {
    printf "Sync data from:\n(L)ocal system\n(R)emote server\n> " && read S
    [[ ${S,,} = "l" ]] && syncfromlocal
    [[ ${S,,} = "r" ]] && syncfromremote; }

function syncfromlocal {
    echo "Syncing '$DIR' => ${REMOTE}..."
    rclone -u sync "$DIR" "${REMOTE}:" -P; } # --drive-acknowledge-abuse

function syncfromremote {
    echo "Syncing $REMOTE => '${DIR}'..."
    rclone -u sync "${REMOTE}:" "$DIR" -P; } # --drive-acknowledge-abuse

function copy {
    if [[ "$INPUT" = "" ]]; then
        echo "Error: missing input parameter."
    elif [[ -d "$INPUT" ]]; then
        echo "Copying '$INPUT' to ${REMOTE}:${OUTPUT}..."
        rclone copy "$INPUT" "${REMOTE}:${OUTPUT}" -P
    elif [[ -f "$INPUT" ]]; then
        echo "Copying '$INPUT' to ${REMOTE}:${OUTPUT}..."
        rclone copy "$INPUT" "${REMOTE}:${OUTPUT}" -P; fi; }

function remove {
    if [[ "$INPUT" = "" ]]; then
        echo "Error: missing input parameter."
    else
        echo "Deleting '$INPUT' from $REMOTE..."
        rclone deletefile "${REMOTE}:${INPUT}"; fi; }

function removedir {
    if [[ "$INPUT" = "" ]]; then
        echo "Error: missing input parameter."
    else
        echo "Deleting '$INPUT' folder from $REMOTE..."
        rclone rmdir "${REMOTE}:$INPUT"; fi; }

function makedir {
    if [[ "$INPUT" = "" ]]; then
        echo "Error: missing input parameter."
    else
        echo "Creating '$INPUT' folder in $REMOTE..."
        rclone mkdir "${REMOTE}:$INPUT"; fi; }

function list {
    rclone lsf "${REMOTE}:${INPUT}"; }

function link {
    rclone link "${REMOTE}:${INPUT}"; }

function mount {
    if [[ $(ls -1a "$DIR" | sed '1d;2d') != "" ]]; then
        echo "Error: directory '$DIR' must be empty."
    elif [[ "$ISMOUNTED" != "" ]]; then
        echo "Remote $REMOTE already mounted in '$DIR' [$PID]."
    else
        rclone mount "${REMOTE}:" "$DIR" -L --allow-non-empty & disown
        echo "Remote $REMOTE mounted in '$DIR' [$!]."; fi; }

function umount {
    if [[ "$ISMOUNTED" = "" && "$PID" = "" ]]; then
        echo "Remote $REMOTE is not currently mounted."
    elif [[ "$PID" != "" && "$ISMOUNTED" = "" ]]; then
        echo "Killing remaining process $PID..."
        kill -9 "$PID"
    else
        fusermount -uz "$DIR" &&
        echo "Remote $REMOTE umounted from '$DIR' [$PID]." &&
        getpid && [[ "$PID" != "" ]] &&
        kill -9 "$PID"; fi; }

function status {
    if [[ "$ISMOUNTED" != "" ]]; then
        echo "Remote $REMOTE mounted in '$DIR' [$PID]."
    elif [[ "$PID" != "" && "$ISMOUNTED" = "" ]]; then
        echo "Killing remaining process $PID..."
        kill -9 "$PID"
    else
        echo "Remote $REMOTE is not currently mounted."; fi; }

function check {
    rclone check "${REMOTE}:" "$DIR" --size-only; }

function getpid {
    PID="$(ps aux | grep -i "rclone mount " | grep -v grep | awk '{print $2}')"; }

function ismounted {
    ISMOUNTED="$(findmnt | grep rclone | grep "$DIR" | grep "${REMOTE}:")"; }

#################################################

# execute

getpid    # catch process ID if already running
ismounted # check if remote is mounted in directory

case "$OPTION" in

    y|sync)
        sync
        ;;

    syncfromlocal|synctoremote)
        syncfromlocal
        ;;

    syncfromremote|synctolocal)
        syncfromremote
        ;;

    cp|copy)
        copy
        ;;

    rm|remove|delete)
        remove
        ;;

    rmdir|removedir)
        removedir
        ;;

    mkdir|makedir)
        makedir
        ;;

    ls|list)
        list
        ;;

    l|link|share)
        link
        ;;

    c|check)
        check
        ;;

    m|mount)
        mount
        ;;

    u|umount)
        umount
        ;;

    r|remount|refresh)
        umount
        sleep 0.5
        getpid
        ismounted
        mount
        ;;

    s|status)
        status
        ;;

    -h|*) # default
        help
        ;;

esac # finishes