# Dosya Yolu: /tools/legacy/ofbiz/ofbiz-linux-18.12.07.sh
# Amac: Eski OFBiz 18.12.07 tek-surum kurulum scriptini arsivler
# Tool - Shell
# Version: 1.1.0
# Aciklama: Tarihsel CentOS tabanli kurulum; yeni kurulumlarda controllers/ofbiz.sh kullanilmalidir
#
# Bagimli Oldugu Katman: Tool

#!/bin/bash

read -p "Please enter your website name (ornek xxx.com): " website
if [[ -z "$website" ]]; then
    echo "ERROR: The website name is invalid or blank."
    exit 1
fi

cd /tmp
wget -O oraclejdk8.sh https://raw.githubusercontent.com/TurkuazLabs/TurkuazOFBiz/main/tools/legacy/java/oraclejdk8.sh
bash oraclejdk8.sh

yum -y install perl-Digest-SHA

mkdir -p /usr/local/ofbiz
cd /usr/local/ofbiz
wget https://archive.apache.org/dist/ofbiz/apache-ofbiz-18.12.07.zip
unzip apache-ofbiz-18.12.07.zip -d /usr/local/ofbiz

IP_ADDRESS=( $(hostname -I) )

sed -i "s/host-headers-allowed=localhost,127.0.0.1,demo-trunk.ofbiz.apache.org,demo-stable.ofbiz.apache.org,demo-next.ofbiz.apache.org/host-headers-allowed=localhost,127.0.0.1,demo-trunk.ofbiz.apache.org,demo-stable.ofbiz.apache.org,demo-next.ofbiz.apache.org,$website,${IP_ADDRESS[0]}/"     /usr/local/ofbiz/apache-ofbiz-18.12.07/framework/security/config/security.properties

cd /usr/local/ofbiz/apache-ofbiz-18.12.07
sh gradle/init-gradle-wrapper.sh
./gradlew loadAll ofbiz
./gradlew ofbiz
