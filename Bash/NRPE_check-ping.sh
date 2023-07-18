#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-ping.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-ping.sh <IP>
#
# SCRIPT DESCRIPTION :     This script is used to check the ping of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-ping.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_ping () {
    # Check the ping of the system, and return the time
    ping -c 1 "$1" | grep "time=" | cut -d "=" -f 4 | cut -d " " -f 1 | awk '{print $1/2}'
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

ip_address="$1"
if [ -z "$ip_address" ]; then
    echo -e "UNKNOWN - No IP address provided."
    exit 3
fi

ping_result="$(check_ping "$ip_address")ms"

if [ -n "$ping_result" ]; then
    echo -e "OK - Ping to $ip_address is $ping_result. | 'ping'=$ping_result"
    exit 0
else
    echo -e "CRITICAL - Ping to $ip_address is not responding."
    exit 2
fi