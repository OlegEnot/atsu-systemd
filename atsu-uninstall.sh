#!/bin/bash

# env
app="Atsumeru"
dir="/opt/${app,,}"
user="${app,,}"
purge_="sudo apt purge"
RED='\033[0;31m'
NC='\033[0m'

read -r -p "Do you want to remove the Atsumeru server service?? [y/N] " response_sys
    if [[ "$response_sys" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        echo "Removing a ${app} service!"
        sudo systemctl stop ${app,,}.service
		sudo systemctl disable ${app,,}.service
		sudo systemctl daemon-reload
    else
		echo "Deletion aborted by user !"
		exit
    fi

read -r -p "ATTENTION!!! THIS WILL DELETE ALL FILES IN THE DIRECTORY!!! Do you want to delete the server directory? [y/N] " response_dir
    if [[ "$response_dir" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
                echo "Deleting a server-user and a server directory with all data!"
                sudo userdel -r ${app,,}
        else
               echo "Deletion a server-user and a server directory aborted by user !"
    fi
echo
read -r -p "Do you want to purge OpenJRE 11 now? [y/N] " response_jre
    if [[ "$response_jre" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
                echo "Purge OpenJRE 11 "
                $purge_ openjdk-11-jre -y
        else
               echo "Purge OpenJRE 11 aborted !"
    fi
	
echo "Removal completed. Thank you for using Atsumeru!"