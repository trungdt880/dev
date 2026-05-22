#!/bin/bash
# Script to mount Google Drive using google-drive-ocamlfuse

USER=termanteus
GOOGLE_DRIVE_MOUNTPOINT=~/gdrive

# Make sure the mount point directory exists
if [ ! -d "$GOOGLE_DRIVE_MOUNTPOINT" ]; then
    mkdir -p "$GOOGLE_DRIVE_MOUNTPOINT"
fi

# Mount the Google Drive
su $USER -l -c "google-drive-ocamlfuse $GOOGLE_DRIVE_MOUNTPOINT"

