# Dosya Yolu: /tools/legacy/server/certbot.sh
# Amac: Eski yum ve pip tabanli Certbot kurulum notunu arsivler
# Tool - Shell
# Version: 1.0.0
# Aciklama: Legacy CentOS Certbot kurulumu; aktif OFBiz kurulumundan bagimsizdir
#
# Bagimli Oldugu Katman: Tool

sudo yum -y install python3 augeas-libs
sudo yum -y remove certbot
sudo python3 -m venv /opt/certbot/
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
