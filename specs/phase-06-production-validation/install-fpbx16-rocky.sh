#!/bin/bash
# Install FreePBX 16 + Asterisk 18 on Rocky Linux 8.
# Mimics the SNG7/FreePBX-Distro environment (RHEL-family, systemd,
# firewalld, php-fpm) more closely than the Debian path. Suitable as
# a proxy for friend's likely production environment.
#
# Adapted from official FreePBX 16 on CentOS 7 guide + Rocky 8 adjustments.

set -e
exec > >(tee -a /var/log/freepbx16-rocky-install.log) 2>&1
echo "=== FreePBX 16 Rocky 8 install starting $(date) ==="

# Stop SELinux from interfering during install
setenforce 0 || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

# Add EPEL + PowerTools (Rocky calls it 'powertools' on 8, 'crb' on 9)
dnf install -y epel-release
dnf config-manager --set-enabled powertools || dnf config-manager --set-enabled crb || true

# Base packages
dnf install -y \
  wget curl git rsync vim nano \
  gcc gcc-c++ make autoconf automake libtool m4 pkgconfig \
  mariadb-server mariadb \
  httpd \
  cronie at \
  policycoreutils-python-utils

# Disable firewalld for sandbox (FreePBX has its own firewall module)
systemctl stop firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true

# Disable fail2ban if pulled in
systemctl stop fail2ban 2>/dev/null || true
systemctl disable fail2ban 2>/dev/null || true

# === Stage 2: PHP 7.4 ===
echo "=== Stage 2: PHP 7.4 (FreePBX 16 hard-requires it) ==="
# Remi repo for PHP 7.4 on Rocky 8 (similar to Sury on Debian)
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module reset -y php
dnf module enable -y php:remi-7.4
dnf install -y \
  php php-cli php-common php-curl php-mbstring \
  php-gd php-mysqlnd php-bcmath \
  php-zip php-xml php-imap php-snmp \
  php-fpm php-intl php-ldap php-sqlite3

# Tune PHP for FreePBX
PHPINI=/etc/php.ini
sed -i 's/^upload_max_filesize.*/upload_max_filesize = 120M/' $PHPINI
sed -i 's/^post_max_size.*/post_max_size = 120M/' $PHPINI
sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHPINI

# === Stage 3: Asterisk user + Apache as asterisk ===
echo "=== Stage 3: asterisk user ==="
groupadd -r asterisk 2>/dev/null || true
useradd -r -d /var/lib/asterisk -g asterisk -s /bin/bash asterisk 2>/dev/null || true
usermod -aG audio,dialout asterisk

sed -i 's/^User apache/User asterisk/' /etc/httpd/conf/httpd.conf
sed -i 's/^Group apache/Group asterisk/' /etc/httpd/conf/httpd.conf
# AllowOverride for .htaccess
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# === Stage 4: Node.js 18 (from NodeSource) ===
echo "=== Stage 4: Node.js 18 ==="
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# === Stage 5: Asterisk 18 from source ===
echo "=== Stage 5: Asterisk 18 build ==="
# Asterisk build deps
dnf install -y \
  libxml2-devel ncurses-devel libuuid-devel sqlite-devel openssl-devel \
  libedit-devel jansson-devel newt-devel \
  libsrtp-devel libtiff-devel \
  unixODBC-devel libpq-devel \
  gsm-devel speex-devel speexdsp-devel libvorbis-devel \
  libcurl-devel libical-devel iksemel-devel neon-devel \
  libxml2-devel binutils-devel net-snmp-devel \
  lua-devel libcap-devel openldap-devel \
  python3 python3-devel \
  bison flex

cd /usr/src
[ -f asterisk-18-current.tar.gz ] || wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
tar -zxf asterisk-18-current.tar.gz
ASTDIR=$(ls -d asterisk-18.* | head -1)
cd $ASTDIR
./configure --with-pjproject-bundled --with-jansson-bundled
make menuselect.makeopts
make -j$(nproc)
make install
make samples
make config
ldconfig

chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /usr/lib/asterisk
sed -i 's/;\?runuser = asterisk/runuser = asterisk/' /etc/asterisk/asterisk.conf
sed -i 's/;\?rungroup = asterisk/rungroup = asterisk/' /etc/asterisk/asterisk.conf

# === Stage 6: MariaDB ===
echo "=== Stage 6: MariaDB ==="
systemctl enable --now mariadb
mysql -uroot <<SQL || true
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
SQL

# === Stage 7: FreePBX 16 ===
echo "=== Stage 7: FreePBX 16 ==="
cd /usr/src
[ -f freepbx-16.0-latest.tgz ] || wget -q https://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz
tar -zxf freepbx-16.0-latest.tgz
cd freepbx

# Enable cronie + httpd
systemctl enable --now crond httpd

./start_asterisk start || true
./install -n --dbuser root --dbpass '' --webroot=/var/www/html --force

fwconsole ma installall
fwconsole chown
fwconsole reload
fwconsole restart

systemctl restart httpd

echo "=== FreePBX 16 Rocky install complete $(date) ==="
echo "Web UI: http://$(hostname -I | awk '{print $1}')/admin"
fwconsole --version
asterisk -rx 'core show version' || true
