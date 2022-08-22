#!/bin/bash

# see also https://borgbackup.readthedocs.io/en/1.2-maint/quickstart.html#automating-backups

export BORG_REPO="$HOME/.backup"
export BACKUP_TARGETS="$HOME/bin $HOME/etc"
export BACKUP_NAME="backup"

if [ ! -d $BORG_REPO ]
then
    $HOME/bin/borg init $BORG_REPO --encryption none
fi

# create borg backup archive
$HOME/bin/borg create ::`date +%Y%m%d`-$BACKUP_NAME $BACKUP_TARGETS --exclude "$HOME/bin/borg"

# prune old archives to keep disk space in check
$HOME/bin/borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=2

# to list the content of the repo:
# $HOME/bin/borg list $HOME/.backup