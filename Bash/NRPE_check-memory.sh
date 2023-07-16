#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-memory.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-memory.sh
#
# SCRIPT DESCRIPTION :     This script is used to check the memory usage of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-memory.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_memory () {
    # Check the memory usage of the system, and return the percentage
    free -m | awk 'NR==2{printf "%.2f", $3*100/$2 }'
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

if [ "$(check_memory | cut -d "." -f1)" -gt 90 ]; then
    echo -e "CRITICAL - Memory usage is $(check_memory)%"
    exit 2
elif [ "$(check_memory | cut -d "." -f1)" -lt 90 ] & [ "$(check_memory | cut -d "." -f1)" -gt 80 ]; then
    echo -e "WARNING - Memory usage is $(check_memory)%"
    exit 1
else
    echo -e "OK - Memory usage is $(check_memory)%"
    exit 0
fi