#!/usr/bin/env bash
# sudo wget "https://xfonts.pro/xfonts_files/5e4ba999a0eae905e9ddddb5/files/JetBrainsMono-Regular.ttf"
# /usr/share/terminology/fonts - dar o wget aqui dentro
mydump_path='/opt/mydump'
git clone 'https://github.com/rhuan-pk/mydump.git' "${mydump_path}"
sudo ln -s ${mydump_path}/mydump.sh /usr/local/bin/mydump
sudo ln -s ${mydump_path}/refresh.sh /usr/local/bin/mydump-refresh
cat << EOF > /home/${USER}/.local/share/applications/
[Desktop Entry]
        Encoding=UTF-8
        Name=MyDump
        Icon=${mydump_path}/icons/logo.png
        Exec=/
        Terminal=false
        Type=Application
        Categories=Desenvolvimento
EOF
