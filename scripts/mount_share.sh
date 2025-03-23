#!/bin/bash
# Mount the backup directory from the NAS
# You need to run "apt install cifs-utils" first

# Get script directory
SCRIPTDIR=$(dirname $(readlink -f $0))

# Include config
. ${SCRIPTDIR}/config.sh

echo "[INFO] Checking if temporary mount directory exists <mountDir=$NAS_MOUNT_DIR> ..."
if [ ! -d $NAS_MOUNT_DIR ] ; then
	echo "[INFO] Temporary directory does not exist, creating it"
	OUT=`$BIN_MKDIR -p $NAS_MOUNT_DIR`
	if [ $? -ne 0 ] ; then
		echo "[ERROR] Failed to create temporary mount directory, aborting"
		exit 1
	fi
fi

echo "[INFO] Checking if share has already been mounted <host=$NAS_HOSTNAME><share=$NAS_SHARE><mountDir=$NAS_MOUNT_DIR> ..."
if $BIN_MOUNTPOINT -q $NAS_MOUNT_DIR; then
	echo "[INFO] Share is already mounted ..."
else
	echo "[INFO] Share is not mounted, mounting it now ..."
	$BIN_MOUNT -t cifs -o username=$USERNAME,password=$PASSWORD //$NAS_HOSTNAME/$NAS_SHARE $NAS_MOUNT_DIR
	if [ $? -ne 0 ] ; then
		echo "[ERROR] Failed to mount share, aborting"
		exit 1
	fi
	echo "[INFO] Re-checking if share has been mounted <host=$NAS_HOSTNAME><share=$NAS_SHARE><mountDir=$NAS_MOUNT_DIR> ..."
	if $BIN_MOUNTPOINT -q $NAS_MOUNT_DIR; then
		echo "[INFO] Share has been mounted"
	else
		echo "[ERROR] Share mount failed"
		exit 1
	fi
fi

exit 0
