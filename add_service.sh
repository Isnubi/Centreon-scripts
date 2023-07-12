
for HOST in ${HOSTS}; do
    echo -e "${Yellow}Adding the service ${SERVICE_NAME} to the host ${HOST}...${No_Color}"
    if ! centreon -u "${CENTREON_LOGIN}" -p "${CENTREON_PASSWORD}" -o SERVICE -a add -v "${HOST};${SERVICE_NAME};${SERVICE_TEMPLATE_NAME}" ; then
        echo -e "${Red}Error while adding the service ${SERVICE_NAME} to the host ${HOST}${No_Color}\n"
    else
        echo -e "${Green}Service ${SERVICE_NAME} added to the host ${HOST}${No_Color}\n"
    fi
done

echo -e "${Green}Script finished${No_Color}"