# Dosya Yolu: /tools/legacy/java/adoptjdk11.sh
# Amac: Eski CentOS Java 11 kurulum notunu arsivler
# Tool - Shell
# Version: 1.0.0
# Aciklama: Legacy OpenJDK 11 yum kurulumu; aktif OFBiz kurulumunda kullanilmaz
#
# Bagimli Oldugu Katman: Tool

#!/bin/bash

yum -y install java-11-openjdk.x86_64

cat <<'EOF' >> /etc/profile.d/javahome.sh
#!/bin/sh
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.17.0.8-2.el7_9.x86_64
export JRE_HOME=$JAVA_HOME/jre
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=$JAVA_HOME/jre/lib/ext:$JAVA_HOME/lib/tools.jar
EOF
