#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-traffic.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\NRPE_check-traffic.sh <INTERFACE_NAME>
#
# SCRIPT DESCRIPTION :     This script is used to check the traffic of a system with NRPE.
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

SCRIPT_NAME="NRPE_check-traffic.sh"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

check_rx_traffic () {
    # Check the RX traffic for specific interface of the system, and return the traffic
    old_rx_traffic=$(ip -s -j link show "$1" | grep -oP '(?<="rx":{"bytes":)\d+')
    sleep 2
    new_rx_traffic=$(ip -s -j link show "$1" | grep -oP '(?<="rx":{"bytes":)\d+')
    rx_traffic=$(($((new_rx_traffic - old_rx_traffic)) / 2))
    echo "$rx_traffic"
}


check_tx_traffic () {
    # Check the TX traffic for specific interface of the system, and return the traffic
    old_tx_traffic=$(ip -s -j link show "$1" | grep -oP '(?<="tx":{"bytes":)\d+')
    sleep 2
    new_tx_traffic=$(ip -s -j link show "$1" | grep -oP '(?<="tx":{"bytes":)\d+')
    tx_traffic=$(($((new_tx_traffic - old_tx_traffic)) / 2))
    echo "$tx_traffic"
}


######################
#                    #
#  IV - MAIN SCRIPT  #
#                    #
######################

interface_name="$1"
if [ -z "$interface_name" ]; then
    echo -e "UNKNOWN - No network interface given."
    exit 3
fi

rx_traffic="$(check_rx_traffic "$interface_name")b/s"
tx_traffic="$(check_tx_traffic "$interface_name")b/s"

echo -e "OK - RX: $rx_traffic \\ TX: $tx_traffic | 'traffic_in'=$rx_traffic 'traffic_out'=$tx_traffic"
exit 0