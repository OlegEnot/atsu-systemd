#!/bin/bash
set -eou pipefail

# env
app="Atsumeru"
repoowner="AtsumeruDev"
dir="/opt/${app,,}"
user="${app,,}"
update_="sudo apt update "
install_="sudo apt install "
RED='\033[0;31m'
NC='\033[0m'

# Web server port number request
read -r -p "Enter the port for atsumeru web service (press ENTER if port 31337 suits you) " us_port
if [[ $us_port -ne 0 ]];
then
        port="$us_port"
        echo The server will listen on the port \-\> "$port" ;
else
        port="31337"
        echo The server will listen on the default port \-\> "$port" ;
fi

# If there are problems with server, or if errors like <OutOfMemoryException> appear in the console/logs, you probably need to increase maximum amount of memory that Atsumeru can use in megabytes.

heap="4096"


# Checking for Java and, in case of absence, installing openJRE 11 (apt)
echo Java JRE -
if type -p java; then
    echo Found Java executable in PATH
    _java=java
elif [[ -n $JAVA_HOME ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo Found Java executable in JAVA_HOME
    _java="$JAVA_HOME/bin/java"
else
    read -r -p "JAVA_HOME not found. Do you want to install recommended OpenJDK 11 now? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
                echo "Installing OpenJRE 11 "
                $update_
                $install_ openjdk-11-jre -y
        else
               echo "Installation aborted !"
               exit
    fi
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo Version "$version"
fi

# Add a user from which the atsu service will be launched, the user will be in the group from which the script was launched
sudo useradd ${user} -d ${dir} -g $USER -N -m

# Allow the user running the script to change the directory ${dir} atsu
sudo chmod -R 774 ${dir}

# Downloading the last version of the fire engine from github
sudo curl -s https://api.github.com/repos/${repoowner}/${app}/releases/latest | grep "browser_download_url.*.jar" |  cut -d : -f 2,3 |  tr -d \" |  wget -O ${dir}/${app}.jar -i -

# Creating a file of service variables, if it’s not very easy, after installation you can mark the parameters
sudo cat << EOF > ${dir}/.env
port=${port}
heap=${heap}
app=${app}
user=${app,,}
EOF

# Creating a service file and running it
sudo cat << EOF > $dir/${app,,}.service

[Unit]
Description = ${app}
After = network.target

[Service]
User = ${user}
Group = $USER
Type = simple
EnvironmentFile=${dir}/.env
ExecStart = java -Xmx${heap}m -Dserver.port=${port} -jar ${app}.jar
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

sudo mv -f $dir/${app,,}.service /etc/systemd/system/${app,,}.service
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
        exit
else
        echo -e Admin user created with password  ${RED}${pass##*:}${NC}
fi

adr=$(hostname -I | awk '{ print $1 }')
echo -e The server is available at\: ${RED}http\://"$adr:$port"${NC}
read -r -p "Enter to the end"