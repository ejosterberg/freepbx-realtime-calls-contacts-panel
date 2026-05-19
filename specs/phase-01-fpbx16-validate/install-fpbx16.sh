#!/bin/bash
# Install FreePBX 16 + Asterisk 18 on Debian 12 (bookworm)
# Sandbox install — not production-hardened. Run as root.
# Based on: https://hotkey404.com/installing-freepbx-16-on-debian-12-with-asterisk-18-2/
# Adapted for unattended execution. See specs/phase-01-fpbx16-validate/plan.md

set -e
exec > >(tee -a /var/log/freepbx16-install.log) 2>&1
echo "=== FreePBX 16 install starting $(date) ==="

export DEBIAN_FRONTEND=noninteractive

# ============================================================================
# Stage 1: Base packages + Apache + MariaDB + node + sox
# ============================================================================
echo "=== Stage 1: base packages ==="
apt-get update -qq
apt-get -y upgrade
apt-get -y install \
  curl wget gnupg lsb-release ca-certificates \
  build-essential pkg-config autoconf libtool m4 \
  git rsync sudo nano vim less \
  mariadb-server mariadb-client \
  apache2 \
  nodejs npm \
  sox \
  cron at \
  postfix

# Asterisk build deps (manually — skip install_prereq for non-interactive)
apt-get -y install \
  libxml2-dev libncurses5-dev libsqlite3-dev libssl-dev \
  libedit-dev uuid-dev libjansson-dev libnewt-dev \
  libsrtp2-dev libspandsp-dev libtiff-dev \
  unixodbc-dev libpq-dev libfftw3-dev \
  libgsm1-dev libspeex-dev libspeexdsp-dev libvorbis-dev \
  libcurl4-openssl-dev libical-dev libiksemel-dev libneon27-dev \
  libxml2-utils binutils-dev libsnmp-dev libgmime-3.0-dev \
  liblua5.4-dev libcap-dev libldap2-dev \
  python3 python3-dev

# Disable fail2ban if it got pulled in
apt-get -y install fail2ban || true
systemctl stop fail2ban 2>/dev/null || true
systemctl disable fail2ban 2>/dev/null || true

# ============================================================================
# Stage 2: PHP 7.4 via Sury (FreePBX 16 hard-requires PHP 7.4)
# ============================================================================
echo "=== Stage 2: PHP 7.4 ==="
wget -qO /etc/apt/trusted.gpg.d/sury.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ bookworm main" > /etc/apt/sources.list.d/php.list
apt-get update -qq
apt-get -y install \
  php7.4 libapache2-mod-php7.4 \
  php7.4-cgi php7.4-common php7.4-curl php7.4-mbstring \
  php7.4-gd php7.4-mysql php7.4-gettext php7.4-bcmath \
  php7.4-zip php7.4-xml php7.4-imap php7.4-snmp \
  php7.4-fpm php7.4-intl php7.4-ldap php7.4-sqlite3 \
  php7.4-mongodb

# Switch Apache to PHP 7.4
a2dismod php8.2 2>/dev/null || true
a2dismod mpm_event 2>/dev/null || true
a2enmod php7.4 mpm_prefork rewrite
update-alternatives --set php /usr/bin/php7.4

# ============================================================================
# Stage 3: Asterisk user + group (do BEFORE Asterisk install)
# ============================================================================
echo "=== Stage 3: asterisk user ==="
groupadd -r asterisk 2>/dev/null || true
useradd -r -d /var/lib/asterisk -g asterisk -s /bin/bash asterisk 2>/dev/null || true
usermod -aG audio,dialout asterisk

# Apache as asterisk user
sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
sed -i 's/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=asterisk/' /etc/apache2/envvars
sed -i 's/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=asterisk/' /etc/apache2/envvars

# Set PHP upload limit (FreePBX module uploads need >= 100MB)
PHPINI=/etc/php/7.4/apache2/php.ini
sed -i 's/^upload_max_filesize.*/upload_max_filesize = 120M/' $PHPINI
sed -i 's/^post_max_size.*/post_max_size = 120M/' $PHPINI
sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHPINI

# ============================================================================
# Stage 4: Build Asterisk 18 from source
# ============================================================================
echo "=== Stage 4: Asterisk 18 from source ==="
cd /usr/src
if [ ! -f asterisk-18-current.tar.gz ]; then
  wget -q https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
fi
tar -zxf asterisk-18-current.tar.gz
ASTDIR=$(ls -d asterisk-18.* | head -1)
cd $ASTDIR

./configure --with-pjproject-bundled --with-jansson-bundled
make menuselect.makeopts
# Defaults are fine for sandbox; no MP3 codec needed
make -j$(nproc)
make install
make samples
make config
ldconfig

# Permissions
chown -R asterisk:asterisk /etc/asterisk /var/lib/asterisk /var/log/asterisk /var/spool/asterisk /usr/lib/asterisk

# asterisk.conf -> run as asterisk user
sed -i 's/;\?runuser = asterisk/runuser = asterisk/' /etc/asterisk/asterisk.conf
sed -i 's/;\?rungroup = asterisk/rungroup = asterisk/' /etc/asterisk/asterisk.conf

# ============================================================================
# Stage 5: MariaDB setup (passwordless root for sandbox)
# ============================================================================
echo "=== Stage 5: MariaDB ==="
systemctl enable --now mariadb
mysql -uroot <<SQL
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL

# ============================================================================
# Stage 6: FreePBX 16 framework install
# ============================================================================
echo "=== Stage 6: FreePBX 16 ==="
cd /usr/src
if [ ! -f freepbx-16.0-latest.tgz ]; then
  wget -q https://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz
fi
tar -zxf freepbx-16.0-latest.tgz
cd freepbx

./start_asterisk start

./install -n --dbuser root --dbpass '' --webroot=/var/www/html

# Install all core modules
fwconsole ma installall
fwconsole chown
fwconsole reload
fwconsole restart

# Apache
systemctl restart apache2

echo "=== FreePBX 16 install complete $(date) ==="
echo "Web UI: http://$(hostname -I | awk '{print $1}')/admin"
fwconsole --version
asterisk -rx 'core show version' || true
