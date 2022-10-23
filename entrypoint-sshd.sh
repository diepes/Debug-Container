#!/bin/bash
## Entrypoint-sshd.sh installs and runs sshd, used for asible pipeline testing (Fake VM)
# Activate with docker run -e "root_password=Passw0rd" --entrypoint /entrypoint-sshd.sh
echo "#$0 installing openssh-server and allowing root ssh ..."
#apt-get update 
apt-get install -y openssh-server
mkdir /var/run/sshd
echo "root:${root_password:-Passw0rd}" | chpasswd
sed -i 's/^.*PermitRootLogin .*$/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

echo "# running /usr/sbin/sshd deamon ..."
/usr/sbin/sshd -D -e
