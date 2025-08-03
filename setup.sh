#!/bin/bash

# Global Variables
REPO="https://raw.githubusercontent.com/xenvoid404/autoscript-tunn/master/"
NEON_PURPLE='\033[1;38;5;129m'
NEON_PINK='\033[1;38;5;201m'
NEON_RED='\033[1;38;5;196m'
NEON_GREEN='\033[1;38;5;46m'
NEON_ORANGE='\033[1;38;5;208m'
NEON_BLUE='\033[1;38;5;45m'
NC='\033[0m'
IP=$(curl -s --max-time 3 ipinfo.io/ip || echo "127.0.0.1")
DATE=$(date +'%Y-%m-%d')
start=$(date +%s)

# Telegram Config (Remove or replace with your own)
CHAT_ID="1198920849"
BOT_TOKEN="7965763247:AAFOM6r5SG1cH_eGYzH_mr35mmQ84FJQIL4"
URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

# Function to display error and exit
error_exit() {
    echo -e "${NEON_RED}Error: $1${NC}" >&2
    exit 1
}

# Function to check if command succeeded
check_success() {
    if [ $? -ne 0 ]; then
        error_exit "$1 failed"
    fi
}

# Function to print status messages
print_status() {
    echo -e "${NEON_BLUE}[*]${NC} $1"
}

# Function to print success messages
print_success() {
    echo -e "${NEON_GREEN}[+]${NC} $1"
}

# Function to print warning messages
print_warning() {
    echo -e "${NEON_ORANGE}[!]${NC} $1"
}

# Function to convert seconds to human readable time
secs_to_human() {
    echo "Installation time: $((${1} / 3600))h $(((${1} / 60) % 60))m $((${1} % 60))s"
}

# Initial system checks
initial_checks() {
    clear
    print_status "Running initial system checks..."
    
    # Check root
    if [ "$(id -u)" -ne 0 ]; then
        error_exit "This script must be run as root"
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        error_exit "Unsupported architecture: $ARCH (Only x86_64 is supported)"
    fi
    
    # Check OS
    source /etc/os-release
    case "$ID" in
        debian|ubuntu)
            print_success "OS supported: $PRETTY_NAME"
            ;;
        *)
            error_exit "Unsupported OS: $PRETTY_NAME"
            ;;
    esac
    
    # Check virtualization
    if [ "$(systemd-detect-virt)" == "openvz" ]; then
        error_exit "OpenVZ virtualization is not supported"
    fi
    
    # Check internet connection
    if ! curl -s --max-time 3 ipinfo.io > /dev/null; then
        error_exit "No internet connection detected"
    fi
}

# Install basic dependencies
install_basics() {
    print_status "Installing basic dependencies..."
    
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q -y
    check_success "System update"
    
    apt-get upgrade -q -y
    apt-get install -q -y --no-install-recommends \
        curl wget git zip unzip tar gzip p7zip-full \
        cron bash-completion net-tools socat netcat \
        dnsutils gnupg2 ca-certificates lsb-release \
        iptables-persistent netfilter-persistent \
        lolcat wondershaper figlet jq
    check_success "Basic dependencies installation"
}

# Setup system environment
setup_environment() {
    print_status "Setting up system environment..."
    
    # Set timezone
    timedatectl set-timezone Asia/Jakarta
    
    # Disable IPv6
    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
    
    # Create necessary directories
    mkdir -p /etc/xray /var/log/xray /var/lib/yuipedia /usr/local/yuipedia
    chown -R www-data:www-data /var/log/xray
    chmod -R +x /var/log/xray
    
    # Create empty log files
    touch /var/log/xray/access.log /var/log/xray/error.log
    
    # Get system info
    curl -s ipinfo.io/city > /etc/xray/city
    curl -s ipinfo.io/org | cut -d " " -f 2-10 > /etc/xray/isp
}

# Install Xray
install_xray() {
    print_status "Installing Xray core..."
    
    # Install latest Xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data
    
    # Base directory for all configurations
    mkdir -p /etc/default/layer/{spectrum,quantix,cipheron}
    
    # Download base spectrum config templates
    wget -q -O /etc/default/layer/spectrum/vmess.json "${REPO}etc/default/layer/spectrum/vmess.json"
    wget -q -O /etc/default/layer/spectrum/vmess.json.bak "${REPO}etc/default/layer/spectrum/vmess.json"
    wget -q -O /etc/default/layer/spectrum/spectrum.json "${REPO}etc/default/layer/spectrum/spectrum.json"
    wget -q -O /etc/default/layer/spectrum/spectrum.json.bak "${REPO}etc/default/layer/spectrum/spectrum.json"
    wget -q -O /etc/default/layer/spectrum/outbounds.json "${REPO}etc/default/layer/spectrum/outbounds.json"
    wget -q -O /etc/default/layer/spectrum/outbounds.json.bak "${REPO}etc/default/layer/spectrum/outbounds.json"
    wget -q -O /etc/default/layer/spectrum/rules.json "${REPO}etc/default/layer/spectrum/rules.json"
    wget -q -O /etc/default/layer/spectrum/rules.json.bak "${REPO}etc/default/layer/spectrum/rules.json"
   
    # Download base quantix config templates
    wget -q -O /etc/default/layer/quantix/vless.json "${REPO}etc/default/layer/quantix/vless.json"
    wget -q -O /etc/default/layer/quantix/vless.json.bak "${REPO}etc/default/layer/quantix/vless.json"
    wget -q -O /etc/default/layer/quantix/quantix.json "${REPO}etc/default/layer/quantix/quantix.json"
    wget -q -O /etc/default/layer/quantix/quantix.json.bak "${REPO}etc/default/layer/quantix/quantix.json"
    wget -q -O /etc/default/layer/quantix/outbounds.json "${REPO}etc/default/layer/quantix/outbounds.json"
    wget -q -O /etc/default/layer/quantix/outbounds.json.bak "${REPO}etc/default/layer/quantix/outbounds.json"
    wget -q -O /etc/default/layer/quantix/rules.json "${REPO}etc/default/layer/quantix/rules.json"
    wget -q -O /etc/default/layer/quantix/rules.json.bak "${REPO}etc/default/layer/quantix/rules.json"

    # Download base cipheron config templates
    wget -q -O /etc/default/layer/cipheron/trojan.json "${REPO}etc/default/layer/cipheron/trojan.json"
    wget -q -O /etc/default/layer/cipheron/trojan.json.bak "${REPO}etc/default/layer/cipheron/trojan.json"
    wget -q -O /etc/default/layer/cipheron/cipheron.json "${REPO}etc/default/layer/cipheron/cipheron.json"
    wget -q -O /etc/default/layer/cipheron/cipheron.json.bak "${REPO}etc/default/layer/cipheron/cipheron.json"
    wget -q -O /etc/default/layer/cipheron/outbounds.json "${REPO}etc/default/layer/cipheron/outbounds.json"
    wget -q -O /etc/default/layer/cipheron/outbounds.json.bak "${REPO}etc/default/layer/cipheron/outbounds.json"
    wget -q -O /etc/default/layer/cipheron/rules.json "${REPO}etc/default/layer/cipheron/rules.json"
    wget -q -O /etc/default/layer/cipheron/rules.json.bak "${REPO}etc/default/layer/cipheron/rules.json"

    # Customize each config
    sed -i "s/%%DOMAIN%%/$(cat /etc/xray/domain)/g" /etc/xray/*/config.json
    sed -i "s/%%UUID%%/$(cat /proc/sys/kernel/random/uuid)/g" /etc/xray/*/config.json

    # Reload and enable services
    systemctl daemon-reload
    systemctl enable --now {spectrum,quantix,cipheron}
    
    print_success "Xray installed successfully"
}

# Install and configure Nginx
install_nginx() {
    print_status "Installing and configuring Nginx..."
    
    apt-get install -q -y nginx
    check_success "Nginx installation"
    
    # Get config files
    wget -q -O /etc/nginx/conf.d/xray.conf "${REPO}limit/xray.conf"
    wget -q -O /etc/nginx/nginx.conf "${REPO}limit/nginx.conf"
    
    systemctl enable nginx
    systemctl restart nginx
    print_success "Nginx configured successfully"
}
# Install and configure HAProxy
install_haproxy() {
    print_status "Installing and configuring HAProxy..."
    
    if [ "$ID" == "ubuntu" ]; then
        add-apt-repository ppa:vbernat/haproxy-2.0 -y
        apt-get install -q -y haproxy=2.0.*
    elif [ "$ID" == "debian" ]; then
        curl https://haproxy.debian.net/bernat.debian.org.gpg | gpg --dearmor > /usr/share/keyrings/haproxy.debian.net.gpg
        echo "deb [signed-by=/usr/share/keyrings/haproxy.debian.net.gpg] http://haproxy.debian.net buster-backports-1.8 main" > /etc/apt/sources.list.d/haproxy.list
        apt-get update
        apt-get install -q -y haproxy=1.8.*
    fi
    check_success "HAProxy installation"
    
    wget -q -O /etc/haproxy/haproxy.cfg "${REPO}limit/haproxy.cfg"
    
    systemctl enable haproxy
    systemctl restart haproxy
    print_success "HAProxy configured successfully"
}

# Setup domain and SSL
setup_domain_ssl() {
    print_status "Setting up domain and SSL..."
    
    # Get domain
    echo ""
    echo -e "${NEON_BLUE}Please select a domain option:${NC}"
    echo "1) Use your own domain"
    echo "2) Use random domain (for Digital Ocean only)"
    read -p "Select option (1-2, default=1): " domain_option
    
    if [ "$domain_option" == "2" ]; then
        wget -q "${REPO}limit/cf.sh" -O cf.sh && chmod +x cf.sh && ./cf.sh
        rm -f cf.sh
    else
        read -p "Enter your domain: " domain
        echo "$domain" > /etc/xray/domain
    fi
    
    domain=$(cat /etc/xray/domain)
    
    # Install SSL
    print_status "Installing SSL certificate for $domain..."
    
    apt-get install -q -y socat
    mkdir -p /root/.acme.sh
    curl https://get.acme.sh | sh -s email=admin@$domain
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    ~/.acme.sh/acme.sh --issue -d $domain --standalone --keylength ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
    chmod 600 /etc/xray/xray.key
    
    # Combine cert and key for HAProxy
    cat /etc/xray/xray.crt /etc/xray/xray.key > /etc/haproxy/hap.pem
    
    print_success "SSL certificate installed successfully"
}

# Install SSH and related services
install_ssh_services() {
    print_status "Installing SSH and related services..."
    
    # Configure SSH
    wget -q -O /etc/ssh/sshd_config "${REPO}etc/ssh/sshd_config"
    wget -q -O /etc/pam.d/common-password "${REPO}etc/pam.d/common-password"
    chmod 600 /etc/ssh/sshd_config
    
    # Install Dropbear
    apt-get install -q -y dropbear
    wget -q -O /etc/default/dropbear "${REPO}etc/default/dropbear"
    
    # Install Fail2Ban
    apt-get install -q -y fail2ban
    
    # Install BadVPN UDPGw
    wget -q -O /usr/bin/badvpn-udpgw "${REPO}limit/badvpn-udpgw"
    chmod +x /usr/bin/badvpn-udpgw
    
    # Restart services
    systemctl restart ssh
    systemctl restart dropbear
    systemctl restart fail2ban
    
    print_success "SSH services installed successfully"
}

# Install VPN services
install_vpn_services() {
    print_status "Installing VPN services..."
    
    # Install OpenVPN
    wget -q "${REPO}limit/openvpn" -O openvpn.sh && chmod +x openvpn.sh && ./openvpn.sh
    rm -f openvpn.sh
    
    # Install WebSocket (ePro)
    wget -q -O /usr/sbin/ws-epro "${REPO}usr/sbin/ws-epro"
    wget -q -O /usr/sbin/tunws.conf "${REPO}usr/sbin/tunws.conf"
    wget -q -O /etc/systemd/system/tunws.service "${REPO}etc/systemd/system/tunws.service"
    chmod +x /usr/bin/ws
    chmod 644 /usr/bin/tun.conf
    systemctl enable ws
    
    print_success "VPN services installed successfully"
}

# Install monitoring tools
install_monitoring() {
    print_status "Installing monitoring tools..."
    
    # Install vnstat
    apt-get install -q -y vnstat
    /etc/init.d/vnstat restart
    
    # Install gotop
    latest_gotop=$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)
    wget -q "https://github.com/xxxserxxx/gotop/releases/download/v$latest_gotop/gotop_v${latest_gotop}_linux_amd64.deb" -O /tmp/gotop.deb
    dpkg -i /tmp/gotop.deb
    rm -f /tmp/gotop.deb
    
    print_success "Monitoring tools installed successfully"
}

# Setup quota and limits
setup_limits() {
    print_status "Setting up bandwidth limits..."
    
    wget -q "${REPO}limit/limit.sh" -O limit.sh && chmod +x limit.sh && ./limit.sh
    rm -f limit.sh
    
    wget -q -O /usr/bin/limit-ip "${REPO}limit/limit-ip"
    chmod +x /usr/bin/limit-ip
    
    # Create limit services
    for service in vmip vlip trip; do
        cat > /etc/systemd/system/$service.service <<EOF
[Unit]
Description=Limit $service
After=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip $service
Restart=always

[Install]
WantedBy=multi-user.target
EOF
        systemctl enable $service
        systemctl start $service
    done
    
    # Install UDP Mini
    wget -q -O /usr/local/kyt/udp-mini "${REPO}limit/udp-mini"
    chmod +x /usr/local/kyt/udp-mini
    
    for i in 1 2 3; do
        wget -q -O /etc/systemd/system/udp-mini-$i.service "${REPO}limit/udp-mini-$i.service"
        systemctl enable udp-mini-$i
        systemctl start udp-mini-$i
    done
    
    print_success "Bandwidth limits configured successfully"
}

# Install SlowDNS
install_slowdns() {
    print_status "Installing SlowDNS..."
    
    wget -q -O /tmp/nameserver "${REPO}limit/nameserver"
    chmod +x /tmp/nameserver
    bash /tmp/nameserver | tee /root/install.log
    
    print_success "SlowDNS installed successfully"
}

# Setup backup system
setup_backup() {
    print_status "Setting up backup system..."
    
    # Install rclone
    apt-get install -q -y rclone
    wget -q -O /root/.config/rclone/rclone.conf "${REPO}limit/rclone.conf"
    
    # Install Wondershaper
    git clone https://github.com/magnific0/wondershaper.git /tmp/wondershaper
    cd /tmp/wondershaper
    make install
    cd
    rm -rf /tmp/wondershaper
    
    # Install email notification
    apt-get install -q -y msmtp-mta ca-certificates bsd-mailx
    cat > /etc/msmtprc <<EOF
defaults
tls on
tls_starttls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account default
host smtp.gmail.com
port 587
auth on
user oceantestdigital@gmail.com
from oceantestdigital@gmail.com
password jokerman77
logfile ~/.msmtp.log
EOF
    chown -R www-data:www-data /etc/msmtprc
    
    print_success "Backup system configured successfully"
}

# Setup swap
setup_swap() {
    print_status "Setting up swap file..."
    
    # Create 1GB swap file
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    # Enable BBR
    wget -q "${REPO}limit/bbr.sh" -O bbr.sh && chmod +x bbr.sh && ./bbr.sh
    rm -f bbr.sh
    
    print_success "Swap file configured successfully"
}

# Install menu system
install_menu() {
    print_status "Installing menu system..."
    
    wget -q "${REPO}limit/menu.zip" -O menu.zip
    unzip -q menu.zip
    chmod +x menu/*
    mv menu/* /usr/local/sbin
    rm -rf menu menu.zip
    
    # Create profile
    cat > /root/.profile <<EOF
# ~/.profile: executed by Bourne-compatible login shells.
if [ "\$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
mesg n || true
menu
EOF
    
    # Setup cron jobs
    cat > /etc/cron.d/xp_all <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
2 0 * * * root /usr/local/sbin/xp
EOF

    cat > /etc/cron.d/logclean <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/20 * * * * root /usr/local/sbin/clearlog
EOF

    cat > /etc/cron.d/daily_reboot <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
0 5 * * * root /sbin/reboot
EOF

    echo "*/1 * * * * root echo -n > /var/log/nginx/access.log" > /etc/cron.d/log.nginx
    echo "*/1 * * * * root echo -n > /var/log/xray/access.log" >> /etc/cron.d/log.xray
    
    service cron restart
    
    print_success "Menu system installed successfully"
}

# Final cleanup and restart
final_setup() {
    print_status "Performing final setup..."
    
    # Enable services
    systemctl daemon-reload
    systemctl enable --now {nginx,xray,cron,haproxy,ws,fail2ban}
    
    # Clean up
    history -c
    echo "unset HISTFILE" >> /etc/profile
    
    # Calculate installation time
    end=$(date +%s)
    runtime=$((end-start))
    
    # Send notification
    TEXT="
<code>────────────────────</code>
<b>⚡AUTOSCRIPT PREMIUM⚡</b>
<code>────────────────────</code>
<code>Domain   :</code><code>$(cat /etc/xray/domain)</code>
<code>IPVPS    :</code><code>$IP</code>
<code>ISP      :</code><code>$(cat /etc/xray/isp)</code>
<code>DATE     :</code><code>$DATE</code>
<code>Time     :</code><code>$(date +%T)</code>
<code>────────────────────</code>
<b>SCRIPT INSTALLED</b>
<code>────────────────────</code>
<i>Automatic Notifications From Installation</i>
"'&reply_markup={"inline_keyboard":[[{"text":"ᴏʀᴅᴇʀ","url":"https://wa.me/"}]]}'
    
    curl -s --max-time 10 -d "chat_id=$CHAT_ID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
    
    # Display completion message
    clear
    echo ""
    echo -e "${NEON_GREEN}Script Successfully Installed!${NC}"
    echo ""
    secs_to_human "$runtime"
    echo ""
    
    # Prompt for reboot
    read -p "$(echo -e "Press ${NEON_BLUE}[Enter]${NC} to reboot") "
    reboot
}

# Main installation function
main_install() {
    initial_checks
    install_basics
    setup_environment
    setup_domain_ssl
    install_xray
    install_nginx
    install_haproxy
    install_ssh_services
    install_vpn_services
    install_monitoring
    setup_limits
    install_slowdns
    setup_backup
    setup_swap
    install_menu
    final_setup
}

# Start installation
main_install