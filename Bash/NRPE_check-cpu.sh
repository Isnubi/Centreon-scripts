#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-cpu.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-cpu.sh
#
# SCRIPT DESCRIPTION :     This script is used to check the cpu usage of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-cpu.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_cpu () {
    # Check the cpu usage of the system, and return the percentage
    top -bn1 | grep Cpu | awk '{print $2}'
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

cpu_usage="$(check_cpu)"

if [ "$(echo "$cpu_usage" | cut -d "." -f1)" -gt 90 ]; then
    echo -e "CRITICAL - CPU usage is $cpu_usage% | 'cpu_usage'=$cpu_usage%"
    exit 2
elif [ "$(echo "$cpu_usage" | cut -d "." -f1)" -lt 90 ] & [ "$(echo "$cpu_usage" | cut -d "." -f1)" -gt 80 ]; then
    echo -e "WARNING - CPU usage is $cpu_usage% | 'cpu_usage'=$cpu_usage%"
    exit 1
else
    echo -e "OK - CPU usage is $cpu_usage% | 'cpu_usage'=$cpu_usage%"
    exit 0
fi