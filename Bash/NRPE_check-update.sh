#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-update.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-update.sh
#
# SCRIPT DESCRIPTION :     This script is used to check if there is any update available for the system with NRPE.
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

SCRIPT_NAME="NRPE_check-update.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_update () {
    # Check if there is any update available for the system, and return the status
    apt update 2>/dev/null 1>/dev/null
    packages=$(apt list --upgradable 2>/dev/null)
    echo "$packages"
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

packages_list=$(check_update)
if [[ "$packages_list" == "Listing..." ]]; then
    echo -e "OK - No update available for the system."
    exit 0
else
    packages_list=$(echo "$packages_list" | awk -F/ 'NR>1 {print $1}' | tail -n +4)
    output=""
    for package in $packages_list; do
        output="$output \\ $package"
    done
    output=$(echo "$output" | cut -c 5-)
    echo -e "WARNING - Update available for the following packages.\n$output"
    exit 1
fi