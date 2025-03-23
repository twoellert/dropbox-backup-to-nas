#!/bin/bash
# Cleanup of backups depending on retention config

# Get script directory
SCRIPTDIR=$(dirname $(readlink -f $0))

# Include config
. ${SCRIPTDIR}/config.sh

echo "[INFO] Backup cleanup started ..."

# Check if mounted backup directory exists
echo "[INFO] Checking if backup directory exists <${NAS_MOUNT_DIR}> ..."
if [ ! -d ${NAS_MOUNT_DIR} ] ; then
	echo "[ERROR] Backup directory does not exist or is not mounted <${NAS_MOUNT_DIR}>, aborting"
	exit 1
fi

# Check amount of backups in directory
AMOUNT_OF_BACKUPS=`find ${NAS_MOUNT_DIR}/* -maxdepth 0 -type d | wc -l`
echo "[INFO] Found amount of backups <$AMOUNT_OF_BACKUPS>, backup retention is set to <$BACKUP_RETENTION>"

if [ $AMOUNT_OF_BACKUPS -gt $BACKUP_RETENTION ] ; then
	echo "[INFO] Amount of backups is higher than the configured backup retention <$BACKUP_RETENTION> running cleanup ..."

        BACKUP_COUNTER=0
        BACKUPS=($(ls ${NAS_MOUNT_DIR} -I "*.log" | sort -rt '-' -k 3))
        for BACKUP in "${BACKUPS[@]}"
        do
                BACKUP_COUNTER=$((BACKUP_COUNTER+1))
                if [ $BACKUP_COUNTER -gt $BACKUP_RETENTION ] ; then
                        echo "[INFO] Cleaning up backup <${NAS_MOUNT_DIR}/$BACKUP>"
                        `rm -rf ${NAS_MOUNT_DIR}/${BACKUP}`
			if [ $? -ne 0 ] ; then
				echo "[ERROR] Failed to cleanup backup, aborting"
				exit 1
			fi

			# Also delete any existing log file of this backup
			if [ -f ${NAS_MOUNT_DIR}/${BACKUP}-dropbox.log ] ; then
				`rm -rf ${NAS_MOUNT_DIR}/${BACKUP}-dropbox.log`
			fi
                fi
        done
fi

echo "[INFO] Backup cleanup finished"
exit 0
