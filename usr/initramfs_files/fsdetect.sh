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

# Variables (to be changed for other devices)
CONFIGDIR=/sdcard/Android/data/g3mod
EFSDEV=stl4
SYSTEMDEV=stl6
DATADEV=stl7
CACHEDEV=stl8
SDCARDDEV=mmcblk0p1
ALTSDCARDDEV=mmcblk0
DATA2SDDEV=mmcblk0p2

# Create directories
mkdir -p /mnt/sdcard
ln -s /mnt/sdcard /sdcard

# Mount SD card
mount -o utf8 -t vfat /dev/block/$SDCARDDEV /mnt/sdcard
if test -z `df /mnt/sdcard/`; then
	echo "SD Card $SDCARDDEV not found. Using alternative $ALTSDCARDDEV..."
	mount -o utf8 -t vfat /dev/block/$ALTSDCARDDEV /mnt/sdcard
	if test -z `df /mnt/sdcard`; then
		echo "No SD card mounted. No settings will be saved"
	fi
else
	echo "SD card $SDCARDDEV used for configuration"
fi
mkdir -p $CONFIGDIR

# Detect Filesystems
mkdir /mnt/tmp
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
echo "---"

cp /tmp/fs.current $CONFIGDIR/

# Set filesystems in system files
if test -f /etc/recovery.fstab; then
	FILESTOEDIT="/etc/recovery.fstab"
else
	FILESTOEDIT="/init.rc"
fi
for FILE in $FILESTOEDIT
do
	echo "Editing $FILE"
	cp $FILE /stage1/

	sed -i "s|SYSTEMFS|$SYSTEMFS|" $FILE
	sed -i "s|DATAFS|$DATAFS|" $FILE
	sed -i "s|CACHEFS|$CACHEFS|" $FILE
	sed -i "s|DATA2SDFS|$DATA2SDFS|" $FILE
	sed -i "s|SYSTEMDEV|$SYSTEMDEV|" $FILE
	sed -i "s|DATADEV|$DATADEV|" $FILE
	sed -i "s|CACHEDEV|$CACHEDEV|" $FILE
	sed -i "s|DATA2SDDEV|$DATA2SDDEV|" $FILE

	diff /stage1/$FILE $FILE
done

# Mount Data2SD partition
mkdir /sdext
mount -t $DATA2SDFS /dev/block/$DATA2SDDEV /sdext

# Mount EFS
mkdir /efs
mount -o rw -t $EFSFS /dev/block/$EFSDEV /efs

umount /sdcard
