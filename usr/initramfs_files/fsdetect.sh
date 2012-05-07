#!/sbin/busybox sh
#
# Filesystem Detection Script for Galaxy 3 Stage 1 Init
#
# Copyright (c) Hill Beast 2012
#
# By Mark "Hill Beast" Kennard (komcomputers@gmail.com)
#
# Based upon Fugumod pre-init script, but much simpler
#

CONFIGDIR=/sdcard/Android/data/g3mod
EFSDEV=stl4
SYSTEMDEV=stl6
DATADEV=stl7
CACHEDEV=stl8
DATA2SDDEV=mmcblk0p2

# Detect Filesystems
mkdir -p /mnt/tmp
for DEVICE in $EFSDEV $SYSTEMDEV $DATADEV $CACHEDEV $DATA2SDDEV
do
	mount -o ro /dev/block/${DEVICE} /mnt/tmp
	DEVICEFS=`mount | awk '/\/mnt\/tmp/ { print $5 }' | sed 's/vfat/rfs/'`
	echo "${DEVICE} ${DEVICEFS}" >> /tmp/fs.current
	umount /mnt/tmp
done

EFSFS=`grep $EFSDEV /tmp/fs.current | awk '{ print $2 }'`
SYSTEMFS=`grep $SYSTEMDEV /tmp/fs.current | awk '{ print $2 }'`
DATAFS=`grep $DATADEV /tmp/fs.current | awk '{ print $2 }'`
CACHEFS=`grep $CACHEDEV /tmp/fs.current | awk '{ print $2 }'`
DATA2SDFS=`grep $DATA2SDDEV /tmp/fs.current | awk '{ print $2 }'`

echo "Current filesystems:"
cat /tmp/fs.current
echo "---\n"

mkdir /efs
mkdir /system
mkdir /data
mkdir /cache
mkdir /sdext

mount -t $EFSFS     /dev/block/$EFSDEV     /efs
mount -t $SYSTEMFS  /dev/block/$SYSTEMDEV  /system
mount -t $DATAFS    /dev/block/$DATADEV    /data
mount -t $CACHEFS   /dev/block/$CACHEDEV   /cache
mount -t $DATA2SDFS /dev/block/$DATA2SDDEV /sdext

