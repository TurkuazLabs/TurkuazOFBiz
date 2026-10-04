# Dosya Yolu: /tools/legacy/server/squid.sh
# Amac: Eski CentOS Squid proxy kurulum notunu arsivler
# Tool - Shell
# Version: 1.0.0
# Aciklama: Legacy Squid kurulum ve servis baslatma komutlari
#
# Bagimli Oldugu Katman: Tool

#!/bin/bash

yum -y install squid
systemctl start squid
systemctl enable squid
systemctl status squid
