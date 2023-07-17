#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-service.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-service.sh <SERVICE_NAME>
#
# SCRIPT DESCRIPTION :     This script is used to check a service status of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-service.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_service () {
    # Check the service status of the system, and return the status
    service "$1" status 2>&1
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

service_name="$1"
if [ -z "$service_name" ]; then
    echo -e "UNKNOWN - No service given."
    exit 3
fi

service_status="$(check_service "$service_name")"
not_found="$(echo "$service_status" | grep "could not be found")"
inactive="$(echo "$service_status" | grep "Active" | sed 's/^[[:space:]]*//' | cut -d " " -f2 | grep -o "inactive")"

if [ -z "$not_found" ]; then
    if [ -z "$inactive" ]; then
        echo -e "OK - $service_name is running."
        exit 0
    else
        echo -e "CRITICAL - $service_name is not running."
        exit 2
    fi
else
    echo -e "UNKNOWN - $service_name could not be found."
    exit 3
fi