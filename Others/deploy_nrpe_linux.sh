#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     deploy_nrpe_linux.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.07.24
# RELEASE            :     1.4.0
# USAGE SYNTAX       :     .\deploy_nrpe_linux.sh
#
# SCRIPT DESCRIPTION :     This script is used to deploy NRPE on Linux.
#
#==========================================================================================
#
#                 - RELEASE NOTES -
# v1.0.0  2023.07.24 - Louis GAMBART - Initial version
# v1.1.0  2023.07.26 - Louis GAMBART - Add clean_up function
# v1.2.0  2023.07.26 - Louis GAMBART - Redesign script output
# v1.3.0  2023.07.26 - Louis GAMBART - Add check to each command
# v1.4.0  2023.07.26 - Louis GAMBART - Replace hard config file by sed commands
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
Orange='\033[0;35m'     # Orange


####################
#                  #
#  II - VARIABLES  #
#                  #
####################

SCRIPT_NAME="deploy_nrpe_linux.sh"
NRPE_CONFIG_FILE="/etc/nrpe/centreon-nrpe3.cfg"


#####################
#                   #
#  III - FUNCTIONS  #
#                   #
#####################

print_help () {
    # Print help message
    echo -e """
    ${Green} SYNOPSIS
        ${SCRIPT_NAME} [-hv]

     DESCRIPTION
        This script is used to deploy NRPE on Linux.

     OPTIONS
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


clean_up () {
    # Clean up function for apt
    echo -e -n "${Yellow}Cleaning up...${No_Color}"
    if ! apt autoremove -y > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to clean up${No_Color}"
        exit 1
    fi
    rm /etc/apt/sources.list.d/centreon.list > /dev/null 2>&1
    rm /etc/apt/trusted.gpg.d/centreon.gpg > /dev/null 2>&1
    apt update > /dev/null 2>&1
    echo -e "${Green} OK\n${No_Color}"
}


install_nrpe () {
    # Install NRPE Agent for Centreon
    echo -e "${Yellow}\nInstalling NRPE...${No_Color}"

    echo -e -n "${Yellow}\n    * INFO - Creating user 'centreon-engine'...${No_Color}"
    if id "centreon-engine" >/dev/null 2>&1; then
        echo -e "${Orange} WARN - User 'centreon-engine' already exist${No_Color}"
    else
        echo -e "${Yellow} OK${No_Color}"
        useradd --create-home centreon-engine
    fi

    echo -e -n "${Yellow}    * INFO - Installing needed packages...${No_Color}"
    if ! apt install -y gnupg wget lsb-release > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to install needed packages${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Adding Centreon repository key...${No_Color}"
    if ! wget -qO- https://apt-key.centreon.com 2>/dev/null | gpg --dearmor > /etc/apt/trusted.gpg.d/centreon.gpg 2>&1; then
        echo -e "${Red} ERR - Unable to download Centreon GPG key${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Adding Centreon repository...${No_Color}"
    if ! echo "deb https://apt.centreon.com/repository/22.10/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/centreon.list;then
        echo -e "${Red} ERR - Unable to add Centreon repository${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Update packages list...${No_Color}"
    if ! apt update > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to update packages list${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Installing NRPE package...${No_Color}"
    if ! apt install -y centreon-nrpe3-daemon centreon-plugin-operatingsystems-linux-local > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to install NRPE package${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e "\n${Yellow}Installing NRPE...${Green} OK\n${No_Color}"
}


configure_nrpe () {
    # Configure NRPE Agent for Centreon
    echo -e "${Yellow}\nConfiguring NRPE...\n${No_Color}"

    # Get NRPE port
    read -r -p "    * NRPE port (default: 5666): " NRPE_PORT
    if [ -n "${NRPE_PORT}" ]; then
         echo -e -n "${Yellow}    * INFO - Changing NRPE port in ${NRPE_CONFIG_FILE}...${No_Color}"
         if ! sed -i "s/server_port=5666/server_port=${NRPE_PORT}/g" ${NRPE_CONFIG_FILE}; then
            echo -e "${Red} ERR - Unable to change NRPE port in ${NRPE_CONFIG_FILE}${No_Color}"
        fi
        echo -e "${Green} OK${No_Color}"
    fi

    # Get allowed hosts
    read -r -p "    * Allowed hosts to add (comma separated): " ALLOWED_HOSTS
    if [ -n "${ALLOWED_HOSTS}" ]; then
        echo -e -n "${Yellow}    * INFO - Adding allowed hosts to ${NRPE_CONFIG_FILE}...${No_Color}"
        if ! sed -i "s/allowed_hosts=127.0.0.1,::1/allowed_hosts=127.0.0.1,::1,${ALLOWED_HOSTS}/g" ${NRPE_CONFIG_FILE}; then
            echo -e "${Red} ERR - Unable to change allowed hosts in ${NRPE_CONFIG_FILE}${No_Color}"
        fi
        echo -e "${Green} OK${No_Color}"
    fi

    # Add NRPE commands to NRPE config file
    echo -e -n "${Yellow}    * INFO - Including NRPE commands file in NRPE config...${No_Color}"
    if ! sed -i "s/#include=<somefile.cfg>/include=\/etc\/nrpe\/commands.cfg/g" ${NRPE_CONFIG_FILE}; then
        echo -e "${Red} ERR - Unable to include commands.cfg in ${NRPE_CONFIG_FILE}${No_Color}"
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Writing NRPE commands file...${No_Color}"
    cat >> /etc/nrpe/commands.cfg <<EOF
# COMMAND DEFINITIONS
# command[<command_name>]=<command_line> \$ARG1\$ \$ARG2\$ \$ARG3\$

command[check_uptime]=/usr/lib/centreon/plugins/NRPE_check-uptime.sh
command[check_cpu]=/usr/lib/centreon/plugins/NRPE_check-cpu.sh
command[check_disk]=/usr/lib/centreon/plugins/NRPE_check-disk.sh \$ARG1\$
command[check_load]=/usr/lib/centreon/plugins/NRPE_check-load.sh
command[check_memory]=/usr/lib/centreon/plugins/NRPE_check-memory.sh
command[check_swap]=/usr/lib/centreon/plugins/NRPE_check-swap.sh
command[check_ping]=/usr/lib/centreon/plugins/NRPE_check-ping.sh \$ARG1\$
command[check_service]=/usr/lib/centreon/plugins/NRPE_check-service.sh \$ARG1\$
command[check_traffic]=/usr/lib/centreon/plugins/NRPE_check-traffic.sh \$ARG1\$
command[check_update]=/usr/lib/centreon/plugins/NRPE_check-update.sh
EOF
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Enabling NRPE service...${No_Color}"
    if ! systemctl enable centreon-nrpe3.service > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to enable NRPE service${No_Color}"
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Restarting NRPE service...${No_Color}"
    if ! systemctl restart centreon-nrpe3.service > /dev/null; then
        echo -e "${Red} ERR - Unable to restart NRPE service${No_Color}"
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e "\n${Yellow}Configuring NRPE...${Green} OK\n${No_Color}"
}


install_script () {
    # Install NRPE custom script
    echo -e "${Yellow}\nInstalling NRPE custom script...${No_Color}"

    echo -e -n "${Yellow}\n    * INFO - Installing git package...${No_Color}"
    if ! apt install -y git > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to install git package${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Downloading Centreon-scripts from GitHub...${No_Color}"
    if ! git clone https://github.com/Isnubi/Centreon-scripts.git /tmp/Centreon-scripts > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to download Centreon-scripts from GitHub${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Moving NRPE scripts to /usr/lib/centreon/plugins/...${No_Color}"
    if ! mv /tmp/Centreon-scripts/Bash/NRPE_* /usr/lib/centreon/plugins/ > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to move NRPE scripts to /usr/lib/centreon/plugins/${No_Color}"
        exit 1
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Changing NRPE scripts permissions...${No_Color}"
    if ! chmod +x /usr/lib/centreon/plugins/NRPE_* > /dev/null 2>&1; then
        echo -e "${Red} ERR - Unable to change NRPE scripts permissions${No_Color}"
    fi
    echo -e "${Green} OK${No_Color}"

    echo -e -n "${Yellow}    * INFO - Removing Centreon-scripts temporary directory...${No_Color}"
    rm -rf /tmp/Centreon-scripts
    echo -e "${Green} OK${No_Color}"

    echo -e "\n${Yellow}Installing NRPE custom script...${Green} OK\n\n${No_Color}"
}


#########################
#                       #
#  IV - SCRIPT OPTIONS  #
#                       #
#########################

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
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

echo -e "${Blue}Starting the script...${No_Color}\n"

clean_up
install_nrpe
configure_nrpe
install_script

echo -e "${Blue}...Script finished${No_Color}"