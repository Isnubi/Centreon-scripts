#!/usr/bin/env bash
#==========================================================================================
#
# SCRIPT NAME        :     deploy_nrpe_linux.sh
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.03.20
# RELEASE            :     1.0.0
# USAGE SYNTAX       :     .\deploy_nrpe_linux.sh
#
# SCRIPT DESCRIPTION :     This script is used to deploy NRPE on Linux.
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
Green='\033[0;32m'      # Green
Blue='\033[0;34m'       # Blue


####################
#                  #
#  II - VARIABLES  #
#                  #
####################

SCRIPT_NAME="deploy_nrpe_linux.sh"


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


install_nrpe () {
    # Install NRPE Agent for Centreon
    echo -e -n "${Yellow}Installing NRPE...${No_Color}"
    #check if user already exist
    if id "centreon-engine" >/dev/null 2>&1; then
        echo -e "${Red} WARN - User 'centreon-engine' already exist${No_Color}"
    else
        useradd --create-home centreon-engine
    fi
    apt install -y gpg > /dev/null 2>&1
    wget -qO- https://apt-key.centreon.com | gpg --dearmor > /etc/apt/trusted.gpg.d/centreon.gpg
    echo "deb https://apt.centreon.com/repository/22.10/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/centreon.list
    apt update > /dev/null 2>&1
    apt install -y centreon-nrpe3-daemon centreon-plugin-operatingsystems-linux-local > /dev/null 2>&1
    mkdir -p /var/lib/centreon/centplugins
    chown -R centreon-engine:centreon-engine /var/lib/centreon/centplugins
    echo -e "${Green} OK${No_Color}"
}


configure_nrpe () {
    # Configure NRPE Agent for Centreon
    echo -e -n "${Yellow}Configuring NRPE...\n${No_Color}"
    mv /etc/nrpe/centreon-nrpe3.cfg{,.bak}

    # Get NRPE port
    read -r -p "NRPE port (default: 5666): " NRPE_PORT
    if [ -n "${NRPE_PORT}" ]; then
        sed -i "s/server_port=5666/server_port=${NRPE_PORT}/g" /etc/nrpe/centreon-nrpe3.cfg
    fi
    # Get allowed hosts
    read -r -p "Allowed hosts: " ALLOWED_HOSTS
    if [ -n "${ALLOWED_HOSTS}" ]; then
        sed -i "s/allowed_hosts=127.0.0.1,::1/allowed_hosts=127.0.0.1,::1,${ALLOWED_HOSTS}/g" /etc/nrpe/centreon-nrpe3.cfg
    fi
    sed -i "s/#include=<somefile.cfg>/include=\/etc\/nrpe\/commands.cfg/g" /etc/nrpe/centreon-nrpe3.cfg

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
    systemctl enable centreon-nrpe3.service > /dev/null 2>&1
    systemctl restart centreon-nrpe3.service > /dev/null
    echo -e "${Yellow}Configuring NRPE... ${Green}OK${No_Color}"
}


install_script () {
    # Install NRPE custom script
    echo -e -n "${Yellow}Installing NRPE custom script...${No_Color}"
    apt install -y git > /dev/null 2>&1
    git clone https://github.com/Isnubi/Centreon-scripts.git /tmp/Centreon-scripts > /dev/null 2>&1
    mv /tmp/Centreon-scripts/Bash/NRPE_* /usr/lib/centreon/plugins/
    chmod +x /usr/lib/centreon/plugins/NRPE_*
    rm -rf /tmp/Centreon-scripts
    echo -e "${Green} OK${No_Color}"
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

install_nrpe
configure_nrpe
install_script

echo -e "${Blue}...Script finished${No_Color}"