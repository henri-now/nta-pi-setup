#!/bin/bash


#####################################
# USAGE: install.sh TARGET [-i IMAGE] [-u FILE-USER-DATA] [-m FILE-META-DATA]
# TARGET should be a block device
# IMAGE is automatically downloaded if omitted
# This is a fairly fragile script only expected to work with images of Ubuntu Server 24
#####################################


set -eo pipefail

# extract and validate arguments
while getopts i:u:m: option; do 
    case "$option" in
        i)IMAGE=${OPTARG};;
        u)USERFILE=${OPTARG};;
        m)METAFILE=${OPTARG};;
    esac
done

shift $((OPTIND - 1))
if [ -z "$1" ]; then
    echo "ERROR: no target specified" >&2
    exit 1
fi
TARGET=$1

if [ ! -w "$TARGET" ]; then
    echo "ERROR: cannot write to target" >&2
    exit 1
fi

# write IMAGE to TARGET, downloading it if necessary
if [ -z "$IMAGE" ]; then
    wget -q -O- "https://cdimage.ubuntu.com/releases/24.04.4/release/ubuntu-24.04.4-preinstalled-server-arm64+raspi.img.xz" \
    | unxz -c \
    | dd of="$TARGET" status=progress
else
    dd if=$IMAGE of=$TARGET status=progress
fi

# modify boot partition
BOOTPART=$(lsblk $TARGET -l -o PATH,LABEL | grep system-boot | awk '{print $1}')
if [ -z "$BOOTPART" ]; then
    echo "ERROR: no boot partition found after flashing image" >&2
    exit 1
fi
TEMPDIR=$(mktemp -d)
SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [ -z "$USERFILE"]; then
    USERFILE="${SCRIPTDIR}/user-data"
fi
if [ -z "$METAFILE"]; then
    METAFILE="${SCRIPTDIR}/meta-data"
fi

mount $BOOTPART $TEMPDIR
cp "$USERFILE" "$TEMPDIR"
cp "$METAFILE" "$TEMPDIR"
umount $TEMPDIR
rm -r $TEMPDIR
