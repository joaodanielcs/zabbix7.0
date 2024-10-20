#!/bin/bash
# Zabbix 7.0 lts on LXC DEBIAN 12 - By João Daniel  (f6:b6:e4:96:66:e5)
clear
read -sp "Insira a senha que deve ser usada no banco de dados: " passDB

apt update > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1
apt install sudo -y
timedatectl set-timezone America/Sao_Paulo
sudo apt install apt-transport-https curl -y
sudo mkdir -p /etc/apt/keyrings
sudo curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
sudo bash -c 'cat <<EOF > /etc/apt/sources.list.d/mariadb.sources
# MariaDB 11 Rolling repository list - created 2024-10-20 16:01 UTC
# https://mariadb.org/download/
X-Repolib-Name: MariaDB
Types: deb
# deb.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# URIs: https://deb.mariadb.org/11/debian
URIs: https://mirror.nodesdirect.com/mariadb/repo/11.rolling/debian
Suites: bookworm
Components: main
Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp
EOF'
sudo apt update
sudo apt install mariadb-server -y
clear
sudo systemctl status mariadb --no-pager
mariadb -uroot -e "alter user root@localhost identified by '\$passDB';"
sudo apt install apache2 -y
clear
sudo apt install php php-{cgi,common,mbstring,net-socket,gd,xml-util,mysql,bcmath,imap,snmp} -y
sudo apt install libapache2-mod-php -y
clear
wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian12_all.deb
dpkg -i zabbix-release_latest+debian12_all.deb
sudo apt update
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent -y
clear
mariadb -uroot -pzabbix_DB -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin; CREATE USER zabbix@localhost IDENTIFIED BY '\$passDB'; GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost; SET GLOBAL log_bin_trust_function_creators = 1;"
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mariadb --default-character-set=utf8mb4 -uzabbix -pzabbix_DB zabbix
mariadb -uroot -pzabbix_DB -e "SET GLOBAL log_bin_trust_function_creators = 0;"
sudo sed -i 's/^# DBPassword=.*/DBPassword=\$passDB/' /etc/zabbix/zabbix_server.conf
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2
clear
sudo apt install -y neofetch
neofetch
bash -c 'echo -e "reset\nneofetch\nsystemctl list-units --type service | egrep \"apache2|mariadb|ssh\"" >> /etc/profile.d/mymotd.sh && chmod +x /etc/profile.d/mymotd.sh'
echo > /etc/motd
history -c
