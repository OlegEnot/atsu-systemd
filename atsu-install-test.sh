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
W='65'

if [ "$(id -u)" -eq 0 ]; then
        whiptail --msgbox --title " ( ；｀ヘ´) " "Run script not as root!" $H $W 3>&1 1>&2 2>&3
        exit 1
fi

if (whiptail --title " (」°ﾛ°)｣ " --yesno "Do you want to install the Atsumeru server service?." $H $W 3>&1 1>&2 2>&3); then

    psw=$(whiptail --title " ╭⚈¬⚈╮ " --passwordbox "Enter your \"sudo\" password and choose Ok to continue." $H $W 3>&1 1>&2 2>&3)

    if ( sudo -S -v <<< $psw ); then
        echo
        else
        whiptail --title " (ಥ﹃ಥ) " --msgbox "No valid sudo password" $H $W 3>&1 1>&2 2>&3
        exit 1
    fi
else
    whiptail --title " ok! (￣-￣)ゞ " --msgbox "Install aborted by user !" $H $W 3>&1 1>&2 2>&3
    exit
fi

# Web server port number request
us_port=$(whiptail --inputbox "Enter the port for atsumeru web service (press ENTER if port 31337 suits you)" $H $W 3>&1 1>&2 2>&3)

if [[ $us_port -ne 0 ]];
then
        port="$us_port"
else
        port="31337"
fi

pmem=$(free -t | grep -oP '\d+' | sed '1!d')
if [ "$pmem" -lt 1048576 ]; then
        if (whiptail --title " ┌( ‘o’)┐ " --yesno "You don't have enough RAM, more than ~1 GB is recommended." $H $W --no-button "No (abort install)" --yes-button "Don't care, LET'S GO!" 3>&1 1>&2 2>&3); then
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
                exit
        fi
fi

# Add a user from which the atsu service will be launched, the user will be in the group from which the script was launched
sudo useradd "${user}" -d "${dir}" -g "$USER" -N -m

# Allow the user running the script to change the directory ${dir} atsu
sudo chmod -R 774 "${dir}"

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
        echo "service not started succesfully, check logs.."
        whiptail --msgbox --title " Σ(‘◉⌓◉’) " "Service not started succesfully, check logs..." $H $W 3>&1 1>&2 2>&3
        exit
else
        adr=$(hostname -I | awk '{ print $1 }')
        whiptail --msgbox --title " (◕‿◕) " "< Admin > user created with password < ${pass##*:} >\nThe server is available at: < http://""$adr":"$port"" > \n\n\nDon't forget to change your password!" $H $W 3>&1 1>&2 2>&3
fi