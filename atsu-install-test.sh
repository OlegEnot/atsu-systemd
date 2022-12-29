#!/bin/bash
set -eou pipefail

# env
app="Atsumeru"
repoowner="AtsumeruDev"
dir="/opt/${app,,}"
user="${app,,}"
update_="sudo apt update "
install_="sudo apt install "
H='15'
W='75'

if [ "$(id -u)" -eq 0 ]; then
        whiptail --msgbox --title " ( ；｀ヘ´) " "Run script not as root!" $H $W 3>&1 1>&2 2>&3
        exit 1
fi

# Menu
menu=$(whiptail --title " ∠( ᐛ 」∠)＿ " --menu "Choose an option" $H $W 8 3>&1 1>&2 2>&3 \
"1" "Install the Atsumeru server service." \
"2" "Update the Atsumeru server service." \
"3" "Uninstall the Atsumeru server service.")

# Valid sudo password
psw=$(whiptail --title " ╭⚈¬⚈╮ " --passwordbox "Enter your \"sudo\" password and choose Ok to continue." $H $W 3>&1 1>&2 2>&3)
if ( sudo -S -v <<< "$psw" ); then
        echo
else
        whiptail --title " (ಥ﹃ಥ) " --msgbox "No valid sudo password?" $H $W 3>&1 1>&2 2>&3
        exit 1
fi

# ------------------------------------------------------------ menu = 1 ------------------------------------------------------------
if [ "$menu" -eq 1 ]; then

stat=$(sudo systemctl show -p ActiveState --value ${app,,})
if [ "$stat" == "active" ]; then
        whiptail --msgbox --title " Σ(･ิ¬･ิ) " "Wait a minute! But atsumeru is already working for you! \nMaybe you want to check the update?" $H $W 3>&1 1>&2 2>&3
        exit
fi

# Web server port number request
us_port=$(whiptail --title " へ_(‾◡◝ )> " --inputbox "Enter the port for atsumeru web service (press ENTER if port 31337 suits you)" $H $W 3>&1 1>&2 2>&3)

if [[ $us_port -ne 0 ]];
then
        port="$us_port"
else
        port="31337"
fi

# Checking RAM
pmem=$(free -t | grep -oP '\d+' | sed '1!d')
if [ "$pmem" -lt 1048576 ]; then
        if (whiptail --title " ┌( ‘o’)┐ " --yesno "You don't have enough RAM, more than ~1 GB is recommended." $H $W --no-button "No (I'm afraid)" --yes-button "Don't care, LET'S GO!" 3>&1 1>&2 2>&3); then
                echo
        else
                exit
        fi
fi

# Checking for Java and, in case of absence, installing openJRE 11 (apt)
if type -p java; then
        _java=java
else
        if (whiptail --title " ｢(ﾟﾍﾟ)　Errrrm… " --yesno "JAVA_HOME not found. Do you want to install recommended OpenJRE 11 now?" $H $W --no-button "No (abort install)" --yes-button "Yes" 3>&1 1>&2 2>&3); then
                $update_
                $install_ openjdk-11-jre -y
        else
                whiptail --title " ★｡･:¯\(ツ)/¯:･ﾟ★ " --msgbox "Atsumeru can't work without java..." $H $W 3>&1 1>&2 2>&3
                exit
        fi
fi

# Add a user from which the atsu service will be launched, the user will be in the group from which the script was launched
sudo useradd "${user}" -d "${dir}" -g "$USER" -N -m

# Allow the user running the script to change the directory ${dir} atsu
sudo chmod -R 774 "${dir}"
echo "Please wait a minute..."
# Downloading the last version of the fire engine from github
curl -s https://api.github.com/repos/${repoowner}/${app}/releases/latest | grep "browser_download_url.*.jar" |  cut -d : -f 2,3 |  tr -d \" |  wget -q -O "${dir}"/${app}.jar -i -

# Creating a file of service variables, if it’s not very easy, after installation you can mark the parameters
cat << EOF > "${dir}"/.env
port=${port}
app=${app}
user=${app,,}
EOF

# Creating a service file and running it
cat << EOF > "$dir"/${app,,}.service

[Unit]
Description = ${app}
After = network.target

[Service]
User = ${user}
Group = $USER
Type = simple
EnvironmentFile=${dir}/.env
ExecStart = java -Dserver.port=${port} -jar ${app}.jar
ExecReload = /bin/kill -HUP \${MAINPID}
ExecStop = /bin/kill -INT \${MAINPID}

TimeoutSec = 30
WorkingDirectory = ${dir}
Restart = on-failure
RestartSec = 5s
LimitNOFILE = 4096

[Install]
WantedBy = multi-user.target
EOF

sudo mv -f "$dir"/${app,,}.service /etc/systemd/system/${app,,}.service
sudo systemctl daemon-reload
sudo systemctl start ${app,,}.service
sudo systemctl enable ${app,,}.service

# Output to the console the Admin password from the launch logs, if any
sleep 10
pass="$(sudo journalctl -u ${app,,} --since "1min ago" | grep -oP 'Admin user created with password = \K.*$' | tail -1)"
max_retry=10
counter=0

until [ -n "$pass" ] || [ $counter -ge $max_retry ]
do
        sleep 30
        pass="$(sudo journalctl -u ${app,,} --since "1min ago" | grep -oP 'Admin user created with password = \K.*$' | tail -1)"
        ((counter++))
done

if  [ $counter -ge $max_retry ]
then
        whiptail --msgbox --title " Σ(‘◉⌓◉’) " "Service not started succesfully, check logs..." $H $W 3>&1 1>&2 2>&3
        exit
else
        adr=$(hostname -I | awk '{ print $1 }')
        whiptail --msgbox --title " (◕‿◕) " "< Admin > user created with password < ${pass##*:} >\nThe server is available at: < http://""$adr":"$port"" > \nUse it for authorization through 'Atsumeru manager'.\n\nDon't forget to change your password!" $H $W 3>&1 1>&2 2>&3
fi
fi
# ------------------------------------------------------------ end menu = 1 ------------------------------------------------------------

# ------------------------------------------------------------ menu = 2 ------------------------------------------------------------
if [ "$menu" -eq 2 ]; then
        stat=$(sudo systemctl show -p ActiveState --value ${app,,})
        if [ "$stat" == "active" ]; then
                echo "Please wait a minute..."
                curl -s https://api.github.com/repos/${repoowner}/${app}/releases/latest | grep "browser_download_url.*.jar" |  cut -d : -f 2,3 |  tr -d \" |  wget -q -O /tmp/${app}.jar -i -
                # Check atsumeru version
                CurrV=$(unzip -p -c "$dir"/"$app".jar META-INF/MANIFEST.MF | grep -oP 'Implementation-Version: \K\d+.*\b')
                ExpecV=$(unzip -p -c /tmp/"$app".jar META-INF/MANIFEST.MF | grep -oP 'Implementation-Version: \K\d+.*\b')
                if [ "$CurrV" == "$ExpecV" ]; then
                        whiptail --title " ok! (￣-￣)ゞ " --msgbox "No need update !" $H $W 3>&1 1>&2 2>&3
                else
                        printf -v versions '%s\n%s' "$CurrV" "$ExpecV"
                        if [[ $versions = "$(sort -V <<< "$versions")" ]]; then
                                echo 'Update run!'
                                sudo systemctl stop ${app,,}.service
                                mv -f /tmp/${app}.jar "$dir"/${app}.jar
                                sudo systemctl start ${app,,}.service
                                sleep 2
                                stat=$(sudo systemctl show -p ActiveState --value ${app,,})
                                if [ "$stat" == "active" ]; then
                                        whiptail --title " ok! (￣-￣)ゞ " --msgbox "Update complete !" $H $W 3>&1 1>&2 2>&3
                                else
                                        whiptail --title " Σ(‘◉⌓◉’) " --msgbox "Failed to start service after update. \nCheck logs... /nBad luck." $H $W 3>&1 1>&2 2>&3
                                        exit 1
                                fi
                        else
                                whiptail --title " ok! (￣-￣)ゞ " --msgbox "No need update !" $H $W 3>&1 1>&2 2>&3
                                exit
                        fi
                fi
        else
                whiptail --title " ｢(ﾟﾍﾟ)　Errrrm… " --msgbox "No running service found !\nUpdate aborted." $H $W 3>&1 1>&2 2>&3
                exit 1
        fi
fi
# ------------------------------------------------------------ end menu = 2 ------------------------------------------------------------

# ------------------------------------------------------------ menu = 3 ------------------------------------------------------------
if [ "$menu" -eq 3 ]; then
        check=$(whiptail --title " (」°ﾛ°)｣ " --checklist \
"What exactly do you want to remove?" $H $W 5 3>&1 1>&2 2>&3 \
"1" "Atsumeru server service" ON \
"2" "Server directory !!! will delete all files in $dir !!!" OFF \
"3" "Purge OpenJRE 11" OFF)

        if [[ "$check" =~ .*1.* ]]; then
                sudo systemctl stop ${app,,}.service
                sudo systemctl disable ${app,,}.service
                sudo systemctl daemon-reload
        fi

        if [[ "$check" =~ .*2.* ]]; then
                sudo userdel -r ${app,,}
        fi

        if [[ "$check" =~ .*3.* ]]; then
                sudo apt purge openjdk-11-jre -y
                sudo apt autopurge -y
        fi

        whiptail --title " (o^▽^o) " --msgbox "Removal completed.\nThank you for using Atsumeru!" $H $W 3>&1 1>&2 2>&3
fi
# ------------------------------------------------------------ end menu = 3 ------------------------------------------------------------