# Atsumeru server - install/unistall systemd service for BASH

Downloading the installation script and executing it (I strongly recommend that you run it as a non-root user):
```shell
curl -s https://api.github.com/repos/OlegEnot/atsu-systemd/releases/latest | grep "browser_download_url.*atsu-install.sh" |  cut -d : -f 2,3 |  tr -d \" |  wget -O atsu-install.sh  -i - && \
chmod u+x atsu-install.sh && \
./atsu-install.sh
```
#

Downloading the deletion script and executing it (I strongly recommend that you run it as a non-root user):
```shell
curl -s https://api.github.com/repos/OlegEnot/atsu-systemd/releases/latest | grep "browser_download_url.*atsu-uninstall.sh" |  cut -d : -f 2,3 |  tr -d \" |  wget -O atsu-uninstall.sh  -i - && \
chmod u+x atsu-uninstall.sh && \
./atsu-uninstall.sh
```
#

**Important points:**

- A user is created, in the user group on behalf of which the script for the service with the home directory /opt/atsumeru is launched.

- The content is supposed to be stored in the same directory (symlinks are supported).

- The script works on debian based distributions

#

[GitHub](https://github.com/AtsumeruDev/Atsumeru) for Atsumeru

All info is available on [Atsumeru](https://atsumeru.xyz/) website
