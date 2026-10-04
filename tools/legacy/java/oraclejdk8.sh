# Dosya Yolu: /tools/legacy/java/oraclejdk8.sh
# Amac: Eski Oracle JDK 8 RPM kurulum notunu arsivler
# Tool - Shell
# Version: 1.0.0
# Aciklama: Legacy Oracle JDK 8 kurulumu; aktif OFBiz kurulumunda kullanilmaz
#
# Bagimli Oldugu Katman: Tool

#!/bin/bash

wget -nc https://github.com/frekele/oracle-java/releases/download/8u92-b14/jdk-8u92-linux-x64.rpm
sudo rpm -i jdk-8u92-linux-x64.rpm

cat <<'EOF' >> /etc/profile.d/javahome80.sh
#!/bin/sh
export JAVA_HOME=/usr/java/default
export JRE_HOME=$JAVA_HOME/jre
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar
EOF

source /etc/profile.d/javahome80.sh
