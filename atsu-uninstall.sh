#!/bin/bash
set -eou pipefail
# env
app="Atsumeru"
H='15'
W='65'

if [ "$(id -u)" -eq 0 ]; then
    whiptail --msgbox --title " ( ；｀ヘ´) " "Run script not as root/sudo!" $H $W
    exit 1
fi

if (whiptail --title " (」°ﾛ°)｣ " --yesno "Do you want to remove the Atsumeru server service?." $H $W 3>&1 1>&2 2>&3); then
exitstatus=$?
    psw=$(whiptail --title " ╭⚈¬⚈╮ " --passwordbox "Enter your \"sudo\" password and choose Ok to continue." $H $W 3>&1 1>&2 2>&3)
    if  ( sudo -S -v <<< "$psw" ); then
        echo
        else
        whiptail --title " (ಥ﹃ಥ) " --msgbox "No valid sudo password" $H $W 3>&1 1>&2 2>&3
        exit 1
    fi

    if [ $exitstatus = 0 ]; then
        sudo systemctl stop ${app,,}.service
        sudo systemctl disable ${app,,}.service
        sudo systemctl daemon-reload
    else
        whiptail --title " (☉ε ⊙ﾉ)ﾉ " --msgbox "Operation Cancel" $H $W
    fi
else
    whiptail --title " ok! (￣-￣)ゞ " --msgbox "Deletion aborted by user !" $H $W 3>&1 1>&2 2>&3
    exit
fi

if (whiptail --title " (シ. .)シ " --yesno "ATTENTION!!! THIS WILL DELETE ALL FILES IN THE DIRECTORY!!! \nDo you want to delete the server directory?" $H $W 3>&1 1>&2 2>&3); then
    sudo userdel -r ${app,,}
else
    whiptail --title " (ﾟρﾟ)ﾉ " --msgbox "Deletion a server-user and a server directory aborted by user !" $H $W 3>&1 1>&2 2>&3
    exit
fi
echo

if (whiptail --title " ＼(☆o◎)／ " --yesno "Do you want to purge OpenJRE 11 now?" $H $W 3>&1 1>&2 2>&3); then
    sudo apt purge openjdk-11-jre -y
    sudo apt autopurge -y
    unset psw
else
    whiptail --title " (☉ε ⊙ﾉ)ﾉ " --msgbox "Purge OpenJRE 11 aborted !" $H $W 3>&1 1>&2 2>&3
    unset psw
    exit
fi

whiptail --title " (o^▽^o) " --msgbox "Removal completed.\nThank you for using Atsumeru!" $H $W 3>&1 1>&2 2>&3