# Dosya Yolu: /tools/legacy/java/adoptjdk8.sh
# Amac: Eski AdoptOpenJDK 8 CentOS kurulum notunu arsivler
# Tool - Shell
# Version: 1.0.0
# Aciklama: Legacy AdoptOpenJDK 8 repository kurulumu; aktif OFBiz kurulumunda kullanilmaz
#
# Bagimli Oldugu Katman: Tool

#!/bin/bash

cat <<'EOF' > /etc/yum.repos.d/adoptopenjdk.repo
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF

yum -y install adoptopenjdk-8-hotspot

cat <<'EOF' >> /etc/profile.d/javahome.sh
#!/bin/sh
export JAVA_HOME=/usr/java/default
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar
EOF
