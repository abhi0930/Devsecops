#!/bin/bash

# Initializing variables
file_to_find="../backend/.env.docker"
alreadyUpdate=$(sed -n "4p" ../backend/.env.docker)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Use curl to fetch the public IPv4 address from the metadata service
ipv4_address=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo -e " ${GREEN}System Public Ipv4 address ${NC} : ${ipv4_address}"

if [[ "${alreadyUpdate}" == "FRONTEND_URL=\"http://${ipv4_address}:5173\"" ]]
then
        echo -e "${YELLOW}${file_to_find} file is already updated to the current host's Ipv4 ${NC}"
        exit -1;
else
        if [ -f ${file_to_find} ]
        then
                echo -e "${GREEN}${file_to_find}${NC} found.."
                echo -e "${YELLOW}Configuring env variables in ${NC} ${file_to_find}"
                sleep 7s;
                sed -i -e "s|FRONTEND_URL.*|FRONTEND_URL=\"http://${ipv4_address}:5173\"|g" ${file_to_find}
                echo -e "${GREEN}env variables configured..${NC}"
        else
                echo -e "${RED}ERROR : File not found..${NC}"
        fi
fi
