#!/bin/sh

# Script to mount the volumes..

MOUNTS=$(mount)

if [[ -n "$1" ]]; then
    arg="$1"
fi

if [[ $arg == "pv" ]]; then
    MNT2D="/mnt1/private/var"
else
    MNT2D="/mnt2"
fi

while read LINE; do
    set $LINE
    if [[ $3 == "/mnt1" ]]; then
        MNT1=$1
    else
        if [[ $3 == "$MNT2D" ]]; then
            MNT2=$1
        fi
    fi
done <<< "$MOUNTS"

echo "Waiting for disks..."
while [[ ! $(ls /dev/disk* 2>/dev/null) ]]; do
    :
done

if [[ -z $MNT1 ]]; then
    if [[ -b /dev/disk0s1s1 ]]; then
        echo "Mounting /dev/disk0s1s1 on /mnt1"
        mount_hfs /dev/disk0s1s1 /mnt1
    else
        echo "Checking /dev/disk0s1"
        fsck_hfs /dev/disk0s1
        echo "Mounting /dev/disk0s1 on /mnt1"
        mount_hfs /dev/disk0s1 /mnt1
    fi
else
    echo "$MNT1 already mounted on /mnt1"
fi

if [[ $arg == "root" ]]; then
    exit
fi

if [[ -z $MNT2 ]]; then
    if [[ -b /dev/disk0s1s2 ]]; then
        echo "Mounting /dev/disk0s1s2 on $MNT2D"
        mount_hfs /dev/disk0s1s2 $MNT2D
    elif [[ -b /dev/disk0s2s1 ]]; then
        echo "Mounting /dev/disk0s2s1 on $MNT2D"
        mount_hfs /dev/disk0s2s1 $MNT2D
    else
        echo "Checking /dev/disk0s2"
        fsck_hfs /dev/disk0s2
        echo "Mounting /dev/disk0s2 on $MNT2D"
        mount_hfs /dev/disk0s2 $MNT2D
    fi
else
    echo "$MNT2 already mounted on $MNT2D"
fi
