#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-load.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-load.sh
#
# SCRIPT DESCRIPTION :     This script is used to check the cpu load of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-load.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

get_load () {
    # Get the load of the system, and return the load
    uptime | awk -F 'load average:' '{print $2}' | cut -d ',' -f 1-3
}

get_core_number () {
    # Get the number of cores of the system, and return the number of cores
    nproc
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

load=$(get_load)
instant_load=$(echo "$load" | cut -d ',' -f 1 | sed -e 's/^[[:space:]]*//')
five_min_load=$(echo "$load" | cut -d ',' -f 2 | sed -e 's/^[[:space:]]*//')
fifteen_min_load=$(echo "$load" | cut -d ',' -f 3 | sed -e 's/^[[:space:]]*//')

core_number=$(get_core_number)

if (( $(echo "$instant_load" | cut -d '.' -f 1) > core_number )); then
    echo -e "CRITICAL - Load average: {$instant_load}, {$five_min_load}, {$fifteen_min_load} | 'load1'=${instant_load} 'load5'=${five_min_load} 'load15'=${fifteen_min_load}"    exit 2
elif (( $(echo "$instant_load" | cut -d '.' -f 1) > core_number * 75 / 100 )); then
    echo -e "WARNING - Load average: {$instant_load}, {$five_min_load}, {$fifteen_min_load} | 'load1'=${instant_load} 'load5'=${five_min_load} 'load15'=${fifteen_min_load}"    exit 1
else
    echo -e "OK - Load average: {$instant_load}, {$five_min_load}, {$fifteen_min_load} | 'load1'=${instant_load} 'load5'=${five_min_load} 'load15'=${fifteen_min_load}"
    exit 0
fi