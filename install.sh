#!/usr/bin/env bash
# sudo wget "https://xfonts.pro/xfonts_files/5e4ba999a0eae905e9ddddb5/files/JetBrainsMono-Regular.ttf"
# /usr/share/terminology/fonts - dar o wget aqui dentro
# urxvt -bg black -fg white +sb -fn 10x20 -bc -uc -lsp 1 -e 'mydump'
mydump_path='/opt/mydump'
sudo apt install ssh openssh-server sshpass terminator -y
git clone 'https://github.com/rhuan-pk/mydump.git' "${mydump_path}"
sudo ln -s ${mydump_path}/mydump.sh /usr/local/bin/mydump
sudo ln -s ${mydump_path}/mydump-start.sh /usr/local/bin/mydump-start
cat << EOF > /home/${USER}/.local/share/applications/mydump.desktop
[Desktop Entry]
        Encoding=UTF-8
        Name=MyDump
        Icon=${mydump_path}/icons/logo.png
        Exec=mydump-start
        Terminal=false
        Type=Application
EOF
sudo chmod +x /home/${USER}/.local/share/applications/mydump.desktop
