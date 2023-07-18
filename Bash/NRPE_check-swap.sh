#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-swap.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-swap.sh
#
# SCRIPT DESCRIPTION :     This script is used to check the swap usage of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-swap.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_swap () {
    # Check the swap usage of the system, and return the percentage
    free | grep Swap | awk '{print $3/$2 * 100.0}'
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

swap=$(check_swap)

if [ "$(echo "$swap" | cut -d "." -f1)" -gt 90 ]; then
    echo -e "CRITICAL - Swap usage is at 90% - $swap% | 'swap'=$swap%"
    exit 2
elif [ "$(echo "$swap" | cut -d "." -f1)" -gt 80 ]; then
    echo -e "WARNING - Swap usage is at 80% - $swap% | 'swap'=$swap%"
    exit 1
else
    echo -e "OK - Swap usage is at 80% - $swap% | 'swap'=$swap%"
    exit 0
fi