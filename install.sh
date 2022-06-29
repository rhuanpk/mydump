#!/usr/bin/env bash

cd /tmp
mydump_install_path='/opt/mydump'
mydump_desktop="/home/${USER}/.local/share/applications/mydump.desktop"
sudo apt install ssh openssh-server sshpass terminator multitail git wget -y
[ -e ${mydump_install_path} ] && {
        sudo rm -rfv ${mydump_install_path}
        sudo rm -fv /usr/local/bin/mydump
        sudo rm -fv /usr/local/bin/mydump-start
}
[ -e /usr/local/lib/mydump -o -e /usr/local/share/mydump ] && {
        sudo rm -rfv /usr/local/lib/mydump
        sudo rm -rfv /usr/local/share/mydump
}
sudo mkdir -pv /usr/local/lib/mydump
sudo mkdir -pv /usr/local/share/mydump/{icons,banner}
sudo git clone 'https://github.com/rhuan-pk/mydump.git' "${mydump_install_path}"
sudo chown -Rv ${USER}:${USER} ${mydump_install_path}/
sudo ln -sfv ${mydump_install_path}/bin/mydump-coleta.sh /usr/local/bin/mydump
sudo ln -sfv ${mydump_install_path}/bin/mydump-principal.sh /usr/local/bin/mydump-principal
sudo ln -sfv ${mydump_install_path}/bin/mydump-start.sh /usr/local/bin/mydump-start
sudo ln -sfv ${mydump_install_path}/bin/mydump-update.sh /usr/local/bin/mydump-update
sudo ln -sfv ${mydump_install_path}/bin/loading-bar.sh /usr/local/bin/loading-bar
sudo ln -sfv ${mydump_install_path}/lib/common-properties.lib /usr/local/lib/mydump/common-properties.lib
sudo ln -sfv ${mydump_install_path}/share/icons/logo.png /usr/local/share/mydump/icons/logo.png
sudo ln -sfv ${mydump_install_path}/share/banner/banner.txt /usr/local/share/mydump/banner/banner.txt
rm -fv ${mydump_desktop}
cat << EOF | tee ${mydump_desktop}
[Desktop Entry]
Encoding=UTF-8
Name=MyDump
Icon=/usr/local/share/mydump/icons/logo.png
Exec=mydump-start
Terminal=false
Type=Application
EOF
sudo chmod -v +x ${mydump_desktop}
