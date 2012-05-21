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
CONFIGDIR=/sdcard/Android/data/kernel
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
	SDDEV=$ALTSDCARDDEV
else
	echo "SD card $SDCARDDEV used for configuration"
	SDDEV=$SDCARDDEV
fi
mkdir -p $CONFIGDIR

# Detect Filesystems
echo "This file is safe to delete. It will only be generated again upon next boot" > /tmp/fs.current
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

# --- Data2SD ---
# Data2SD create mounts
DATAMOUNTDEV=$DATADEV
DATAMOUNTFS=$DATAFS

if test -z $DATA2SDFS; then
	echo "No Data2SD partition located"
	sed -i "s|DATA2SDMOUNTCODE|# Will not mount Data2SD|" /init.rc
else
	sed -i "s|DATA2SDMOUNTCODE|mount DATA2SDFS /dev/block/DATA2SDDEV /sd-ext nosuid nodev|" /init.rc
	if test -f $CONFIGDIR/fs.data2sd; then
		mkdir /mnt/intdata
		mkdir /mnt/sd-ext
		mount -t $DATAFS /dev/block/$DATADEV /mnt/intdata
		mount -t $DATA2SDFS /dev/block/$DATA2SDDEV /mnt/sd-ext
		if test -z `df /mnt/sd-ext`; then
			echo "DATA2SD Partition ($DATA2SDDEV) is RAW or corrupted. Will format to EXT2"
			mkfs.ext2 /dev/block/$DATA2SDDEV
			mount -t ext2 /dev/block/$DATA2SDDEV /mnt/sd-ext
		fi
		
		if test -z `cat $CONFIGDIR/fs.data2sd | grep "hybrid"`; then
			echo "Data2SD will be used in Normal Mode"
			DATAMOUNTDEV=$DATA2SDDEV
			DATAMOUNTFS=$DATA2SDFS
		else
			echo "Data2SD will be used in Hybrid Mode"

			mount -t $DATAFS /dev/block/$DATADEV /data
			sed -i "s|mount DATAMOUNTFS|# Commented for HD2SD - mount DATAMOUNTFS|" init.rc

			tr -d '\r' < /system/etc/data2sd.dirs > /tmp/data2sd.dirs
			tr -d '\r' < $CONFIGDIR/data2sd.dirs > /tmp/data2sd.dirs

			if test -f /tmp/data2sd.dirs ; then
				echo "HD2SD Config is:"
				cat /tmp/data2sd.dirs
				echo "--- END OF CONFIGURATION ---"
				cat /tmp/data2sd.dirs | while read HD2SDtemp ; do
					echo "Connecting $HD2SDtemp"
					mkdir /data/$HD2SDtemp 2>> /dev/null
					mkdir /mnt/sd-ext/$HD2SDtemp 2>> /dev/null
					mount -o bind /mnt/sd-ext/$HD2SDtemp /data/$HD2SDtemp
				done
			else
				echo "No Data2SD config file found (/system/etc/tmp/data2sd.dirs or /sdcard/Android/data/kernel/tmp/"
			fi

		fi
	else
		echo "Data2SD partition located, but will not be used by kernel based Data2SD"	
	fi
fi

# Set filesystems in system files
if test -f /etc/recovery.fstab; then
	FILESTOEDIT="/etc/recovery.fstab"
else
	FILESTOEDIT=""
fi
for FILE in $FILESTOEDIT /init.rc
do
	echo "Editing $FILE"
	cp $FILE /stage1/

	sed -i "s|SYSTEMFS|$SYSTEMFS|" $FILE
	sed -i "s|SYSTEMDEV|$SYSTEMDEV|" $FILE
	sed -i "s|DATAMOUNTFS|$DATAMOUNTFS|" $FILE
	sed -i "s|DATAMOUNTDEV|$DATAMOUNTDEV|" $FILE
	sed -i "s|CACHEFS|$CACHEFS|" $FILE
	sed -i "s|CACHEDEV|$CACHEDEV|" $FILE
	sed -i "s|DATAFS|$DATAFS|" $FILE
	sed -i "s|DATADEV|$DATADEV|" $FILE
	sed -i "s|DATA2SDFS|$DATA2SDFS|" $FILE
	sed -i "s|DATA2SDDEV|$DATA2SDDEV|" $FILE
	sed -i "s|SDDEV|$SDDEV|" $FILE

	diff /stage1$FILE $FILE
done

# Mount EFS
mkdir /efs
mount -o rw -t $EFSFS /dev/block/$EFSDEV /efs

umount /sdcard
rm -rf /sdcard
