#!/bin/bash
# Main script to run the backup of the atmosphere dropbox

# Get script directory
SCRIPTDIR=$(dirname $(readlink -f $0))

# Include config
. ${SCRIPTDIR}/config.sh

# Start timestamp to use in log and directory file names
TIMESTAMP=`date +%Y%m%d-%H%M%S`

# Temporary log file to write to before it is stored in the final NAS directory
LOGFILE=/tmp/${TIMESTAMP}-dropbox.log

# Root target directory of the backup
ROOT_BACKUP_DIR=${NAS_MOUNT_DIR}

# If we should ignore errors on the backup from dropbox-to-share
RSYNC_IGNORE_ERRORS=1

# Function for logging, log to file and to console
function log {
	ARG_MSG=$1
	LOG_DATE=`date`
	echo "${LOG_DATE}: ${ARG_MSG}" >> $LOGFILE
	echo "${LOG_DATE}: ${ARG_MSG}"

}

# Function to mount all shares
function mount_all {
	log "[INFO] Mounting NAS share read-write ..."
        ${SCRIPTDIR}/mount_share.sh &>> $LOGFILE
        if [ $? -ne 0 ] ; then
                log "[ERROR] Failed to mount NAS share"
		return 1
        fi
	log "[INFO] Mounting dropbox read-only ..."
        ${SCRIPTDIR}/mount_dropbox.sh &>> $LOGFILE
        if [ $? -ne 0 ] ; then
                log "[ERROR] Failed to mount dropbox"
		return 2
        fi
        log "[INFO] Mount of all shares complete"
        return 0
}

# Function to unmount all shares, writing logs to stdout
function unmount_all_nolog {
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

# Function to unmount all shares
function unmount_all {
	log "[INFO] Unmounting NAS share ..."
	${SCRIPTDIR}/unmount_share.sh &>> $LOGFILE
	if [ $? -ne 0 ] ; then
		log "[WARN] Failed to unmount or NAS share was not yet mounted"
	fi
	log "[INFO] Unmounting dropbox ..."
	${SCRIPTDIR}/unmount_dropbox.sh &>> $LOGFILE
	if [ $? -ne 0 ] ; then
                log "[WARN] Failed to unmount or dropbox was not yet mounted"
        fi
	log "[INFO] Unmount of all shares complete"
	return 0
}

# Move log file to NAS share
function store_log_file {
	log "[INFO] Storing log file <$LOGFILE> on NAS share <$ROOT_BACKUP_DIR>"
	mv $LOGFILE ${ROOT_BACKUP_DIR}/
	if [ $? -ne 0 ] ; then
                log "[ERROR] Failed to store log file on NAS share"
		return 1
        fi
	log "[INFO] Storing of log file complete"
	return 0
}

log "[INFO] Backup task started <$TIMESTAMP> ..."

# Run full unmount cleanup, just to be safe
unmount_all

# Mount both NAS and dropbox
mount_all
RET=$?
if [ $RET -ne 0 ] ; then
	log "[ERROR] Mounting at least one share failed, aborting"

	if [ $RET -eq 2 ] ; then
		# We were able to mount the NAS, so store the log file there
		store_log_file
        	unmount_all_nolog
	else
		# We were not able to mount the NAS, so just unmount everythings
        	# Since we cannot store the log file on the NAS share in that case, just leave the log file where it is under /tmp
		unmount_all
	fi
        exit 1
fi

# Check if an older backup directory already exists which we can use as a basic in order to only download changed files
BACKUP_LATEST=($(ls ${ROOT_BACKUP_DIR} -I "*.log" | sort -rt '-' -k 3 | head -n 1))
if [ ! -z $BACKUP_LATEST ] ; then
	log "[INFO] Discovered latest backup <${ROOT_BACKUP_DIR}/${BACKUP_LATEST}>"
else
	log "[INFO] No latest backup discovered, starting from scratch"
fi

# Create the backup target directory on the NAS share
DATE_BACKUP_DIR=${ROOT_BACKUP_DIR}/${TIMESTAMP}
log "[INFO] Creating new backup directory on NAS <backupDir=$DATE_BACKUP_DIR> ..."
$BIN_MKDIR -p ${DATE_BACKUP_DIR} &>> $LOGFILE
if [ $? -ne 0 ] ; then
	log "[INFO] Creating backup directory on NAS failed, aborting"
	store_log_file
	unmount_all_nolog
	exit 1
fi

# If applicable copy latest backup contents into this new folder
if [ ! -z $BACKUP_LATEST ] ; then
	log "[INFO] Copying data from latest backup to new folder as a base line <${ROOT_BACKUP_DIR}/${BACKUP_LATEST}> ..."
	$BIN_RSYNC -ah --progress ${ROOT_BACKUP_DIR}/${BACKUP_LATEST}/ ${DATE_BACKUP_DIR}/ &>> $LOGFILE
	RSYNC_RET=$?
	if [ $RSYNC_RET -ne 0 ] ; then
		log "[ERROR] Failed to copy latest backup as a baseline, starting from scratch <returnCode=$RSYNC_RET>"
		rm -rf ${DATE_BACKUP_DIR}/* &>> $LOGFILE
	else
		log "[INFO] Copy of latest backup complete"
	fi
fi

# Execute the backup
# Exclude the Vault directory, since that is something special within DropBox
log "[INFO] Starting backup rsync from <$DROPBOX_MOUNT_DIR> to <$DATE_BACKUP_DIR>"
$BIN_RSYNC -rlth --itemize-changes --no-perms --no-group --no-owner --delete --size-only --exclude Vault --exclude '*.paper' --progress ${DROPBOX_MOUNT_DIR}/ ${DATE_BACKUP_DIR}/ &>> $LOGFILE
RSYNC_RET=$?
if [ $RSYNC_RET -ne 0 ] ; then
	FAILED_TIMESTAMP=`date +%Y%m%d-%H%M%S`
        log "[ERROR] Backup run failed at <$FAILED_TIMESTAMP> <returnCode=$RSYNC_RET>"
	if [ $RSYNC_IGNORE_ERRORS -eq 0 ] ; then
	        if [ -d ${DATE_BACKUP_DIR} ] ; then
	                log "[ERROR] Deleting incomplete backup <${DATE_BACKUP_DIR}>"
	                rm -rf ${DATE_BACKUP_DIR} &>> $LOGFILE
	        fi
		store_log_file
		unmount_all_nolog
	        exit 1
	else
		log "[INFO] Ignoring errors, continuing"
	fi
fi
log "[INFO] Rsync backup completed successfully"

# Unmount the Dropbox
log "[INFO] Unmounting dropbox ..."
${SCRIPTDIR}/unmount_dropbox.sh &>> $LOGFILE
if [ $? -ne 0 ] ; then
        log "[ERROR] Unmounting dropbox failed, continuing"
fi

# Apply the backup retention
log "[INFO] Running backup cleanup ..."
${SCRIPTDIR}/backup_clean.sh &>> $LOGFILE
if [ $? -ne 0 ] ; then
        log "[ERROR] Backup retention cleanup failed, continuing"
fi

FINISHED_TIMESTAMP=`date +%Y%m%d-%H%M%S`

log "[INFO] Backup run complete at <$FINISHED_TIMESTAMP>"

# Store the log file on the NAS share and unmount it
store_log_file

${SCRIPTDIR}/unmount_share.sh
if [ $? -ne 0 ] ; then
	# Just print it, no log file available anymore
        echo "[ERROR] Unmounting NAS share failed, aborting"
        exit 1
fi

exit 0
