#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     Centreon_add_service_to_host_by_groupname.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.07.05
# RELEASE            :     1.1.0
# USAGE SYNTAX       :     .\Centreon_add_service_to_host_by_groupname.sh
#
# SCRIPT DESCRIPTION :     This script add a service to all the host in a host group in Centreon
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# v1.0.0  2023.07.05 - Louis GAMBART - Initial version
# v1.1.0  2023.07.06 - Louis GAMBART - Add options for all the mandatory variables
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

SCRIPT_NAME="Centreon_add_service_to_host_by_groupname.sh"

# Set variable for the options
HOST_GROUP_NAME=''
SERVICE_NAME=''
SERVICE_TEMPLATE_NAME=''
CENTREON_LOGIN=''
CENTREON_PASSWORD=''


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

print_help () {
    # Print help message
    echo -e """
    ${Green} SYNOPSIS
        ${SCRIPT_NAME} [-l <login>] [-p <password>] [-hg <hostgroup>] [-st <servicetemplate>] [-s <service>] [-hv]

     DESCRIPTION
        This script add a service to all the host in a host group in Centreon

     OPTIONS
        -l, --login        Centreon login
        -p, --password     Centreon password
        -hg, --hostgroup   Host group name
        -st, --servicetemplate
                           Service template name in Centreon
        -s, --service      Service name to display in Centreon

        -h, --help         Print the help message
        -v, --version      Print the script version
    ${No_Color}
    """
}


print_version () {
    # Print version message
    echo -e """
    ${Green}
    version       ${SCRIPT_NAME} 1.1.0
    author        Louis GAMBART (https://louis-gambart.fr)
    license       GNU GPLv3.0
    script_id     0
    ${No_Color}
    """
}


#########################
#                       #
#  IV - SCRIPT OPTIONS  #
#                       #
#########################

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -l|--login)
            CENTREON_LOGIN="$2"
            shift
            ;;
        -p|--password)
            CENTREON_PASSWORD="$2"
            shift
            ;;
        -hg|--hostgroup)
            HOST_GROUP_NAME="$2"
            shift
            ;;
        -st|--servicetemplate)
            SERVICE_TEMPLATE_NAME="$2"
            shift
            ;;
        -s|--service)
            SERVICE_NAME="$2"
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
            echo -e "${Red}Unknown option: $key${No_Color}"
            print_help
            exit 0
            ;;
    esac
    shift
done


#######################
#                     #
#  V - OPTIONS CHECK  #
#                     #
#######################

echo -e "${Yellow}Checking if all the options are set...${No_Color}"
if [[ -z "${CENTREON_LOGIN}" ]]; then
    echo -e "${Red}Please set the Centreon login${No_Color}"
    print_help
    exit 1
elif [ -z "${CENTREON_PASSWORD}" ]; then
    echo -e "${Red}Please set the Centreon password${No_Color}"
    print_help
    exit 1
elif [ -z "${HOST_GROUP_NAME}" ]; then
    echo -e "${Red}Please set the host group name${No_Color}"
    print_help
    exit 1
elif [ -z "${SERVICE_TEMPLATE_NAME}" ]; then
    echo -e "${Red}Please set the service template name${No_Color}"
    print_help
    exit 1
elif [ -z "${SERVICE_NAME}" ]; then
    echo -e "${Red}Please set the service name${No_Color}"
    print_help
    exit 1
else
    echo -e "${Green}All the options are set${No_Color}\n"
fi



#####################
#                   #
#  VI - ROOT CHECK  #
#                   #
#####################

echo -e "${Yellow}Checking if you are root...${No_Color}"
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${Red}Please run as root${No_Color}"
    exit 1
else
    echo -e "${Green}You are root${No_Color}\n"
fi


#######################
#                     #
#  VII - MAIN SCRIPT  #
#                     #
#######################

echo -e "${Yellow}Starting the script...${No_Color}\n"

echo -e "${Yellow}Getting all the host in the host group ${HOST_GROUP_NAME}...${No_Color}\n"
HOSTS=$(centreon -u "${CENTREON_LOGIN}" -p "${CENTREON_PASSWORD}" -o HG -a getmember -v "${HOST_GROUP_NAME}" | cut -d ';' -f2 | tail -n +2)

echo -e "${Yellow}Checking if the host group ${HOST_GROUP_NAME} is empty...${No_Color}\n"
if [[ -z "${HOSTS}" ]]; then
    echo -e "${Red}${HOST_GROUP_NAME} is empty...${No_Color}"
    exit 1
fi

for HOST in ${HOSTS}; do
    echo -e "${Yellow}Adding the service ${SERVICE_NAME} to the host ${HOST}...${No_Color}"
    if ! centreon -u "${CENTREON_LOGIN}" -p "${CENTREON_PASSWORD}" -o SERVICE -a add -v "${HOST};${SERVICE_NAME};${SERVICE_TEMPLATE_NAME}" ; then
        echo -e "${Red}Error while adding the service ${SERVICE_NAME} to the host ${HOST}${No_Color}\n"
    else
        echo -e "${Green}Service ${SERVICE_NAME} added to the host ${HOST}${No_Color}\n"
    fi
done

echo -e "${Green}Script finished${No_Color}"