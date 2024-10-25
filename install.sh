#!/bin/bash
# Zabbix 7.0 lts on LXC DEBIAN 12 - By João Daniel  (f6:b6:e4:96:66:e5)

clear
# Variaveis
GREEN="\033[0;32m"
BLUE="\033[0;34m"
WHITE="\033[0;37m"
BOLD="\033[1m"
RESET="\033[0m"
IP=$(hostname -I | awk '{print $1}')
host=$(hostname)

# Pergunta a senha para usar no MariaDB
read -sp "Insira a senha que deve ser usada no MariaDB: " passDB
clear

# Atualize o sistema
sudo apt update && sudo apt upgrade -y

# Atualize timezone
timedatectl set-timezone America/Sao_Paulo

# Instalar o ccze (color service), Neofetch e agente qemu
sudo apt install -y ccze
sudo apt install -y neofetch
neofetch
bash -c 'echo -e "reset\nneofetch\nsystemctl list-units --type service | egrep \"apache2|mariadb|ssh\"" >> /etc/profile.d/mymotd.sh && chmod +x /etc/profile.d/mymotd.sh'
echo > /etc/motd
sudo apt install -y qemu-guest-agent

# Instalar Apache2
sudo apt install -y apache2

# Instalar PHP 8.2 e módulos necessários
sudo apt install -y php8.2 php8.2-mysql libapache2-mod-php8.2

# Instalar MariaDB sem interação
sudo DEBIAN_FRONTEND=noninteractive apt install -y mariadb-server

# Configure o MariaDB
sleep 20
sudo mariadb -uroot -e "alter user root@localhost identified by '$passDB';"
sudo mariadb -uroot -p$passDB -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mariadb -uroot -p$passDB -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$passDB';"
sudo mariadb -uroot -p$passDB -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
sudo mariadb -uroot -p$passDB -e "SET GLOBAL log_bin_trust_function_creators = 1;"
sudo mariadb -uroot -p$passDB -e "FLUSH PRIVILEGES;"

# Adicione o repositório do Zabbix 7.0
wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian12_all.deb && dpkg -i zabbix-release_latest+debian12_all.deb
sudo apt update

# Instalar o Zabbix
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent zabbix-sql-scripts

# Configure o Zabbix
sleep 10
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mariadb --default-character-set=utf8mb4 -uzabbix -p$passDB zabbix
sudo mariadb -uroot -p$passDB -e "SET GLOBAL log_bin_trust_function_creators = 0;"
sudo sed -i "s/^# DBPassword=.*/DBPassword=$passDB/" /etc/zabbix/zabbix_server.conf

sudo bash -c "cat <<'EOF' > /etc/zabbix/web/zabbix.conf.php
<?php
global \$DB;

\$DB['TYPE']     = 'MYSQL';
\$DB['SERVER']   = 'localhost';
\$DB['PORT']     = '0';
\$DB['DATABASE'] = 'zabbix';
\$DB['USER']     = 'zabbix';
\$DB['PASSWORD'] = '$passDB';

\$DB['SCHEMA'] = '';

\$ZBX_SERVER      = 'localhost';
\$ZBX_SERVER_PORT = '10051';
\$ZBX_SERVER_NAME = '$host';

\$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOF"

# Configure locale
sudo sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
sudo update-locale LANG=en_US.UTF-8
clear

# Aumentar o limite do php para importar os pacotes de Icones
sudo sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 30M/' /etc/php/8.2/apache2/php.ini
sudo sed -i 's/upload_max_filesize 2M/upload_max_filesize 30M/' /etc/zabbix/apache.conf

# Inicie os serviços do Zabbix e Apache2
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

# Verificar serviços
clear
echo -e "\n" && sudo systemctl status zabbix-server --no-pager | ccze -A | sed -n '/Active/p;/Loaded/p;/Duration/p'
echo -e "\n" && sudo systemctl status zabbix-agent --no-pager | ccze -A | sed -n '/Active/p;/Loaded/p;/Duration/p'
echo -e "\n" && sudo systemctl status apache2 --no-pager | ccze -A | sed -n '/Active/p;/Loaded/p;/Duration/p'
echo -e "\n" && sudo systemctl status mariadb --no-pager | ccze -A | sed -n '/Active/p;/Loaded/p;/Duration/p'
echo -e "\n"
echo -e "\n${GREEN}${BOLD} Zabbix Server instalado e configurado com sucesso! ${RESET}"
echo -e "\n"
echo -e "\n${BLUE}${BOLD} Agora acesse via browser ${WHITE}${BOLD}http://$IP/zabbix/ ${RESET}"
echo -e "\n${BLUE}${BOLD} Usuário: ${WHITE}${BOLD}Admin ${RESET}"
echo -e "\n${BLUE}${BOLD} Senha: ${WHITE}${BOLD}zabbix ${RESET}"
echo -e "\n${BLUE}${BOLD} Acesse: ${WHITE}${BOLD}Monitoring >> Maps >> Import ${RESET}"
echo -e "\n${BLUE}${BOLD} Importe essas URLs:  ${RESET}"
echo -e "\n${WHITE}${BOLD}      https://raw.githubusercontent.com/joaodanielcs/zabbix7.0/refs/heads/main/icones.xml ${RESET}"
echo -e "\n${WHITE}${BOLD}      https://raw.githubusercontent.com/joaodanielcs/zabbix7.0/refs/heads/main/icones2.xml ${RESET}"
echo -e "\n${WHITE}${BOLD}      https://raw.githubusercontent.com/joaodanielcs/zabbix7.0/refs/heads/main/icones3.xml ${RESET}"
echo -e "\n"
date
unset passDB IP host GREEN BLUE WHITE BOLD RESET 
history -c && cat /dev/null > ~/.bash_history

