#!/usr/bin/env bash

mydump_path='/opt/mydump'
mydump_desktop="/home/${USER}/.local/share/applications/mydump.desktop"
sudo apt install ssh openssh-server sshpass terminator -y
[ -e ${mydump_path} ] && {
        sudo rm -rf ${mydump_path}
        sudo rm -f /usr/local/bin/mydump
        sudo rm -f /usr/local/bin/mydump-start
}
[ -e /usr/local/lib/mydump -o -e /usr/local/share/mydump ] && {
        sudo rm -rf /usr/local/lib/mydump
        sudo rm -rf /usr/local/share/mydump
        sudo mkdir -p /usr/local/lib/mydump
        sudo mkdir -p /usr/local/share/mydump/{icons,banner}
}
sudo git clone 'https://github.com/rhuan-pk/mydump.git' "${mydump_path}"
sudo ln -s ${mydump_path}/bin/mydump-coleta.sh /usr/local/bin/mydump
sudo ln -s ${mydump_path}/bin/mydump-principal.sh /usr/local/bin/mydump-principal
sudo ln -s ${mydump_path}/bin/mydump-start.sh /usr/local/bin/mydump-start
sudo ln -s ${mydump_path}/bin/loading-bar.sh /usr/local/bin/loading-bar
sudo ln -s ${mydump_path}/lib/common-properties.lib /usr/local/lib/mydump/common-properties.lib
sudo ln -s ${mydump_path}/share/icons/logo.png /usr/local/share/mydump/icons/logo.png
sudo ln -s ${mydump_path}/share/banner/banner.txt /usr/local/share/mydump/banner/banner.txt
cat << EOF | tee ${mydump_desktop}
[Desktop Entry]
Encoding=UTF-8
Name=MyDump
Icon=/usr/local/share/mydump/icons/logo.png
Exec=mydump-start
Terminal=false
Type=Application
EOF
sudo chmod +x ${mydump_desktop}