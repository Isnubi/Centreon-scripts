#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-disk.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-disk.sh
#
# SCRIPT DESCRIPTION :     This script is used to check the disk usage of a system with NRPE.
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# v1.0.0  2023.07.05 - Louis GAMBART - Initial version
#
#==========================================================================================


#####################
#                   #
#  I - COLOR CODES  #
#                   #
#####################

No_Color='\033[0m'      # No Color
Red='\033[0;31m'        # Red
Yellow='\033[0;33m'     # Yellow
Green='\033[0;32m'     # Green


####################
#                  #
#  II - VARIABLES  #
#                  #
####################

SCRIPT_NAME="NRPE_check-disk.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_disk () {
    # Check the disk usage of a given mount point, and return the percentage
    df -h | grep "$1" | awk '{print $5}' | cut -d "%" -f1
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

disk_mount_point="$1"
if [ -z "$disk_mount_point" ]; then
    echo -e "UNKNOWN - No mount point given."
    exit 3
fi

if [ "$(check_disk "$disk_mount_point")" -gt 90 ]; then
    echo -e "CRITICAL - Disk usage of $disk_mount_point is $(check_disk "$disk_mount_point")%."
    exit 2
elif [ "$(check_disk "$disk_mount_point")" -gt 80 ]; then
    echo -e "WARNING - Disk usage of $disk_mount_point is $(check_disk "$disk_mount_point")%."
    exit 1
else
    echo -e "OK - Disk usage of $disk_mount_point is $(check_disk "$disk_mount_point")%."
    exit 0
fi