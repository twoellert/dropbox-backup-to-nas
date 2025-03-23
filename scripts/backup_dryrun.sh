#!/bin/bash
# Main script to run the backup of the aerolifi gitlab project
# You need to run "apt install python pip" and "pip install python-gitlab" first

# Get script directory
SCRIPTDIR=$(dirname $(readlink -f $0))

# Include config
. ${SCRIPTDIR}/config.sh

TIMESTAMP=`date +%Y%m%d-%H%M%S`

ROOT_BACKUP_DIR=${NAS_MOUNT_DIR}

# Function for logging, log to console
function log {
	ARG_MSG=$1
	echo $ARG_MSG
}

# Function to mount all shares
function mount_all {
	log "[INFO] Mounting NAS share read-write ..."
        ${SCRIPTDIR}/mount_share.sh
        if [ $? -ne 0 ] ; then
                log "[ERROR] Failed to mount NAS share"
		return 1
        fi
	log "[INFO] Mounting dropbox read-only ..."
        ${SCRIPTDIR}/mount_dropbox.sh
        if [ $? -ne 0 ] ; then
                log "[ERROR] Failed to mount dropbox"
        fi
        log "[INFO] Mount of all shares complete"
        return 0
}

# Function to unmount all shares
function unmount_all {
	log "[INFO] Unmounting NAS share ..."
	${SCRIPTDIR}/unmount_share.sh
	if [ $? -ne 0 ] ; then
		log "[WARN] Failed to unmount or NAS share was not yet mounted"
	fi
	log "[INFO] Unmounting dropbox ..."
	${SCRIPTDIR}/unmount_dropbox.sh
	if [ $? -ne 0 ] ; then
                log "[WARN] Failed to unmount or dropbox was not yet mounted"
        fi
	log "[INFO] Unmount of all shares complete"
	return 0
}

log "[INFO] Backup dry-run started <$TIMESTAMP> ..."

# Run full unmount cleanup, just to be safe
unmount_all

# Mount both NAS and dropbox
mount_all
if [ $? -ne 0 ] ; then
	log "[ERROR] Mounting NAS share failed, aborting"
        unmount_all
        # Since we cannot store the log file on the NAS share in that case, just leave the log file where it is under /tmp
        exit 1
fi

# Check if an older backup directory already exists which we can use as a basic in order to only download changed files
BACKUP_LATEST=($(ls ${ROOT_BACKUP_DIR} -I "*.log" | sort -rt '-' -k 3 | head -n 1))
if [ ! -z $BACKUP_LATEST ] ; then
	log "[INFO] Discovered latest backup <${ROOT_BACKUP_DIR}/${BACKUP_LATEST}>"

	# Execute the backup
	# Exclude the Vault directory, since that is something special within DropBox
	log "[INFO] Starting backup dry-run rsync, comparing <$DROPBOX_MOUNT_DIR> to <${ROOT_BACKUP_DIR}/${BACKUP_LATEST}>"
	$BIN_RSYNC -ah --dry-run --itemize-changes --no-perms --no-group --no-owner --delete --size-only --exclude Vault --progress ${DROPBOX_MOUNT_DIR}/ ${ROOT_BACKUP_DIR}/${BACKUP_LATEST}/
	if [ $? -ne 0 ] ; then
	        FAILED_TIMESTAMP=`date +%Y%m%d-%H%M%S`
	        log "[ERROR] Backup dry-run failed at <$FAILED_TIMESTAMP>, aborting"
	        unmount_all
	        exit 1
	fi
	log "[INFO] Rsync dry-run completed successfully ..."

else
	log "[ERROR] No latest backup discovered, unable to perform a dry-run, aborting"
fi

# Unmount the Dropbox
log "[INFO] Unmounting dropbox ..."
${SCRIPTDIR}/unmount_dropbox.sh
if [ $? -ne 0 ] ; then
        log "[ERROR] Unmounting dropbox failed, continuing"
fi

FINISHED_TIMESTAMP=`date +%Y%m%d-%H%M%S`

log "[INFO] Backup dry-run complete at <$FINISHED_TIMESTAMP>"

${SCRIPTDIR}/unmount_share.sh
if [ $? -ne 0 ] ; then
	# Just print it, no log file available anymore
        echo "[ERROR] Unmounting NAS share failed, aborting"
        exit 1
fi

exit 0
