#!/usr/bin/env bash
#
# Bash script to interact with rclone and a preconfigured
# remote through the argument actions available below:
#
# usage: rcloud {option} [input] [output] [-s]
# 
# options:
#   sync (y)      sync google remote and exit
#   copy (cp)     a specific file to remote
#   link (l)      get share link for a file or folder
#   mount (m)     start sync and mount as folder
#   umount (u)    stop rclone remote syncing
#   remount (r)   try and refresh remote sync
#   check (c)     status for rclone remote mount
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

ARG="$1"    	# argument to execute
FILE="$2"    	# file or folder to upload
FOLDER="$3"    	# path to upload file or folder to
SHAREONLY="$4"  # flag "-s" for sharing file only

[[ "$FOLDER" = "" ]] &&
FOLDER="share" # default

[[ "$FOLDER" = "/" ]] &&
FOLDER="" # copy to root

[[ "$SHAREONLY" = "-s" || "$FOLDER" = "-s" ]] &&
SHAREONLY=true # disable copying

#################################################

# define functions

function help {
    head -n 15 "$0" | tail -n 10 | sed 's/# //'; }

function getpid {
    PID="$(ps aux | grep -i "rclone mount " | grep -v grep | awk '{print $2}')"; }

function ismounted {
    ISMOUNTED="$(findmnt | grep rclone | grep "$REMOTE")"; }

function sync {
    rclone -u copy "${REMOTE}:" "$DIR" &&
    rclone -u copy "$DIR" "${REMOTE}:" &&
    echo "Synced ${REMOTE}"; }

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
    rclone copy "$FILE" "${REMOTE}:$FOLDER" &&
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

    c|check|status)
        status
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
    	[[ "$SHAREONLY" != true ]] && copy
    	share
    	;;

    *) # default
        help
        ;;

esac # finishes
