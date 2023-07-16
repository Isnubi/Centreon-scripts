#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-uptime.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-uptime.sh
#
# SCRIPT DESCRIPTION :     This script is used to check the uptime of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-uptime.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_uptime () {
    # Check the uptime of the system, and return the time
    uptime -p
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

if [ -n "$(check_uptime)" ]; then
    echo -e "OK - The system is up since $(check_uptime)$"
    exit 0
else
    echo -e "CRITICAL - System down"
    exit 2
fi