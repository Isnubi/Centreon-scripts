#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-user-password-age.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2022.10.27
# RELEASE            :     v2.0.0
# USAGE SYNTAX       :     .\NRPE_check-user-password-age.sh [-u|--user <username>]
#
# SCRIPT DESCRIPTION :     This script is used to check the password age of a user and return a status code to Centreon.
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# v1.0.0  2022.10.27 - Louis GAMBART - Initial version
# v1.1.0  2022.10.27 - Louis GAMBART - Use another bin to secure the script
# v1.2.0  2022.10.27 - Louis GAMBART - Add language control for french based system
# v1.3.0  2022.10.27 - Louis GAMBART - Remove language control and force chage command execution in english
# v1.4.0  2022.10.28 - Louis GAMBART - Add critical exit code for password older than one year
# v1.5.0  2022.10.31 - Louis GAMBART - Change test order to avoid warning when password is older than one year
# v1.5.1  2022.10.31 - Louis GAMBART - Add color in echo
# v2.0.0  2023.07.26 - Louis GAMBART - Rework this script to follow my new template
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
Green='\033[0;32m'      # Green
Blue='\033[0;34m'       # Blue


####################
#                  #
#  II - VARIABLES  #
#                  #
####################

SCRIPT_NAME="NRPE_check-user-password-age.sh"

WARNING_THRESHOLD=180
CRITICAL_THRESHOLD=365


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

print_help () {
    # Print help message
    echo -e """
    ${Green} SYNOPSIS
        ${SCRIPT_NAME} [-u|--user <username>] [-hv]

     DESCRIPTION
        This script is used to check the password age of a user and return a status code to Centreon.

     OPTIONS
        -u, --user         Specify the user to check
        -h, --help         Print the help message
        -v, --version      Print the script version
    ${No_Color}
    """
}


print_version () {
    # Print version message
    echo -e """
    ${Green}
    version       ${SCRIPT_NAME} 1.0.0
    author        Louis GAMBART (https://louis-gambart.fr)
    license       GNU GPLv3.0
    script_id     0
    """
}


get_password_delta () {
    # Get the delta between today and the last password change of a user
    # $1 : username

    out=$(LANG='' chage -l "$1" | grep 'Last password change' | awk '{print $5, $6, $7' | xargs -I {} date -d "{}" +%Y-%m-%d)
    now=$(date +%Y-%m-%d)
    delta=$(( ($(date -d "$now" +%s) - $(date -d "$out" +%s)) / (60*60*24) ))
    echo "$delta"
}


#########################
#                       #
#  IV - SCRIPT OPTIONS  #
#                       #
#########################

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -u|--user)
            username="$2"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        -v|--version)
            print_version
            exit 0
            ;;
        *)
            echo -e "${Red}ERR - Unknown option: $key${No_Color}"
            print_help
            exit 0
            ;;
    esac
    shift
done


####################
#                  #
#  V - ROOT CHECK  #
#                  #
####################

echo -e -n "${Yellow}Checking if you are root...${No_Color}"
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${Red} ERR - Run the script as root${No_Color}"
    exit 1
else
    echo -e "${Green} OK${No_Color}\n"
fi


######################
#                    #
#  VI - MAIN SCRIPT  #
#                    #
######################

if [ -z "$username" ]; then
    username='root'
fi

if ! id "$username" >/dev/null 2>&1; then
    echo -e "UNKNOWN - User ${username} does not exist on this system"
    exit 3
fi

delta=$(get_password_delta "$username")

if [ "$delta" -gt $CRITICAL_THRESHOLD ]; then
    echo -e "CRITICAL - User $username has a password that is older than 365 days"
    echo "Last password change is $delta days ago"
    exit 2
elif [ "$delta" -lt $CRITICAL_THRESHOLD ] && [ "$delta" -gt $WARNING_THRESHOLD ]; then
    echo -e "WARNING - User $username has a password that is older than 180 days"
    echo "Last password change is $delta days ago"
    exit 1
else
    echo -e "OK - User $username has a password that is younger than 180 days"
    echo "Last password change is $delta days ago"
    exit 0
fi