#!/bin/bash

# Xray Auto Install Script - Advanced Version
# Compatible with Ubuntu/Debian/CentOS systems
# Author: Advanced Auto Install Script  
# Version: 2.0 - Maximized Edition
# Features: Multi-Protocol, SSL, Traffic Monitoring, User Management

# Global Variables
SCRIPT_VERSION="2.0"
CONFIG_DIR="/usr/local/etc/xray"
LOG_DIR="/var/log/xray"
USER_DB="/root/xray-users.db"
STATS_DIR="/var/xray-stats"
SSL_DIR="/etc/xray-ssl"
BACKUP_DIR="/root/xray-backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
        PM="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        OS="debian"
        PM="apt-get"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        OS="ubuntu"
        PM="apt-get"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        OS="centos"
        PM="yum"
    elif cat /proc/version | grep -Eqi "debian"; then
        OS="debian"
        PM="apt-get"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        OS="ubuntu"
        PM="apt-get"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        OS="centos"
        PM="yum"
    else
        print_error "Unsupported operating system!"
        exit 1
    fi
    print_status "Detected OS: $OS"
}

# Update sistem dan install paket yang diperlukan
update_system() {
    print_status "Memperbarui paket sistem..."
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update -y
        apt-get install -y curl wget unzip python3 python3-pip jq htop iotop net-tools
    elif [[ "$OS" == "centos" ]]; then
        yum update -y
        yum install -y curl wget unzip python3 python3-pip jq htop iotop net-tools
    fi
    
    # Buat direktori yang diperlukan
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$STATS_DIR" "$SSL_DIR" "$BACKUP_DIR"
    
    # Setup BBR untuk optimasi jaringan
    setup_bbr_optimization
}

# Setup BBR (Bottleneck Bandwidth and Round-trip propagation time)
setup_bbr_optimization() {
    print_status "Mengoptimalkan jaringan dengan BBR..."
    
    # Periksa versi kernel
    kernel_version=$(uname -r | cut -d. -f1-2)
    kernel_major=$(echo $kernel_version | cut -d. -f1)
    kernel_minor=$(echo $kernel_version | cut -d. -f2)
    
    if [[ $kernel_major -gt 4 ]] || [[ $kernel_major -eq 4 && $kernel_minor -ge 9 ]]; then
        print_status "Kernel mendukung BBR (versi $kernel_version)"
        
        # Backup konfigurasi sysctl asli
        cp /etc/sysctl.conf /etc/sysctl.conf.backup 2>/dev/null || true
        
        # Terapkan optimasi BBR dan jaringan
        cat >> /etc/sysctl.conf << 'EOF'

# Optimasi Jaringan BBR untuk Xray
# BBR Congestion Control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Optimasi TCP
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_mtu_probing = 1

# Buffer jaringan
net.core.rmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_default = 262144
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 65536 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Optimasi koneksi
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 5000
net.core.somaxconn = 65535
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1

# Keamanan jaringan
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# Optimasi memori
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
        
        # Terapkan konfigurasi
        sysctl -p >/dev/null 2>&1
        
        # Verifikasi BBR aktif
        if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
            print_status "✅ BBR berhasil diaktifkan!"
        else
            print_warning "⚠️ BBR mungkin tidak sepenuhnya aktif"
        fi
        
        # Tampilkan status optimasi
        echo ""
        print_status "Status Optimasi Jaringan:"
        echo "- Congestion Control: $(sysctl -n net.ipv4.tcp_congestion_control)"
        echo "- Queue Discipline: $(sysctl -n net.core.default_qdisc)"
        echo "- TCP Fast Open: $(sysctl -n net.ipv4.tcp_fastopen)"
        
    else
        print_warning "Kernel terlalu lama untuk BBR (versi $kernel_version)"
        print_status "Menerapkan optimasi TCP dasar..."
        
        # Optimasi dasar untuk kernel lama
        cat >> /etc/sysctl.conf << 'EOF'

# Optimasi TCP Dasar untuk Xray
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_keepalive_time = 600
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF
        sysctl -p >/dev/null 2>&1
    fi
    
    print_status "Optimasi jaringan selesai!"
}

# Fungsi untuk memverifikasi akses port 80/443
verify_port_access() {
    local domain="$1"
    
    print_status "Memverifikasi akses port 80/443 untuk domain $domain..."
    
    # Test port 80
    if timeout 10 bash -c "echo >/dev/tcp/$domain/80" 2>/dev/null; then
        print_status "✓ Port 80 dapat diakses"
    else
        print_warning "⚠ Port 80 tidak dapat diakses dari luar"
        echo "Ini bisa disebabkan oleh:"
        echo "  - Firewall lokal memblokir port 80"
        echo "  - Cloud provider security group tidak mengizinkan port 80"
        echo "  - ISP memblokir port 80"
    fi
    
    # Test port 443  
    if timeout 10 bash -c "echo >/dev/tcp/$domain/443" 2>/dev/null; then
        print_status "✓ Port 443 dapat diakses"
    else
        print_warning "⚠ Port 443 tidak dapat diakses dari luar (ini normal sebelum SSL setup)"
    fi
    
    # Test DNS resolution
    if nslookup "$domain" > /dev/null 2>&1; then
        local resolved_ip=$(nslookup "$domain" | grep -A1 "Name:" | tail -1 | awk '{print $2}' 2>/dev/null)
        local server_ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
        
        if [[ "$resolved_ip" == "$server_ip" ]]; then
            print_status "✓ DNS resolution benar ($resolved_ip)"
        else
            print_warning "⚠ DNS belum mengarah ke server ini"
            echo "  Domain mengarah ke: $resolved_ip"
            echo "  Server IP: $server_ip"
        fi
    else
        print_error "✗ Domain tidak dapat di-resolve"
        return 1
    fi
}

# Install Xray dengan fitur SSL dan reverse proxy
install_xray() {
    print_status "Menginstall Xray dengan SSL dan reverse proxy..."
    
    # Buat direktori xray
    mkdir -p "$CONFIG_DIR" "$LOG_DIR"
    
    # Download dan install Xray
    wget -O xray-install.sh https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh
    chmod +x xray-install.sh
    ./xray-install.sh
    
    # Bersihkan file temporary
    rm -f xray-install.sh
    
    # Inisialisasi database user
    init_user_database
    
    # Setup monitoring traffic
    setup_traffic_monitoring
    
    # Setup sistem DNS management
    setup_dns_management
    
    # Setup SSL dan reverse proxy
    setup_ssl_and_reverse_proxy
    
    print_status "Instalasi Xray dengan SSL dan reverse proxy selesai!"
}

# Initialize user database
init_user_database() {
    if [[ ! -f "$USER_DB" ]]; then
        mkdir -p "$STATS_DIR"
        touch "$USER_DB"
        # Format: username:uuid:email:created_date:expiry_date:status:total_traffic:used_traffic
        echo "# Xray User Database - Format: username:uuid:email:created_date:expiry_date:status:total_traffic:used_traffic" > "$USER_DB"
    fi
}

# Setup traffic monitoring
setup_traffic_monitoring() {
    print_status "Setting up traffic monitoring..."
    
    # Create traffic monitoring script
    cat > /usr/local/bin/xray-traffic-monitor << 'EOF'
#!/bin/bash
STATS_DIR="/var/xray-stats"
USER_DB="/root/xray-users.db"

# Update traffic stats (simplified)
if [[ -f "$USER_DB" ]]; then
    while IFS=':' read -r username uuid email created expiry status total_limit used_traffic; do
        if [[ "$username" =~ ^#.* ]] || [[ -z "$username" ]]; then
            continue
        fi
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        echo "$timestamp,$username,$uuid,0" >> "$STATS_DIR/traffic-$(date +%Y-%m).log"
    done < "$USER_DB"
fi
EOF

    chmod +x /usr/local/bin/xray-traffic-monitor
    
    # Create crontab entry for traffic monitoring
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/xray-traffic-monitor >/dev/null 2>&1") | crontab -
    
# Setup DNS Management System
setup_dns_management() {
    print_status "Menyiapkan sistem manajemen DNS..."
    
    # Backup konfigurasi DNS asli
    cp /etc/resolv.conf /etc/resolv.conf.backup 2>/dev/null || true
    
    # Buat script manajemen DNS
    cat > /usr/local/bin/xray-dns-manager << 'EOF'
#!/bin/bash

# Xray DNS Manager
# Mengelola konfigurasi DNS untuk optimasi kecepatan

DNS_CONFIG_FILE="/etc/xray-dns.conf"
RESOLV_BACKUP="/etc/resolv.conf.backup"

# Daftar DNS server terbaik
declare -A DNS_SERVERS=(
    ["cloudflare"]="1.1.1.1,1.0.0.1"
    ["google"]="8.8.8.8,8.8.4.4"
    ["quad9"]="9.9.9.9,149.112.112.112"
    ["opendns"]="208.67.222.222,208.67.220.220"
    ["adguard"]="94.140.14.14,94.140.15.15"
    ["clean"]="76.76.19.19,76.223.100.101"
    ["comodo"]="8.26.56.26,8.20.247.20"
    ["level3"]="4.2.2.1,4.2.2.2"
)

# Fungsi untuk tes kecepatan DNS
test_dns_speed() {
    local dns_ip="$1"
    local test_domain="google.com"
    
    # Tes resolusi DNS dengan timeout
    local start_time=$(date +%s%N)
    if timeout 3 nslookup "$test_domain" "$dns_ip" >/dev/null 2>&1; then
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))
        echo "$duration"
    else
        echo "9999"
    fi
}

# Fungsi untuk set DNS
set_dns() {
    local dns_name="$1"
    local dns_ips="$2"
    
    if [[ -n "$dns_ips" ]]; then
        # Backup resolv.conf saat ini
        cp /etc/resolv.conf /etc/resolv.conf.temp 2>/dev/null || true
        
        # Tulis konfigurasi DNS baru
        cat > /etc/resolv.conf << DNSEOF
# DNS Configuration managed by Xray DNS Manager
# Provider: $dns_name
# Generated: $(date)

DNSEOF
        
        # Tambahkan server DNS
        IFS=',' read -ra DNS_ARRAY <<< "$dns_ips"
        for dns in "${DNS_ARRAY[@]}"; do
            echo "nameserver $dns" >> /etc/resolv.conf
        done
        
        # Simpan konfigurasi
        echo "$dns_name:$dns_ips" > "$DNS_CONFIG_FILE"
        
        echo "DNS berhasil diubah ke $dns_name ($dns_ips)"
    else
        echo "Error: DNS tidak valid"
        return 1
    fi
}

# Fungsi untuk tes semua DNS dan pilih yang tercepat
auto_select_fastest_dns() {
    echo "Menguji kecepatan semua DNS server..."
    echo "======================================"
    
    local fastest_dns=""
    local fastest_time=9999
    local fastest_name=""
    
    for dns_name in "${!DNS_SERVERS[@]}"; do
        local dns_ips="${DNS_SERVERS[$dns_name]}"
        local primary_dns=$(echo "$dns_ips" | cut -d',' -f1)
        
        printf "%-12s %-15s " "$dns_name" "$primary_dns"
        
        local response_time=$(test_dns_speed "$primary_dns")
        
        if [[ $response_time -lt $fastest_time ]]; then
            fastest_time=$response_time
            fastest_dns="$dns_ips"
            fastest_name="$dns_name"
        fi
        
        if [[ $response_time -eq 9999 ]]; then
            echo "TIMEOUT"
        else
            echo "${response_time}ms"
        fi
    done
    
    echo "======================================"
    echo "DNS tercepat: $fastest_name (${fastest_time}ms)"
    
    if [[ $fastest_time -lt 9999 ]]; then
        set_dns "$fastest_name" "$fastest_dns"
        return 0
    else
        echo "Semua DNS gagal diuji, menggunakan Cloudflare sebagai default"
        set_dns "cloudflare" "1.1.1.1,1.0.0.1"
        return 1
    fi
}

# Fungsi untuk menampilkan status DNS saat ini
show_dns_status() {
    echo "Status DNS Saat Ini:"
    echo "===================="
    
    if [[ -f "$DNS_CONFIG_FILE" ]]; then
        local current_config=$(cat "$DNS_CONFIG_FILE")
        local dns_name=$(echo "$current_config" | cut -d':' -f1)
        local dns_ips=$(echo "$current_config" | cut -d':' -f2)
        echo "Provider: $dns_name"
        echo "DNS Servers: $dns_ips"
    else
        echo "Menggunakan DNS sistem default"
    fi
    
    echo ""
    echo "Konfigurasi /etc/resolv.conf:"
    echo "============================="
    cat /etc/resolv.conf | grep nameserver
}

# Fungsi untuk restore DNS asli
restore_dns() {
    if [[ -f "$RESOLV_BACKUP" ]]; then
        cp "$RESOLV_BACKUP" /etc/resolv.conf
        rm -f "$DNS_CONFIG_FILE"
        echo "DNS dikembalikan ke konfigurasi asli"
    else
        echo "Backup DNS tidak ditemukan"
        return 1
    fi
}

# Menu utama
case "$1" in
    "set")
        if [[ -n "$2" && -n "${DNS_SERVERS[$2]}" ]]; then
            set_dns "$2" "${DNS_SERVERS[$2]}"
        else
            echo "DNS provider tidak valid. Pilihan: ${!DNS_SERVERS[*]}"
            exit 1
        fi
        ;;
    "auto")
        auto_select_fastest_dns
        ;;
    "status")
        show_dns_status
        ;;
    "restore")
        restore_dns
        ;;
    "test")
        if [[ -n "$2" ]]; then
            echo "Menguji DNS $2..."
            response_time=$(test_dns_speed "$2")
            if [[ $response_time -eq 9999 ]]; then
                echo "DNS $2: TIMEOUT"
            else
                echo "DNS $2: ${response_time}ms"
            fi
        else
            echo "Gunakan: xray-dns-manager test <ip_dns>"
        fi
        ;;
    *)
        echo "Xray DNS Manager"
        echo "================"
        echo "Penggunaan: xray-dns-manager [opsi]"
        echo ""
        echo "Opsi:"
        echo "  set <provider>    - Set DNS provider (${!DNS_SERVERS[*]})"
        echo "  auto             - Otomatis pilih DNS tercepat"
        echo "  status           - Tampilkan status DNS saat ini"
        echo "  restore          - Kembalikan ke DNS asli"
        echo "  test <ip>        - Tes kecepatan DNS tertentu"
        echo ""
        echo "Contoh:"
        echo "  xray-dns-manager set cloudflare"
        echo "  xray-dns-manager auto"
        echo "  xray-dns-manager test 1.1.1.1"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/xray-dns-manager
    
    # Auto-select DNS tercepat saat instalasi
    print_status "Memilih DNS tercepat secara otomatis..."
    /usr/local/bin/xray-dns-manager auto
    
# Setup SSL Certificate berdasarkan pilihan instalasi
setup_ssl_and_reverse_proxy() {
    print_status "Menyiapkan SSL Certificate dan Reverse Proxy..."
    
    # Install Nginx dan Certbot
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get install -y nginx certbot python3-certbot-nginx
    elif [[ "$OS" == "centos" ]]; then
        yum install -y nginx certbot python3-certbot-nginx
        systemctl enable nginx
    fi
    
    mkdir -p "$SSL_DIR"
    
    # Proses berdasarkan pilihan yang sudah dibuat saat instalasi
    case $SSL_TYPE in
        "letsencrypt")
            print_status "Menggunakan konfigurasi Let's Encrypt: $DOMAIN"
            setup_letsencrypt_ssl_with_config
            ;;
        "selfsigned")
            print_status "Menggunakan self-signed certificate untuk: $DOMAIN"
            setup_selfsigned_ssl
            ;;
        "none")
            print_status "Skip SSL, menggunakan HTTP saja"
            setup_nginx_http_only
            USE_SSL=false
            return 0
            ;;
        *)
            print_warning "Konfigurasi SSL tidak valid, menggunakan self-signed sebagai fallback"
            setup_selfsigned_ssl
            ;;
    esac
}

# Setup Let's Encrypt dengan konfigurasi yang sudah ada
setup_letsencrypt_ssl_with_config() {
    print_status "Meminta sertifikat SSL dari Let's Encrypt untuk $DOMAIN..."
    
    # PENTING: Buka port 80/443 terlebih dahulu untuk Let's Encrypt validation
    print_status "Membuka port 80/443 untuk validasi SSL..."
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp
        ufw allow 443/tcp
        print_status "UFW: Port 80/443 telah dibuka"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
        print_status "Firewalld: Port 80/443 telah dibuka"
    else
        print_warning "Firewall tidak terdeteksi. Pastikan port 80/443 terbuka di cloud provider!"
    fi
    
    # Hentikan nginx sementara untuk certbot standalone
    systemctl stop nginx 2>/dev/null || true
    
    # Generate Let's Encrypt certificate dengan konfigurasi yang sudah ada
    if certbot certonly --standalone --non-interactive --agree-tos --email "$SSL_EMAIL" -d "$DOMAIN"; then
        # Copy certificate ke direktori Xray
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/fullchain.pem"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/privkey.pem"
        
        # Set permissions
        chmod 644 "$SSL_DIR/fullchain.pem"
        chmod 600 "$SSL_DIR/privkey.pem"
        
        # Setup auto-renewal
        setup_ssl_renewal "$DOMAIN"
        
        print_status "✅ Sertifikat SSL Let's Encrypt berhasil dipasang!"
        
        # Setup Nginx reverse proxy
        setup_nginx_reverse_proxy "$DOMAIN"
        
        USE_SSL=true
        
    else
        print_error "Gagal mendapatkan sertifikat Let's Encrypt"
        print_status "Kemungkinan penyebab:"
        echo "  - Domain belum mengarah ke server ini"
        echo "  - Port 80 tidak dapat diakses dari internet"
        echo "  - Firewall memblokir koneksi"
        echo ""
        print_status "Menggunakan self-signed certificate sebagai fallback"
        
        # Fallback ke self-signed
        SSL_TYPE="selfsigned"
        setup_selfsigned_ssl
    fi
}

# Setup Nginx untuk HTTP only (tanpa SSL)
setup_nginx_http_only() {
    print_status "Menyiapkan Nginx reverse proxy untuk HTTP only..."
    
    # Load ports dari konfigurasi yang tersimpan
    if [[ -f /root/xray-ports.conf ]]; then
        source /root/xray-ports.conf
    else
        # Fallback jika file tidak ada, baca dari config Xray
        VMESS_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vmess'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "10001")
        VLESS_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vless'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "20001")
        TROJAN_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='trojan'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "30001")
    fi
    
    print_status "Menggunakan ports: VMess=$VMESS_PORT, VLESS=$VLESS_PORT, Trojan=$TROJAN_PORT"
    
    # Backup konfigurasi nginx default
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup 2>/dev/null || true
    
    # Buat konfigurasi Nginx tanpa SSL
    cat > /etc/nginx/sites-available/xray << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # Security Headers (basic)
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Hide nginx version
    server_tokens off;
    
    # Default page (untuk menyamarkan)
    location / {
        root /var/www/html;
        index index.html index.htm;
        try_files \$uri \$uri/ =404;
    }
    
    # VMess WebSocket Proxy
    location /vmessws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$VMESS_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }
    
    # VLESS WebSocket Proxy
    location /vlessws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$VLESS_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }
    
    # Trojan WebSocket Proxy
    location /trojanws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$TROJAN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }
    
    # Block direct access to admin paths
    location ~* /(admin|api|config) {
        return 404;
    }
    
    # Log configuration
    access_log /var/log/nginx/xray_access.log;
    error_log /var/log/nginx/xray_error.log;
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Create camouflage website
    create_camouflage_website
    
    # Test nginx configuration
    if nginx -t; then
        systemctl enable nginx
        systemctl restart nginx
        print_status "✅ Nginx HTTP reverse proxy berhasil dikonfigurasi"
    else
        print_error "Konfigurasi Nginx tidak valid"
        return 1
    fi
}

# Setup Let's Encrypt SSL
setup_letsencrypt_ssl() {
    echo ""
    read -p "Masukkan domain Anda (contoh: proxy.example.com): " domain
    
    if [[ -z "$domain" ]]; then
        print_error "Domain tidak boleh kosong!"
        setup_selfsigned_ssl
        return 1
    fi
    
    # Validasi format domain
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)+$ ]]; then
        print_error "Format domain tidak valid!"
        setup_selfsigned_ssl
        return 1
    fi
    
    # Verifikasi DNS dan port access
    if ! verify_port_access "$domain"; then
        echo ""
        read -p "Domain belum siap. Lanjutkan dengan self-signed SSL? (y/n): " continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            print_status "Silakan perbaiki konfigurasi domain dan coba lagi"
            return 1
        fi
        setup_selfsigned_ssl
        return 1
    fi
    
    read -p "Masukkan email untuk Let's Encrypt: " email
    if [[ -z "$email" ]]; then
        email="admin@$domain"
    fi
    
    # PENTING: Buka port 80/443 terlebih dahulu untuk Let's Encrypt validation
    print_status "Membuka port 80/443 untuk validasi SSL..."
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp
        ufw allow 443/tcp
        print_status "UFW: Port 80/443 telah dibuka"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
        print_status "Firewalld: Port 80/443 telah dibuka"
    else
        print_warning "Firewall tidak terdeteksi. Pastikan port 80/443 terbuka di cloud provider!"
    fi
    
    # Hentikan nginx sementara untuk certbot standalone
    systemctl stop nginx 2>/dev/null || true
    
    # Generate Let's Encrypt certificate
    print_status "Meminta sertifikat SSL dari Let's Encrypt..."
    
    if certbot certonly --standalone --non-interactive --agree-tos --email "$email" -d "$domain"; then
        # Copy certificate ke direktori Xray
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "$SSL_DIR/fullchain.pem"
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "$SSL_DIR/privkey.pem"
        
        # Set permissions
        chmod 644 "$SSL_DIR/fullchain.pem"
        chmod 600 "$SSL_DIR/privkey.pem"
        
        # Setup auto-renewal
        setup_ssl_renewal "$domain"
        
        print_status "✅ Sertifikat SSL Let's Encrypt berhasil dipasang!"
        
        # Setup Nginx reverse proxy
        setup_nginx_reverse_proxy "$domain"
        
        USE_SSL=true
        DOMAIN="$domain"
        SSL_TYPE="letsencrypt"
        
    else
        print_error "Gagal mendapatkan sertifikat Let's Encrypt"
        print_status "Menggunakan self-signed certificate sebagai fallback"
        setup_selfsigned_ssl
    fi
}

# Setup Self-Signed SSL
setup_selfsigned_ssl() {
    print_status "Membuat self-signed SSL certificate..."
    
    # Generate self-signed certificate
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=XrayProxy/CN=localhost" \
        -keyout "$SSL_DIR/privkey.pem" \
        -out "$SSL_DIR/fullchain.pem"
    
    # Set permissions
    chmod 644 "$SSL_DIR/fullchain.pem"
    chmod 600 "$SSL_DIR/privkey.pem"
    
    print_status "✅ Self-signed SSL certificate berhasil dibuat"
    
    # Setup Nginx dengan self-signed cert
    setup_nginx_reverse_proxy "localhost"
    
    USE_SSL=true
    DOMAIN="localhost"
    SSL_TYPE="selfsigned"
}

# Setup Nginx Reverse Proxy
setup_nginx_reverse_proxy() {
    local domain="$1"
    
    print_status "Menyiapkan Nginx reverse proxy untuk $domain..."
    
    # Load ports dari konfigurasi yang tersimpan
    if [[ -f /root/xray-ports.conf ]]; then
        source /root/xray-ports.conf
    else
        # Fallback jika file tidak ada, baca dari config Xray
        VMESS_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vmess'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "10001")
        VLESS_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vless'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "20001")
        TROJAN_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='trojan'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "30001")
    fi
    
    print_status "Menggunakan ports: VMess=$VMESS_PORT, VLESS=$VLESS_PORT, Trojan=$TROJAN_PORT"
    
    # Backup konfigurasi nginx default
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup 2>/dev/null || true
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup 2>/dev/null || true
    
    # Buat konfigurasi Nginx untuk Xray
    cat > /etc/nginx/sites-available/xray << EOF
server {
    listen 80;
    server_name $domain;
    
    # Redirect HTTP to HTTPS
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;
    
    # SSL Configuration
    ssl_certificate $SSL_DIR/fullchain.pem;
    ssl_certificate_key $SSL_DIR/privkey.pem;
    
    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Hide nginx version
    server_tokens off;
    
    # Default page (untuk menyamarkan)
    location / {
        root /var/www/html;
        index index.html index.htm;
        try_files \$uri \$uri/ =404;
    }
    
    # VMess WebSocket Proxy
    location /vmessws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$VMESS_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }
    
    # VLESS WebSocket Proxy
    location /vlessws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$VLESS_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }
    
    # Trojan WebSocket Proxy
    location /trojanws {
        if (\$http_upgrade != "websocket") {
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:$TROJAN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 52w;
    }
    
    # Block direct access to admin paths
    location ~* /(admin|api|config) {
        return 404;
    }
    
    # Log configuration
    access_log /var/log/nginx/xray_access.log;
    error_log /var/log/nginx/xray_error.log;
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/xray /etc/nginx/sites-enabled/
    
    # Remove default site
    rm -f /etc/nginx/sites-enabled/default
    
    # Create camouflage website
    create_camouflage_website
    
    # Test nginx configuration
    if nginx -t; then
        systemctl enable nginx
        systemctl restart nginx
        print_status "✅ Nginx reverse proxy berhasil dikonfigurasi"
    else
        print_error "Konfigurasi Nginx tidak valid"
        return 1
    fi
}

# Buat website penyamaran
create_camouflage_website() {
    print_status "Membuat website penyamaran..."
    
    mkdir -p /var/www/html
    
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Selamat Datang</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            max-width: 600px;
        }
        h1 {
            font-size: 3em;
            margin-bottom: 20px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        p {
            font-size: 1.2em;
            line-height: 1.6;
            opacity: 0.9;
        }
        .footer {
            margin-top: 40px;
            font-size: 0.9em;
            opacity: 0.7;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Selamat Datang</h1>
        <p>Website ini sedang dalam pengembangan.</p>
        <p>Terima kasih atas kunjungan Anda.</p>
        <div class="footer">
            <p>&copy; 2024 - Website Development</p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Set permissions
    chown -R www-data:www-data /var/www/html 2>/dev/null || chown -R nginx:nginx /var/www/html 2>/dev/null
    chmod -R 755 /var/www/html
    
    print_status "Website penyamaran berhasil dibuat"
}

# Setup SSL Auto-Renewal
setup_ssl_renewal() {
    local domain="$1"
    
    print_status "Menyiapkan auto-renewal SSL certificate..."
    
    # Buat script renewal
    cat > /usr/local/bin/xray-ssl-renew << EOF
#!/bin/bash

# Xray SSL Certificate Renewal Script

# Renew certificate
certbot renew --quiet --nginx

# Copy new certificates if renewed
if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
    cp "/etc/letsencrypt/live/$domain/fullchain.pem" "$SSL_DIR/fullchain.pem"
    cp "/etc/letsencrypt/live/$domain/privkey.pem" "$SSL_DIR/privkey.pem"
    
    # Set permissions
    chmod 644 "$SSL_DIR/fullchain.pem"
    chmod 600 "$SSL_DIR/privkey.pem"
    
    # Restart services
    systemctl reload nginx
    systemctl restart xray
    
    echo "\$(date): SSL certificate renewed and services restarted" >> /var/log/xray-ssl-renew.log
fi
EOF
    
    chmod +x /usr/local/bin/xray-ssl-renew
    
    # Add to crontab (check renewal daily at 2:30 AM)
    (crontab -l 2>/dev/null; echo "30 2 * * * /usr/local/bin/xray-ssl-renew >/dev/null 2>&1") | crontab -
    
    print_status "Auto-renewal SSL berhasil dikonfigurasi"
}

# Generate UUID
generate_uuid() {
    UUID=$(cat /proc/sys/kernel/random/uuid)
    print_status "Generated UUID: $UUID"
}

# Input domain dan konfigurasi SSL saat instalasi
setup_domain_and_ssl_choice() {
    echo ""
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}    KONFIGURASI DOMAIN & SSL           ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
    
    print_status "Konfigurasi domain dan SSL untuk Xray server Anda"
    echo ""
    
    echo -e "${GREEN}Informasi Penting:${NC}"
    echo "Server IP Anda: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo "Untuk keamanan maksimal, disarankan menggunakan domain dengan SSL Let's Encrypt"
    echo ""
    
    echo "${YELLOW}Pilihan konfigurasi SSL:${NC}"
    echo "1. Gunakan Domain dengan SSL Let's Encrypt (Direkomendasikan)"
    echo "2. Gunakan IP Server dengan Self-Signed SSL"
    echo "3. Skip SSL (HTTP Only - Tidak direkomendasikan)"
    echo ""
    
    while true; do
        read -p "Pilih opsi [1-3]: " ssl_choice
        
        case $ssl_choice in
            1)
                echo ""
                print_status "Anda memilih: Domain dengan SSL Let's Encrypt"
                echo ""
                
                echo -e "${GREEN}Persyaratan untuk Let's Encrypt SSL:${NC}"
                echo "✓ Domain harus sudah mengarah ke IP server ini ($(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'))"
                echo "✓ Port 80 dan 443 harus terbuka dan dapat diakses dari internet"
                echo "✓ Domain harus valid dan dapat di-resolve"
                echo "✓ Firewall tidak boleh memblokir port 80/443 (akan dibuka otomatis)"
                echo "✓ Cloud provider (AWS/GCP/Azure) security group harus mengizinkan port 80/443"
                echo ""
                
                echo -e "${BLUE}Cara setting domain:${NC}"
                echo "1. Login ke DNS provider Anda (Cloudflare, GoDaddy, Namecheap, dll)"
                echo "2. Buat A Record yang mengarah ke IP server ini:"
                echo "   Nama: proxy (atau subdomain lain)"
                echo "   Type: A"
                echo "   Value: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
                echo "   TTL: 300 (atau Auto)"
                echo "3. Tunggu propagasi DNS (5-30 menit)"
                echo "4. Test dengan: ping proxy.yourdomain.com"
                echo ""
                
                print_warning "Pastikan domain sudah mengarah ke server sebelum melanjutkan!"
                echo ""
                
                # Input domain
                while true; do
                    read -p "Masukkan domain Anda (contoh: proxy.example.com): " domain_input
                    
                    if [[ -z "$domain_input" ]]; then
                        print_error "Domain tidak boleh kosong!"
                        continue
                    fi
                    
                    # Validasi format domain
                    if [[ ! "$domain_input" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)+$ ]]; then
                        print_error "Format domain tidak valid!"
                        echo "Contoh format yang benar: proxy.example.com, vpn.mydomain.net"
                        continue
                    fi
                    
                    # Test DNS resolution
                    print_status "Melakukan test DNS resolution untuk $domain_input..."
                    
                    domain_ip=$(dig +short "$domain_input" @8.8.8.8 2>/dev/null | tail -1)
                    server_ip=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
                    
                    if [[ -n "$domain_ip" ]]; then
                        if [[ "$domain_ip" == "$server_ip" ]]; then
                            print_status "✅ Domain sudah mengarah ke server ini ($server_ip)"
                        else
                            print_warning "⚠️ Domain mengarah ke IP yang berbeda!"
                            echo "Domain mengarah ke: $domain_ip"
                            echo "Server IP: $server_ip"
                            echo ""
                            read -p "Lanjutkan tetap dengan domain ini? (y/N): " force_continue
                            if [[ "$force_continue" != "y" && "$force_continue" != "Y" ]]; then
                                print_status "Silakan perbaiki DNS record dan coba lagi."
                                continue
                            fi
                        fi
                    else
                        print_error "Domain tidak dapat di-resolve!"
                        echo "Kemungkinan penyebab:"
                        echo "- DNS record belum dibuat"  
                        echo "- Propagasi DNS belum selesai"
                        echo "- Kesalahan penulisan domain"
                        echo ""
                        read -p "Lanjutkan tetap dengan domain ini? (y/N): " force_continue
                        if [[ "$force_continue" != "y" && "$force_continue" != "Y" ]]; then
                            continue
                        fi
                    fi
                    
                    # Konfirmasi domain
                    echo ""
                    print_status "Domain yang akan digunakan: $domain_input"
                    read -p "Apakah domain ini sudah benar? (y/n): " confirm_domain
                    
                    if [[ "$confirm_domain" == "y" || "$confirm_domain" == "Y" ]]; then
                        DOMAIN="$domain_input"
                        break
                    fi
                done
                
                # Input email (opsional)
                echo ""
                read -p "Masukkan email untuk Let's Encrypt (kosongkan untuk default admin@$DOMAIN): " email_input
                if [[ -z "$email_input" ]]; then
                    SSL_EMAIL="admin@$DOMAIN"
                else
                    SSL_EMAIL="$email_input"
                fi
                
                # Set variabel SSL
                USE_SSL=true
                SSL_TYPE="letsencrypt"
                
                print_status "Konfigurasi SSL Let's Encrypt siap!"
                print_status "Domain: $DOMAIN"
                print_status "Email: $SSL_EMAIL"
                break
                ;;
            2)
                print_status "Anda memilih: Self-Signed SSL"
                echo ""
                
                print_warning "Self-signed certificate akan dibuat."
                print_warning "Client harus mengaktifkan 'Allow Insecure' atau 'Skip Certificate Verification'"
                echo ""
                
                # Gunakan IP server
                SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
                DOMAIN="$SERVER_IP"
                USE_SSL=true
                SSL_TYPE="selfsigned"
                
                print_status "Self-signed SSL akan dibuat untuk IP: $SERVER_IP"
                break
                ;;
            3)
                print_warning "Anda memilih: Skip SSL (HTTP Only)"
                print_warning "Koneksi tidak akan dienkripsi - SANGAT TIDAK DIREKOMENDASIKAN!"
                print_warning "Traffic dapat dengan mudah disadap dan diblokir!"
                echo ""
                
                read -p "Yakin ingin melanjutkan tanpa SSL? (y/N): " confirm_no_ssl
                if [[ "$confirm_no_ssl" == "y" || "$confirm_no_ssl" == "Y" ]]; then
                    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
                    DOMAIN="$SERVER_IP"
                    USE_SSL=false
                    SSL_TYPE="none"
                    
                    print_status "Konfigurasi HTTP-only siap untuk IP: $SERVER_IP"
                    break
                else
                    print_status "Silakan pilih opsi SSL yang aman."
                    continue
                fi
                ;;
            *)
                print_error "Pilihan tidak valid! Masukkan 1, 2, atau 3."
                continue
                ;;
        esac
    done
    
    echo ""
    print_status "Konfigurasi domain dan SSL selesai!"
    echo ""
}

# Buat konfigurasi Xray canggih dengan SSL dan reverse proxy
create_config() {
    print_status "Membuat konfigurasi multi-protocol dengan SSL..."
    
    # Dapatkan IP server
    SERVER_IP=$(curl -s ifconfig.me)
    
    # Generate multiple random ports untuk backend
    VMESS_PORT=$((RANDOM % 10000 + 10000))
    VLESS_PORT=$((RANDOM % 10000 + 20000)) 
    TROJAN_PORT=$((RANDOM % 10000 + 30000))
    STATS_PORT=$((RANDOM % 1000 + 8000))
    
    # Simpan ports ke file untuk digunakan oleh fungsi lain
    echo "VMESS_PORT=$VMESS_PORT" > /root/xray-ports.conf
    echo "VLESS_PORT=$VLESS_PORT" >> /root/xray-ports.conf
    echo "TROJAN_PORT=$TROJAN_PORT" >> /root/xray-ports.conf
    echo "STATS_PORT=$STATS_PORT" >> /root/xray-ports.conf
    echo "DOMAIN=$DOMAIN" >> /root/xray-ports.conf
    echo "USE_SSL=$USE_SSL" >> /root/xray-ports.conf
    echo "SSL_TYPE=$SSL_TYPE" >> /root/xray-ports.conf
    
    # Export ports untuk digunakan di reverse proxy
    export VMESS_PORT VLESS_PORT TROJAN_PORT DOMAIN USE_SSL SSL_TYPE
    
    # Tentukan konfigurasi SSL berdasarkan setup
    local use_tls="false"
    local cert_file=""
    local key_file=""
    
    if [[ "$USE_SSL" == "true" ]]; then
        use_tls="true"
        cert_file="$SSL_DIR/fullchain.pem"
        key_file="$SSL_DIR/privkey.pem"
    fi
    
    # Buat konfigurasi canggih dengan SSL support
    cat > "$CONFIG_DIR/config.json" << EOF
{
    "log": {
        "loglevel": "info",
        "access": "$LOG_DIR/access.log",
        "error": "$LOG_DIR/error.log"
    },
    "api": {
        "tag": "api",
        "services": ["HandlerService", "LoggerService", "StatsService"]
    },
    "stats": {},
    "policy": {
        "levels": {
            "0": {
                "handshake": 4,
                "connIdle": 300,
                "uplinkOnly": 2,
                "downlinkOnly": 5,
                "statsUserUplink": true,
                "statsUserDownlink": true
            }
        },
        "system": {
            "statsInboundUplink": true,
            "statsInboundDownlink": true,
            "statsOutboundUplink": true,
            "statsOutboundDownlink": true
        }
    },
    "inbounds": [
        {
            "port": $STATS_PORT,
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1"
            },
            "tag": "api"
        },
        {
            "port": $VMESS_PORT,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "level": 0,
                        "alterId": 0,
                        "email": "admin@vmess.local"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vmessws",
                    "headers": {
                        "Host": "$DOMAIN"
                    }
                }
            },
            "tag": "vmess-in",
            "sniffing": {
                "enabled": true,
                "destOverride": ["http", "tls"]
            }
        },
        {
            "port": $VLESS_PORT,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID",
                        "level": 0,
                        "email": "admin@vless.local"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/vlessws",
                    "headers": {
                        "Host": "$DOMAIN"
                    }
                }
            },
            "tag": "vless-in",
            "sniffing": {
                "enabled": true,
                "destOverride": ["http", "tls"]
            }
        },
        {
            "port": $TROJAN_PORT,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "$UUID",
                        "level": 0,
                        "email": "admin@trojan.local"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/trojanws",
                    "headers": {
                        "Host": "$DOMAIN"
                    }
                }
            },
            "tag": "trojan-in"
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4"
            },
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "settings": {},
            "tag": "blocked"
        }
    ],
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "inboundTag": ["api"],
                "outboundTag": "api",
                "type": "field"
            },
            {
                "type": "field",
                "protocol": ["bittorrent"],
                "outboundTag": "blocked"
            },
            {
                "type": "field",
                "domain": [
                    "geosite:category-ads-all"
                ],
                "outboundTag": "blocked"
            },
            {
                "type": "field",
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "blocked"
            }
        ]
    }
}
EOF

    # Simpan admin user ke database
    if [[ ! -f "$USER_DB" ]]; then
        init_user_database
    fi
    created_date=$(date +"%Y-%m-%d")
    echo "admin:$UUID:admin@xray.local:$created_date:never:active:unlimited:0" >> "$USER_DB"
    
    print_status "Konfigurasi multi-protocol dengan SSL berhasil dibuat!"
    print_status "VMess Port (Backend): $VMESS_PORT"
    print_status "VLESS Port (Backend): $VLESS_PORT"
    print_status "Trojan Port (Backend): $TROJAN_PORT"
    
    if [[ "$USE_SSL" == "true" ]]; then
        print_status "SSL/TLS: AKTIF (melalui Nginx reverse proxy)"
        print_status "Domain: $DOMAIN"
    else
        print_status "SSL/TLS: TIDAK AKTIF (HTTP only)"
    fi
}

# Create systemd service
create_service() {
    print_status "Creating systemd service..."
    
    cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xray
    print_status "Systemd service created and enabled!"
}

# Configure firewall for multiple ports
configure_firewall() {
    print_status "Configuring firewall for multi-protocol setup..."
    
    # Get ports from config
    VMESS_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vmess'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "10001")
    VLESS_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vless'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "20001")
    TROJAN_PORT=$(python3 -c "import json,sys; config_path=sys.argv[1]; config=json.load(open(config_path)); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='trojan'][0])" "$CONFIG_DIR/config.json" 2>/dev/null || echo "30001")
    
    if command -v ufw >/dev/null 2>&1; then
        ufw allow $VMESS_PORT/tcp
        ufw allow $VLESS_PORT/tcp
        ufw allow $TROJAN_PORT/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        print_status "UFW firewall configured for all protocols"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=$VMESS_PORT/tcp
        firewall-cmd --permanent --add-port=$VLESS_PORT/tcp
        firewall-cmd --permanent --add-port=$TROJAN_PORT/tcp
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
        print_status "Firewalld configured for all protocols"
    else
        print_warning "No firewall detected. Please manually open ports: $VMESS_PORT, $VLESS_PORT, $TROJAN_PORT, 80, 443"
    fi
}

# Start Xray service
start_xray() {
    print_status "Starting Xray service..."
    systemctl start xray
    
    if systemctl is-active --quiet xray; then
        print_status "Xray service started successfully!"
    else
        print_error "Failed to start Xray service!"
        exit 1
    fi
}

# Generate konfigurasi client canggih dengan SSL
generate_client_config() {
    print_status "Membuat konfigurasi client canggih dengan SSL..."
    
    # Tentukan server address
    local server_addr
    if [[ "$USE_SSL" == "true" && -n "$DOMAIN" && "$DOMAIN" != "localhost" ]]; then
        server_addr="$DOMAIN"
    else
        server_addr=$(curl -s ifconfig.me)
    fi
    
    # Tentukan port dan security
    local web_port
    local security_type
    local tls_setting
    
    if [[ "$USE_SSL" == "true" ]]; then
        web_port="443"
        security_type="tls"
        tls_setting="\"tls\":\"tls\""
    else
        web_port="80"
        security_type="none"
        tls_setting="\"tls\":\"\""
    fi
    
    echo ""
    echo "==========================================="
    echo "KONFIGURASI CLIENT XRAY CANGGIH"
    echo "==========================================="
    echo ""
    echo -e "${GREEN}VMess Configuration (WebSocket + SSL):${NC}"
    echo "Server: $server_addr"
    echo "Port: $web_port"
    echo "UUID: $UUID"
    echo "AlterID: 0"
    echo "Security: auto"
    echo "Network: ws"
    echo "Path: /vmessws"
    echo "TLS: $security_type"
    if [[ "$SSL_TYPE" == "selfsigned" ]]; then
        echo "⚠️  Allow Insecure: true (self-signed cert)"
    fi
    echo ""
    echo -e "${BLUE}VLESS Configuration (WebSocket + SSL):${NC}"
    echo "Server: $server_addr"
    echo "Port: $web_port"
    echo "UUID: $UUID"
    echo "Encryption: none"
    echo "Network: ws"
    echo "Path: /vlessws"
    echo "TLS: $security_type"
    if [[ "$SSL_TYPE" == "selfsigned" ]]; then
        echo "⚠️  Allow Insecure: true (self-signed cert)"
    fi
    echo ""
    echo -e "${YELLOW}Trojan Configuration (WebSocket + SSL):${NC}"
    echo "Server: $server_addr"
    echo "Port: $web_port"
    echo "Password: $UUID"
    echo "Network: ws"
    echo "Path: /trojanws"
    echo "TLS: $security_type"
    if [[ "$SSL_TYPE" == "selfsigned" ]]; then
        echo "⚠️  Allow Insecure: true (self-signed cert)"
    fi
    echo ""
    echo "==========================================="
    echo ""
    
    # Generate connection links
    local vmess_link
    local vless_link
    local trojan_link
    
    if [[ "$SSL_TYPE" == "selfsigned" ]]; then
        # Self-signed certificate - allow insecure
        vmess_link=$(echo -n "{\"v\":\"2\",\"ps\":\"Xray-VMess-SSL\",\"add\":\"$server_addr\",\"port\":\"$web_port\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$server_addr\",\"path\":\"/vmessws\",$tls_setting,\"allowInsecure\":true}" | base64 -w 0)
        vless_link="vless://$UUID@$server_addr:$web_port?encryption=none&security=$security_type&type=ws&host=$server_addr&path=%2Fvlessws&allowInsecure=1#Xray-VLESS-SSL"
        trojan_link="trojan://$UUID@$server_addr:$web_port?security=$security_type&type=ws&host=$server_addr&path=%2Ftrojanws&allowInsecure=1#Xray-Trojan-SSL"
    else
        # Valid certificate
        vmess_link=$(echo -n "{\"v\":\"2\",\"ps\":\"Xray-VMess-SSL\",\"add\":\"$server_addr\",\"port\":\"$web_port\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$server_addr\",\"path\":\"/vmessws\",$tls_setting}" | base64 -w 0)
        vless_link="vless://$UUID@$server_addr:$web_port?encryption=none&security=$security_type&type=ws&host=$server_addr&path=%2Fvlessws#Xray-VLESS-SSL"
        trojan_link="trojan://$UUID@$server_addr:$web_port?security=$security_type&type=ws&host=$server_addr&path=%2Ftrojanws#Xray-Trojan-SSL"
    fi
    
    echo -e "${GREEN}Link Koneksi:${NC}"
    echo "VMess: vmess://$vmess_link"
    echo "VLESS: $vless_link"
    echo "Trojan: $trojan_link"
    echo ""
    
    # Simpan ke file
    cat > /root/xray-ssl-config.txt << EOF
KONFIGURASI CLIENT XRAY DENGAN SSL
=================================

Informasi Server:
Domain/IP: $server_addr
SSL Status: $([[ "$USE_SSL" == "true" ]] && echo "AKTIF" || echo "TIDAK AKTIF")
SSL Type: $([[ -n "$SSL_TYPE" ]] && echo "$SSL_TYPE" || echo "none")
Reverse Proxy: Nginx

VMess Configuration (WebSocket + SSL):
Server: $server_addr
Port: $web_port
UUID: $UUID
AlterID: 0
Security: auto
Network: ws
Path: /vmessws
TLS: $security_type
$([[ "$SSL_TYPE" == "selfsigned" ]] && echo "Allow Insecure: true")

VLESS Configuration (WebSocket + SSL):
Server: $server_addr
Port: $web_port
UUID: $UUID
Encryption: none
Network: ws
Path: /vlessws
TLS: $security_type
$([[ "$SSL_TYPE" == "selfsigned" ]] && echo "Allow Insecure: true")

Trojan Configuration (WebSocket + SSL):
Server: $server_addr
Port: $web_port
Password: $UUID
Network: ws
Path: /trojanws
TLS: $security_type
$([[ "$SSL_TYPE" == "selfsigned" ]] && echo "Allow Insecure: true")

Link Koneksi:
VMess: vmess://$vmess_link
VLESS: $vless_link
Trojan: $trojan_link

Fitur yang Diaktifkan:
- SSL/TLS Encryption via Nginx Reverse Proxy
- Multiple Protocols (VMess, VLESS, Trojan)
- WebSocket Support untuk semua protocol
- Website Camouflage
- Advanced Traffic Monitoring
- User Management System
- BBR Network Optimization
- Smart DNS Management

Catatan Keamanan:
- Semua traffic dienkripsi melalui SSL/TLS
- Server tersembunyi di balik reverse proxy
- Website penyamaran aktif pada port 80/443
- Auto SSL renewal (jika menggunakan Let's Encrypt)
EOF
    
    print_status "Konfigurasi client SSL tersimpan di /root/xray-ssl-config.txt"
    
    # Tampilkan informasi tambahan
    if [[ "$USE_SSL" == "true" ]]; then
        echo ""
        echo -e "${GREEN}✅ SSL/TLS AKTIF${NC}"
        echo "📱 Gunakan link di atas untuk client mobile/desktop"
        echo "🌐 Website penyamaran aktif di: https://$server_addr"
        if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
            echo "🔄 Auto-renewal SSL certificate aktif"
        fi
    else
        echo ""
        echo -e "${YELLOW}⚠️  SSL/TLS TIDAK AKTIF${NC}"
        echo "🔧 Untuk mengaktifkan SSL, jalankan setup ulang dengan domain"
    fi
}

# Create global menu command
create_menu_command() {
    print_status "Creating global 'menu' command..."
    
    # Create menu script
    cat > /usr/local/bin/menu << 'EOF'
#!/bin/bash

# Xray Management Menu Script
# This script provides quick access to Xray management functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This command must be run as root!"
    echo "Please run: sudo menu"
    exit 1
fi

# Check if Xray is installed
if [[ ! -f /usr/local/bin/xray || ! -f /usr/local/etc/xray/config.json ]]; then
    print_error "Xray is not installed!"
    echo "Please install Xray first using the installation script."
    exit 1
fi

# Source the main management functions from the installation script
# First, let's find the installation script
INSTALL_SCRIPT=""
if [[ -f /root/xray-auto-install.sh ]]; then
    INSTALL_SCRIPT="/root/xray-auto-install.sh"
elif [[ -f /usr/local/bin/xray-auto-install.sh ]]; then
    INSTALL_SCRIPT="/usr/local/bin/xray-auto-install.sh"
else
    # Create a minimal management interface if main script not found
    print_warning "Main installation script not found. Using built-in management."
fi

if [[ -n "$INSTALL_SCRIPT" ]]; then
    # Execute the management menu from the main script
    bash "$INSTALL_SCRIPT" --manage
else
    # Fallback minimal menu
    show_minimal_menu
fi

# Minimal menu function (fallback)
show_minimal_menu() {
    while true; do
        clear
        echo -e "${BLUE}=================================${NC}"
        echo -e "${BLUE}    XRAY QUICK MANAGEMENT       ${NC}"
        echo -e "${BLUE}=================================${NC}"
        echo ""
        echo -e "${GREEN}1.${NC} View Service Status"
        echo -e "${GREEN}2.${NC} Restart Xray Service" 
        echo -e "${GREEN}3.${NC} Stop Xray Service"
        echo -e "${GREEN}4.${NC} Start Xray Service"
        echo -e "${GREEN}5.${NC} View Service Logs"
        echo -e "${GREEN}6.${NC} Show Configuration"
        echo -e "${RED}0.${NC} Exit"
        echo ""
        echo -n "Please select an option [0-6]: "
        read choice
        
        case $choice in
            1)
                echo ""
                print_status "Xray Service Status:"
                systemctl status xray --no-pager
                echo ""
                print_status "Service is: $(systemctl is-active xray)"
                read -p "Press Enter to continue..."
                ;;
            2)
                print_status "Restarting Xray service..."
                systemctl restart xray
                print_status "Service restarted. Status: $(systemctl is-active xray)"
                read -p "Press Enter to continue..."
                ;;
            3)
                print_status "Stopping Xray service..."
                systemctl stop xray
                print_status "Service stopped. Status: $(systemctl is-active xray)"
                read -p "Press Enter to continue..."
                ;;
            4)
                print_status "Starting Xray service..."
                systemctl start xray
                print_status "Service started. Status: $(systemctl is-active xray)"
                read -p "Press Enter to continue..."
                ;;
            5)
                echo ""
                print_status "Recent Xray logs:"
                journalctl -u xray --no-pager -n 30
                read -p "Press Enter to continue..."
                ;;
            6)
                echo ""
                print_status "Current Configuration:"
                if [[ -f /root/xray-client-config.txt ]]; then
                    cat /root/xray-client-config.txt
                else
                    print_warning "Client configuration not found at /root/xray-client-config.txt"
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option! Please try again."
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}
EOF

    # Make the menu command executable
    chmod +x /usr/local/bin/menu
    
    # Copy the main script to a system location for the menu command to use
    cp "$0" /root/xray-auto-install.sh
    
    print_status "Global 'menu' command created successfully!"
    print_status "You can now run 'sudo menu' from anywhere to access Xray management."
}

# Fungsi instalasi utama
main() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}    XRAY SCRIPT AUTO INSTALL CANGGIH     ${NC}"
    echo -e "${BLUE}              Versi $SCRIPT_VERSION                ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
    
    check_root
    detect_os
    update_system
    install_xray
    generate_uuid
    
    # Setup domain dan SSL choice sebelum konfigurasi
    setup_domain_and_ssl_choice
    
    create_config
    create_service
    configure_firewall
    start_xray
    generate_client_config
    create_menu_command
    
    echo ""
    print_status "🎉 Instalasi Xray canggih berhasil diselesaikan!"
    print_status "📊 Status service: $(systemctl is-active xray)"
    print_status "📁 File konfigurasi: $CONFIG_DIR/config.json"
    print_status "📋 Konfigurasi client: /root/xray-ssl-config.txt"
    print_status "👥 Database user: $USER_DB"
    echo ""
    print_status "🚀 Fitur Canggih yang Diaktifkan:"
    echo "   ✅ Multi Protocol (VMess, VLESS, Trojan)"
    echo "   ✅ Dukungan WebSocket"
    echo "   ✅ Optimasi BBR Network"
    echo "   ✅ Manajemen DNS Cerdas"
    echo "   ✅ Monitoring Traffic Real-time"
    echo "   ✅ Manajemen User dengan Masa Berlaku"
    echo "   ✅ Sistem Backup Canggih"
    echo "   ✅ Tes Kecepatan Jaringan"
    
    # Tampilkan informasi SSL berdasarkan konfigurasi
    if [[ "$USE_SSL" == "true" ]]; then
        echo "   ✅ SSL/TLS Encryption (${SSL_TYPE})"
        echo "   ✅ Nginx Reverse Proxy"
        echo "   ✅ Website Camouflage"
    else
        echo "   ⚠️ HTTP Only (Tidak direkomendasikan)"
    fi
    
    echo ""
    
    # Tampilkan informasi optimasi
    echo -e "${GREEN}💹 Status Optimasi:${NC}"
    local bbr_status=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
    if [[ "$bbr_status" == "bbr" ]]; then
        echo "   ✅ BBR: AKTIF (${bbr_status})"
    else
        echo "   ⚠️ BBR: TIDAK AKTIF (${bbr_status})"
    fi
    
    local current_dns=$(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}' 2>/dev/null || echo "default")
    echo "   🌐 DNS: $current_dns"
    
    # Tampilkan informasi koneksi
    echo ""
    echo -e "${BLUE}🌐 Informasi Koneksi:${NC}"
    if [[ "$USE_SSL" == "true" ]]; then
        if [[ "$SSL_TYPE" == "letsencrypt" ]]; then
            echo "   📱 Server: https://$DOMAIN"
            echo "   🔒 SSL: Let's Encrypt (Valid Certificate)"
            echo "   🔄 Auto-renewal: AKTIF"
        else
            echo "   📱 Server: https://$DOMAIN"
            echo "   🔒 SSL: Self-Signed (Allow Insecure diperlukan)"
        fi
        echo "   💻 Website: https://$DOMAIN (Camouflage)"
    else
        echo "   📱 Server: http://$DOMAIN"
        echo "   ⚠️ SSL: TIDAK AKTIF"
    fi
    
    echo ""
    print_status "🎮 Untuk mengakses panel manajemen canggih, jalankan: sudo menu"
    print_status "📧 Untuk manajemen DNS: xray-dns-manager"
    if [[ "$USE_SSL" == "true" ]]; then
        print_status "🔒 Untuk manajemen SSL: sudo menu (pilih opsi 14)"
    fi
    print_warning "⚠️  Silakan simpan informasi konfigurasi client Anda!"
    echo ""
    
    # Tampilkan ringkasan perintah berguna
    echo -e "${BLUE}Perintah Berguna:${NC}"
    echo "- sudo menu                    : Panel manajemen utama"
    echo "- xray-dns-manager auto        : Pilih DNS tercepat"
    echo "- xray-dns-manager status      : Lihat status DNS"
    echo "- systemctl status xray        : Status service Xray"
    if [[ "$USE_SSL" == "true" ]]; then
        echo "- systemctl status nginx       : Status Nginx reverse proxy"
    fi
    echo ""
}

# User management functions
show_menu() {
    clear
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}    XRAY PANEL MANAJEMEN CANGGIH      ${NC}"
    echo -e "${BLUE}       SSL + Reverse Proxy + BBR      ${NC}"
    echo -e "${BLUE}            Versi $SCRIPT_VERSION               ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
    echo -e "${GREEN}📊 MANAJEMEN USER:${NC}"
    echo -e "${GREEN}1.${NC}  Tambah User Baru (dengan masa berlaku & limit)"
    echo -e "${GREEN}2.${NC}  Hapus User"
    echo -e "${GREEN}3.${NC}  Lihat Semua User (dengan statistik)"
    echo -e "${GREEN}4.${NC}  Tampilkan Konfigurasi User"
    echo -e "${GREEN}5.${NC}  Edit Pengaturan User"
    echo ""
    echo -e "${YELLOW}📈 MONITORING & STATISTIK:${NC}"
    echo -e "${YELLOW}6.${NC}  Lihat Statistik Traffic"
    echo -e "${YELLOW}7.${NC}  Monitor Sistem Real-time"
    echo -e "${YELLOW}8.${NC}  Generate Laporan Penggunaan"
    echo ""
    echo -e "${BLUE}⚙️  MANAJEMEN SERVICE:${NC}"
    echo -e "${BLUE}9.${NC}  Lihat Status Service"
    echo -e "${BLUE}10.${NC} Lihat Log Service"
    echo -e "${BLUE}11.${NC} Restart Xray Service"
    echo -e "${BLUE}12.${NC} Stop/Start Xray Service"
    echo -e "${BLUE}13.${NC} Update Xray"
    echo ""
    echo -e "${YELLOW}🔒 SSL & REVERSE PROXY:${NC}"
    echo -e "${YELLOW}14.${NC} Manajemen SSL Certificate"
    echo -e "${YELLOW}15.${NC} Status Nginx Reverse Proxy"
    echo -e "${YELLOW}16.${NC} Konfigurasi Ulang SSL"
    echo ""
    echo -e "${YELLOW}🌐 OPTIMASI JARINGAN:${NC}"
    echo -e "${YELLOW}17.${NC} Manajemen DNS"
    echo -e "${YELLOW}18.${NC} Status Optimasi BBR"
    echo -e "${YELLOW}19.${NC} Tes Kecepatan Jaringan"
    echo ""
    echo -e "${YELLOW}🔒 FITUR CANGGIH:${NC}"
    echo -e "${YELLOW}20.${NC} Konfigurasi Protocol"
    echo -e "${YELLOW}21.${NC} Audit Keamanan"
    echo -e "${YELLOW}22.${NC} Backup Konfigurasi"
    echo -e "${YELLOW}23.${NC} Restore Konfigurasi"
    echo -e "${YELLOW}24.${NC} Pembersihan Sistem"
    echo ""
    echo -e "${RED}0.${NC}  Keluar"
    echo ""
    echo -n "Silakan pilih opsi [0-24]: "
}

# Advanced add user with expiry and limits
add_user() {
    echo ""
    print_status "Adding new user with advanced options..."
    
    read -p "Enter username: " username
    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi
    
    # Check if user already exists
    if grep -q "^$username:" "$USER_DB" 2>/dev/null; then
        print_error "User '$username' already exists!"
        return 1
    fi
    
    read -p "Enter email (optional): " email
    email=${email:-"$username@xray.local"}
    
    # Expiry date options
    echo ""
    echo "Expiry options:"
    echo "1. Never expire"
    echo "2. 7 days"
    echo "3. 30 days"
    echo "4. 90 days"
    echo "5. Custom date"
    read -p "Choose expiry option [1-5]: " exp_option
    
    case $exp_option in
        1) expiry="never" ;;
        2) expiry=$(date -d "+7 days" +"%Y-%m-%d") ;;
        3) expiry=$(date -d "+30 days" +"%Y-%m-%d") ;;
        4) expiry=$(date -d "+90 days" +"%Y-%m-%d") ;;
        5) 
            read -p "Enter expiry date (YYYY-MM-DD): " custom_date
            if date -d "$custom_date" >/dev/null 2>&1; then
                expiry="$custom_date"
            else
                print_error "Invalid date format!"
                return 1
            fi
            ;;
        *) expiry="never" ;;
    esac
    
    # Traffic limit options
    echo ""
    echo "Traffic limit options (GB):"
    echo "1. Unlimited"
    echo "2. 10 GB"
    echo "3. 50 GB"
    echo "4. 100 GB"
    echo "5. Custom limit"
    read -p "Choose traffic limit [1-5]: " limit_option
    
    case $limit_option in
        1) traffic_limit="unlimited" ;;
        2) traffic_limit="10" ;;
        3) traffic_limit="50" ;;
        4) traffic_limit="100" ;;
        5)
            read -p "Enter traffic limit (GB): " custom_limit
            if [[ "$custom_limit" =~ ^[0-9]+$ ]]; then
                traffic_limit="$custom_limit"
            else
                print_error "Invalid traffic limit!"
                return 1
            fi
            ;;
        *) traffic_limit="unlimited" ;;
    esac
    
    # Generate new UUID for user
    new_uuid=$(cat /proc/sys/kernel/random/uuid)
    created_date=$(date +"%Y-%m-%d")
    
    # Add user to database
    echo "$username:$new_uuid:$email:$created_date:$expiry:active:$traffic_limit:0" >> "$USER_DB"
    
    # Add user to configuration
    config_file="$CONFIG_DIR/config.json"
    cp "$config_file" "$config_file.backup"
    
    # Add to all protocol configurations using Python
    python3 -c "
import json
import sys

try:
    with open('$config_file', 'r') as f:
        config = json.load(f)
    
    for inbound in config['inbounds']:
        if inbound.get('protocol') == 'vmess':
            inbound['settings']['clients'].append({
                'id': '$new_uuid',
                'level': 0,
                'alterId': 0,
                'email': '$email'
            })
        elif inbound.get('protocol') == 'vless':
            inbound['settings']['clients'].append({
                'id': '$new_uuid',
                'level': 0,
                'email': '$email'
            })
        elif inbound.get('protocol') == 'trojan':
            inbound['settings']['clients'].append({
                'password': '$new_uuid',
                'level': 0,
                'email': '$email'
            })
    
    with open('$config_file', 'w') as f:
        json.dump(config, f, indent=4)
        
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)
" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        systemctl restart xray
        print_status "User '$username' added successfully!"
        print_status "UUID: $new_uuid"
        print_status "Email: $email"
        print_status "Expiry: $expiry"
        print_status "Traffic Limit: $traffic_limit GB"
        
        generate_user_config "$username" "$new_uuid"
    else
        print_error "Failed to add user to configuration!"
        # Remove from database if config update failed
        grep -v "^$username:" "$USER_DB" > "/tmp/xray-users-temp.txt"
        mv "/tmp/xray-users-temp.txt" "$USER_DB"
    fi
}

# Delete user
delete_user() {
    echo ""
    print_status "Menghapus user..."
    
    if [[ ! -f "$USER_DB" ]]; then
        print_error "Database user tidak ditemukan!"
        return 1
    fi
    
    echo "User yang tersedia:"
    local count=1
    while IFS=':' read -r username uuid email created expiry status total_limit used_traffic; do
        if [[ "$username" =~ ^#.* ]] || [[ -z "$username" ]]; then
            continue
        fi
        echo "$count. $username ($status)"
        ((count++))
    done < "$USER_DB"
    
    if [[ $count -eq 1 ]]; then
        print_error "Tidak ada user yang ditemukan!"
        return 1
    fi
    
    echo ""
    read -p "Masukkan username yang akan dihapus: " username
    if [[ -z "$username" ]]; then
        print_error "Username tidak boleh kosong!"
        return 1
    fi
    
    # Cari user UUID dari database
    user_uuid=$(grep "^$username:" "$USER_DB" | cut -d: -f2)
    
    if [[ -z "$user_uuid" ]]; then
        print_error "User '$username' tidak ditemukan!"
        return 1
    fi
    
    # Konfirmasi penghapusan
    echo ""
    print_warning "Akan menghapus user: $username"
    read -p "Yakin ingin menghapus user ini? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_status "Penghapusan dibatalkan."
        return 0
    fi
    
    config_file="$CONFIG_DIR/config.json"
    
    # Backup konfigurasi saat ini
    cp "$config_file" "$config_file.backup"
    
    # Hapus user dari konfigurasi menggunakan Python
    python3 -c "
import json
import sys

try:
    with open('$config_file', 'r') as f:
        config = json.load(f)
    
    user_found = False
    
    for inbound in config['inbounds']:
        if inbound.get('protocol') == 'vmess':
            original_count = len(inbound['settings']['clients'])
            inbound['settings']['clients'] = [
                client for client in inbound['settings']['clients'] 
                if client.get('id') != '$user_uuid'
            ]
            if len(inbound['settings']['clients']) < original_count:
                user_found = True
                
        elif inbound.get('protocol') == 'vless':
            original_count = len(inbound['settings']['clients'])
            inbound['settings']['clients'] = [
                client for client in inbound['settings']['clients'] 
                if client.get('id') != '$user_uuid'
            ]
            if len(inbound['settings']['clients']) < original_count:
                user_found = True
                
        elif inbound.get('protocol') == 'trojan':
            original_count = len(inbound['settings']['clients'])
            inbound['settings']['clients'] = [
                client for client in inbound['settings']['clients'] 
                if client.get('password') != '$user_uuid'
            ]
            if len(inbound['settings']['clients']) < original_count:
                user_found = True
    
    if not user_found:
        print('Error: User not found in configuration')
        sys.exit(1)
    
    with open('$config_file', 'w') as f:
        json.dump(config, f, indent=4)
        
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)
" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        # Hapus dari database user
        grep -v "^$username:" "$USER_DB" > "/tmp/xray-users-temp.txt"
        mv "/tmp/xray-users-temp.txt" "$USER_DB"
        
        # Hapus file konfigurasi user jika ada
        rm -f "/root/$username-config.txt"
        
        # Restart service Xray
        systemctl restart xray
        
        print_status "User '$username' berhasil dihapus!"
        print_status "Service Xray telah di-restart."
    else
        print_error "Gagal menghapus user dari konfigurasi!"
        # Restore backup jika gagal
        cp "$config_file.backup" "$config_file"
        return 1
    fi
}

# List all users with advanced information
list_users() {
    echo ""
    print_status "Current users with detailed information:"
    echo ""
    
    if [[ ! -f "$USER_DB" ]]; then
        print_warning "No users found!"
        return 1
    fi
    
    printf "${YELLOW}%-3s %-12s %-12s %-12s %-10s %-10s %-10s${NC}\n" "No." "Username" "Status" "Created" "Expiry" "Limit(GB)" "Used(MB)"
    echo "================================================================================="
    
    local count=1
    while IFS=':' read -r username uuid email created expiry status total_limit used_traffic; do
        if [[ "$username" =~ ^#.* ]] || [[ -z "$username" ]]; then
            continue
        fi
        
        # Convert bytes to MB
        used_mb=$((used_traffic / 1024 / 1024))
        
        # Color coding for status
        case $status in
            "active") status_color="${GREEN}$status${NC}" ;;
            "expired") status_color="${RED}$status${NC}" ;;
            "limited") status_color="${YELLOW}$status${NC}" ;;
            *) status_color="$status" ;;
        esac
        
        printf "%-3s %-12s %-20s %-12s %-10s %-10s %-10s\n" "$count" "$username" "$status_color" "$created" "$expiry" "$total_limit" "$used_mb"
        ((count++))
    done < "$USER_DB"
    
    echo ""
    total_users=$((count - 1))
    active_users=$(grep -c ":active:" "$USER_DB" 2>/dev/null || echo "0")
    print_status "Total users: $total_users | Active: $active_users"
}

# View traffic statistics
view_traffic_stats() {
    echo ""
    print_status "Traffic Statistics:"
    echo "=================="
    
    if [[ -f "$STATS_DIR/traffic-$(date +%Y-%m).log" ]]; then
        echo "Current month traffic log (last 10 entries):"
        tail -10 "$STATS_DIR/traffic-$(date +%Y-%m).log"
    else
        print_warning "No traffic data available for current month"
    fi
    
    echo ""
    if [[ -f "$USER_DB" ]]; then
        print_status "User traffic summary:"
        printf "${YELLOW}%-15s %-15s %-15s${NC}\n" "Username" "Limit (GB)" "Used (MB)"
        echo "================================================"
        
        while IFS=':' read -r username uuid email created expiry status total_limit used_traffic; do
            if [[ "$username" =~ ^#.* ]] || [[ -z "$username" ]]; then
                continue
            fi
            used_mb=$((used_traffic / 1024 / 1024))
            printf "%-15s %-15s %-15s\n" "$username" "$total_limit" "$used_mb"
        done < "$USER_DB"
    fi
}

# Menu manajemen DNS
dns_management_menu() {
    while true; do
        clear
        echo -e "${BLUE}=================================${NC}"
        echo -e "${BLUE}    MANAJEMEN DNS XRAY          ${NC}"
        echo -e "${BLUE}=================================${NC}"
        echo ""
        
        # Tampilkan status DNS saat ini
        echo -e "${GREEN}Status DNS Saat Ini:${NC}"
        /usr/local/bin/xray-dns-manager status
        echo ""
        
        echo -e "${YELLOW}Pilihan DNS Provider:${NC}"
        echo -e "${GREEN}1.${NC} Cloudflare (1.1.1.1) - Tercepat & Privacy"
        echo -e "${GREEN}2.${NC} Google (8.8.8.8) - Reliable & Fast"
        echo -e "${GREEN}3.${NC} Quad9 (9.9.9.9) - Security Focused"
        echo -e "${GREEN}4.${NC} OpenDNS (208.67.222.222) - Family Safe"
        echo -e "${GREEN}5.${NC} AdGuard (94.140.14.14) - Block Ads"
        echo -e "${GREEN}6.${NC} CleanBrowsing (76.76.19.19) - Clean Internet"
        echo -e "${GREEN}7.${NC} Comodo (8.26.56.26) - Secure DNS"
        echo -e "${GREEN}8.${NC} Level3 (4.2.2.1) - ISP Grade"
        echo ""
        echo -e "${BLUE}Opsi Lanjutan:${NC}"
        echo -e "${BLUE}9.${NC}  Auto-Pilih DNS Tercepat"
        echo -e "${BLUE}10.${NC} Tes Kecepatan DNS Custom"
        echo -e "${BLUE}11.${NC} Kembalikan DNS Asli"
        echo -e "${BLUE}12.${NC} Benchmark Semua DNS"
        echo ""
        echo -e "${RED}0.${NC} Kembali ke Menu Utama"
        echo ""
        echo -n "Pilih opsi [0-12]: "
        
        read dns_choice
        
        case $dns_choice in
            1)
                print_status "Menggunakan Cloudflare DNS..."
                /usr/local/bin/xray-dns-manager set cloudflare
                ;;
            2)
                print_status "Menggunakan Google DNS..."
                /usr/local/bin/xray-dns-manager set google
                ;;
            3)
                print_status "Menggunakan Quad9 DNS..."
                /usr/local/bin/xray-dns-manager set quad9
                ;;
            4)
                print_status "Menggunakan OpenDNS..."
                /usr/local/bin/xray-dns-manager set opendns
                ;;
            5)
                print_status "Menggunakan AdGuard DNS..."
                /usr/local/bin/xray-dns-manager set adguard
                ;;
            6)
                print_status "Menggunakan CleanBrowsing DNS..."
                /usr/local/bin/xray-dns-manager set clean
                ;;
            7)
                print_status "Menggunakan Comodo DNS..."
                /usr/local/bin/xray-dns-manager set comodo
                ;;
            8)
                print_status "Menggunakan Level3 DNS..."
                /usr/local/bin/xray-dns-manager set level3
                ;;
            9)
                print_status "Mencari DNS tercepat secara otomatis..."
                /usr/local/bin/xray-dns-manager auto
                ;;
            10)
                echo ""
                read -p "Masukkan IP DNS untuk ditest: " custom_dns
                if [[ -n "$custom_dns" ]]; then
                    /usr/local/bin/xray-dns-manager test "$custom_dns"
                else
                    print_error "IP DNS tidak boleh kosong!"
                fi
                ;;
            11)
                print_status "Mengembalikan ke DNS asli..."
                /usr/local/bin/xray-dns-manager restore
                ;;
            12)
                print_status "Melakukan benchmark semua DNS..."
                echo ""
                /usr/local/bin/xray-dns-manager auto
                ;;
            0)
                return 0
                ;;
            *)
                print_error "Opsi tidak valid!"
                ;;
        esac
        
        echo ""
        read -p "Tekan Enter untuk melanjutkan..."
    done
}

# Fungsi untuk menampilkan status BBR
show_bbr_status() {
    echo ""
    print_status "Status Optimasi BBR:"
    echo "===================="
    
    # Periksa congestion control
    local congestion_control=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
    local queue_discipline=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo "unknown")
    local tcp_fastopen=$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo "0")
    
    echo "Congestion Control: $congestion_control"
    echo "Queue Discipline: $queue_discipline"
    echo "TCP Fast Open: $tcp_fastopen"
    
    if [[ "$congestion_control" == "bbr" ]]; then
        echo -e "Status BBR: ${GREEN}✅ AKTIF${NC}"
    else
        echo -e "Status BBR: ${RED}❌ TIDAK AKTIF${NC}"
    fi
    
    echo ""
    echo "Parameter Jaringan Lainnya:"
    echo "============================"
    echo "TCP Keep Alive Time: $(sysctl -n net.ipv4.tcp_keepalive_time 2>/dev/null || echo 'default')"
    echo "TCP Slow Start After Idle: $(sysctl -n net.ipv4.tcp_slow_start_after_idle 2>/dev/null || echo 'default')"
    echo "Core RMem Max: $(sysctl -n net.core.rmem_max 2>/dev/null || echo 'default')"
    echo "Core WMem Max: $(sysctl -n net.core.wmem_max 2>/dev/null || echo 'default')"
}

# Menu manajemen SSL
ssl_management_menu() {
    while true; do
        clear
        echo -e "${BLUE}=================================${NC}"
        echo -e "${BLUE}    MANAJEMEN SSL CERTIFICATE    ${NC}"
        echo -e "${BLUE}=================================${NC}"
        echo ""
        
        # Tampilkan status SSL saat ini
        echo -e "${GREEN}Status SSL Saat Ini:${NC}"
        if [[ -f "$SSL_DIR/fullchain.pem" && -f "$SSL_DIR/privkey.pem" ]]; then
            echo "✅ SSL Certificate: TERINSTALL"
            
            # Cek informasi certificate
            local cert_info
            cert_info=$(openssl x509 -in "$SSL_DIR/fullchain.pem" -noout -subject -issuer -dates 2>/dev/null)
            
            if [[ -n "$cert_info" ]]; then
                echo "Informasi Certificate:"
                echo "$cert_info" | sed 's/^/  /'
                
                # Cek masa berlaku
                local expire_date
                expire_date=$(openssl x509 -in "$SSL_DIR/fullchain.pem" -noout -enddate 2>/dev/null | cut -d= -f2)
                if [[ -n "$expire_date" ]]; then
                    local expire_timestamp
                    expire_timestamp=$(date -d "$expire_date" +%s 2>/dev/null)
                    local current_timestamp
                    current_timestamp=$(date +%s)
                    local days_left
                    days_left=$(( (expire_timestamp - current_timestamp) / 86400 ))
                    
                    if [[ $days_left -gt 30 ]]; then
                        echo -e "  Masa Berlaku: ${GREEN}$days_left hari lagi${NC}"
                    elif [[ $days_left -gt 7 ]]; then
                        echo -e "  Masa Berlaku: ${YELLOW}$days_left hari lagi${NC}"
                    else
                        echo -e "  Masa Berlaku: ${RED}$days_left hari lagi (PERLU RENEWAL!)${NC}"
                    fi
                fi
            fi
        else
            echo "❌ SSL Certificate: TIDAK TERINSTALL"
        fi
        
        # Status Nginx
        echo ""
        echo -e "${BLUE}Status Nginx Reverse Proxy:${NC}"
        if systemctl is-active --quiet nginx; then
            echo "✅ Nginx: AKTIF"
            
            # Cek konfigurasi
            if [[ -f /etc/nginx/sites-available/xray ]]; then
                echo "✅ Konfigurasi Xray: TERINSTALL"
            else
                echo "❌ Konfigurasi Xray: TIDAK DITEMUKAN"
            fi
        else
            echo "❌ Nginx: TIDAK AKTIF"
        fi
        
        echo ""
        echo -e "${YELLOW}Pilihan SSL Management:${NC}"
        echo -e "${GREEN}1.${NC} Install SSL Certificate Baru (Let's Encrypt)"
        echo -e "${GREEN}2.${NC} Install Self-Signed Certificate"
        echo -e "${GREEN}3.${NC} Renew SSL Certificate"
        echo -e "${GREEN}4.${NC} Lihat Detail Certificate"
        echo -e "${GREEN}5.${NC} Test SSL Certificate"
        echo ""
        echo -e "${BLUE}Nginx Management:${NC}"
        echo -e "${BLUE}6.${NC}  Restart Nginx"
        echo -e "${BLUE}7.${NC}  Reload Nginx Configuration"
        echo -e "${BLUE}8.${NC}  Test Nginx Configuration"
        echo -e "${BLUE}9.${NC}  Lihat Nginx Logs"
        echo ""
        echo -e "${YELLOW}Tools:${NC}"
        echo -e "${YELLOW}10.${NC} Setup Auto-Renewal"
        echo -e "${YELLOW}11.${NC} Backup SSL Certificate"
        echo -e "${YELLOW}12.${NC} Reset SSL Configuration"
        echo ""
        echo -e "${RED}0.${NC} Kembali ke Menu Utama"
        echo ""
        echo -n "Pilih opsi [0-12]: "
        
        read ssl_choice
        
        case $ssl_choice in
            1)
                print_status "Install SSL Certificate Let's Encrypt..."
                setup_letsencrypt_ssl
                ;;
            2)
                print_status "Install Self-Signed Certificate..."
                setup_selfsigned_ssl
                ;;
            3)
                print_status "Renewing SSL Certificate..."
                if [[ -x /usr/local/bin/xray-ssl-renew ]]; then
                    /usr/local/bin/xray-ssl-renew
                else
                    print_error "Auto-renewal script tidak ditemukan"
                fi
                ;;
            4)
                print_status "Detail SSL Certificate:"
                if [[ -f "$SSL_DIR/fullchain.pem" ]]; then
                    openssl x509 -in "$SSL_DIR/fullchain.pem" -noout -text | head -30
                else
                    print_error "SSL Certificate tidak ditemukan"
                fi
                ;;
            5)
                print_status "Testing SSL Certificate..."
                if [[ -n "$DOMAIN" && "$DOMAIN" != "localhost" ]]; then
                    echo "Testing SSL untuk domain: $DOMAIN"
                    echo "" | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -dates
                else
                    print_error "Domain tidak dikonfigurasi untuk testing"
                fi
                ;;
            6)
                print_status "Restarting Nginx..."
                systemctl restart nginx
                print_status "Nginx restarted. Status: $(systemctl is-active nginx)"
                ;;
            7)
                print_status "Reloading Nginx configuration..."
                systemctl reload nginx
                print_status "Nginx configuration reloaded"
                ;;
            8)
                print_status "Testing Nginx configuration..."
                nginx -t
                ;;
            9)
                print_status "Nginx Access Logs (last 20 lines):"
                echo "================================="
                tail -20 /var/log/nginx/xray_access.log 2>/dev/null || echo "Log tidak ditemukan"
                echo ""
                print_status "Nginx Error Logs (last 10 lines):"
                echo "=============================="
                tail -10 /var/log/nginx/xray_error.log 2>/dev/null || echo "Log tidak ditemukan"
                ;;
            10)
                print_status "Setting up auto-renewal..."
                if [[ -n "$DOMAIN" && "$DOMAIN" != "localhost" ]]; then
                    setup_ssl_renewal "$DOMAIN"
                else
                    print_error "Domain diperlukan untuk auto-renewal"
                fi
                ;;
            11)
                print_status "Backup SSL Certificate..."
                backup_dir="/root/ssl-backup-$(date +%Y%m%d-%H%M%S)"
                mkdir -p "$backup_dir"
                cp -r "$SSL_DIR"/* "$backup_dir/" 2>/dev/null
                print_status "SSL backup saved to: $backup_dir"
                ;;
            12)
                print_warning "Reset SSL Configuration? Ini akan menghapus semua SSL setup! (y/N)"
                read -p "Konfirmasi: " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    rm -rf "$SSL_DIR"/*
                    rm -f /etc/nginx/sites-enabled/xray
                    systemctl reload nginx
                    print_status "SSL configuration di-reset"
                else
                    print_status "Reset dibatalkan"
                fi
                ;;
            0)
                return 0
                ;;
            *)
                print_error "Opsi tidak valid!"
                ;;
        esac
        
        echo ""
        read -p "Tekan Enter untuk melanjutkan..."
    done
}
network_speed_test() {
    echo ""
    print_status "Melakukan tes kecepatan jaringan..."
    echo ""
    
    # Tes ping ke beberapa server
    echo "Tes Ping ke Server Global:"
    echo "=========================="
    
    local servers=("8.8.8.8:Google" "1.1.1.1:Cloudflare" "208.67.222.222:OpenDNS" "114.114.114.114:China")
    
    for server_info in "${servers[@]}"; do
        local ip=$(echo "$server_info" | cut -d':' -f1)
        local name=$(echo "$server_info" | cut -d':' -f2)
        
        printf "%-12s %-15s " "$name" "$ip"
        
        local ping_result=$(ping -c 3 -W 2 "$ip" 2>/dev/null | tail -1 | awk -F '/' '{print $5}' 2>/dev/null)
        
        if [[ -n "$ping_result" ]]; then
            echo "${ping_result}ms"
        else
            echo "TIMEOUT"
        fi
    done
    
    echo ""
    echo "Tes Kecepatan Download:"
    echo "======================"
    
    # Tes download speed dengan file kecil
    local test_url="http://speedtest.ftp.otenet.gr/files/test1Mb.db"
    
    if command -v wget >/dev/null 2>&1; then
        echo "Mengunduh file test 1MB..."
        local start_time=$(date +%s)
        wget -q --timeout=10 -O /tmp/speedtest.tmp "$test_url" 2>/dev/null
        local end_time=$(date +%s)
        
        if [[ -f /tmp/speedtest.tmp ]]; then
            local file_size=$(stat -c%s /tmp/speedtest.tmp 2>/dev/null || echo "0")
            local duration=$((end_time - start_time))
            
            if [[ $duration -gt 0 && $file_size -gt 0 ]]; then
                local speed_kbps=$((file_size / duration / 1024))
                echo "Kecepatan Download: ~${speed_kbps} KB/s"
            else
                echo "Tidak dapat mengukur kecepatan download"
            fi
            
            rm -f /tmp/speedtest.tmp
        else
            echo "Gagal mengunduh file test"
        fi
    else
        echo "wget tidak tersedia untuk tes download"
    fi
    
    echo ""
    echo "Statistik Koneksi Saat Ini:"
    echo "============================"
    
    # Tampilkan koneksi aktif
    local active_connections=$(netstat -an | grep ESTABLISHED | wc -l)
    echo "Koneksi Aktif: $active_connections"
    
    # Tampilkan koneksi Xray
    local xray_connections=$(netstat -an | grep -E ':(10|20|30)[0-9]{3}' | grep ESTABLISHED | wc -l)
    echo "Koneksi Xray: $xray_connections"
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    echo "Load Average: $load_avg"
}
real_time_monitor() {
    echo ""
    print_status "Real-time System Monitor (Press Ctrl+C to exit):"
    echo "================================================"
    
    while true; do
        clear
        echo -e "${BLUE}=== XRAY SYSTEM MONITOR ===${NC}"
        echo "Time: $(date)"
        echo ""
        
        # System info
        echo -e "${GREEN}SYSTEM:${NC}"
        echo "CPU Usage: $(top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | sed 's/%us,//' || echo 'N/A')"
        echo "Memory: $(free -h | awk 'NR==2{printf "%s/%s (%.1f%%)", $3,$2,$3*100/$2 }')"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
        echo ""
        
        # Xray service status
        echo -e "${YELLOW}XRAY SERVICE:${NC}"
        echo "Status: $(systemctl is-active xray)"
        echo "Uptime: $(systemctl show xray --property=ActiveEnterTimestamp --value | xargs -I {} date -d {} +'%Y-%m-%d %H:%M:%S' 2>/dev/null || echo 'N/A')"
        echo ""
        
        # Active connections
        echo -e "${BLUE}CONNECTIONS:${NC}"
        netstat -an | grep -E ':(10|20|30)[0-9]{3}' | grep ESTABLISHED | wc -l | xargs echo "Active connections:"
        
        # Recent log entries
        echo ""
        echo -e "${RED}RECENT ACTIVITY:${NC}"
        if [[ -f "$LOG_DIR/access.log" ]]; then
            tail -3 "$LOG_DIR/access.log" 2>/dev/null || echo "No recent activity"
        fi
        
        sleep 5
    done
}

# Generate usage reports
generate_usage_report() {
    echo ""
    print_status "Generating usage report..."
    
    report_file="/root/xray-usage-report-$(date +%Y%m%d).txt"
    
    cat > "$report_file" << EOF
XRAY USAGE REPORT
=================
Generated: $(date)
Server: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

SYSTEM INFORMATION:
------------------
OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')
Xray Version: $(/usr/local/bin/xray version | head -1 2>/dev/null || echo 'Unknown')
Uptime: $(uptime -p 2>/dev/null || uptime)
Load Average: $(uptime | awk -F'load average:' '{print $2}')

USER STATISTICS:
---------------
EOF

    if [[ -f "$USER_DB" ]]; then
        echo "Total Users: $(grep -c -v '^#' "$USER_DB")" >> "$report_file"
        echo "Active Users: $(grep -c ':active:' "$USER_DB")" >> "$report_file"
        echo "Expired Users: $(grep -c ':expired:' "$USER_DB")" >> "$report_file"
        echo "" >> "$report_file"
        
        echo "USER DETAILS:" >> "$report_file"
        printf "%-15s %-12s %-12s %-10s %-10s\n" "Username" "Status" "Created" "Expiry" "Limit(GB)" >> "$report_file"
        echo "================================================================" >> "$report_file"
        
        while IFS=':' read -r username uuid email created expiry status total_limit used_traffic; do
            if [[ "$username" =~ ^#.* ]] || [[ -z "$username" ]]; then
                continue
            fi
            printf "%-15s %-12s %-12s %-10s %-10s\n" "$username" "$status" "$created" "$expiry" "$total_limit" >> "$report_file"
        done < "$USER_DB"
    fi
    
    print_status "Usage report generated: $report_file"
    echo ""
    echo "Report preview:"
    head -20 "$report_file"
}

# Show user configuration
show_user_config() {
    echo ""
    print_status "Show user configuration..."
    
    if [[ ! -f /root/xray-users.txt ]]; then
        print_error "No users file found!"
        return 1
    fi
    
    echo "Current users:"
    cat /root/xray-users.txt | cut -d: -f1 | nl
    echo ""
    
    read -p "Enter username: " username
    if [[ -z "$username" ]]; then
        print_error "Username cannot be empty!"
        return 1
    fi
    
    user_uuid=$(grep "^$username:" /root/xray-users.txt | cut -d: -f2)
    
    if [[ -z "$user_uuid" ]]; then
        print_error "User '$username' not found!"
        return 1
    fi
    
    generate_user_config "$username" "$user_uuid"
    
    if [[ -f "/root/$username-config.txt" ]]; then
        echo ""
        print_status "Configuration for user: $username"
        echo "==========================================="
        cat "/root/$username-config.txt"
        echo "==========================================="
    fi
}

# Generate user-specific configuration
generate_user_config() {
    local username="$1"
    local user_uuid="$2"
    
    # Load konfigurasi dari file
    if [[ -f /root/xray-ports.conf ]]; then
        source /root/xray-ports.conf
    else
        print_error "File konfigurasi ports tidak ditemukan!"
        return 1
    fi
    
    # Tentukan server address
    local server_addr
    if [[ "$USE_SSL" == "true" && -n "$DOMAIN" && "$DOMAIN" != "localhost" ]]; then
        server_addr="$DOMAIN"
    else
        server_addr=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    fi
    
    # Tentukan port dan security
    local web_port
    local security_type
    local tls_setting
    
    if [[ "$USE_SSL" == "true" ]]; then
        web_port="443"
        security_type="tls"
        tls_setting="\"tls\":\"tls\""
    else
        web_port="80"
        security_type="none"
        tls_setting="\"tls\":\"\""
    fi
    
    # Generate connection links untuk user
    local vmess_link
    local vless_link
    local trojan_link
    
    if [[ "$SSL_TYPE" == "selfsigned" ]]; then
        # Self-signed certificate - allow insecure
        vmess_link=$(echo -n "{\"v\":\"2\",\"ps\":\"$username-VMess\",\"add\":\"$server_addr\",\"port\":\"$web_port\",\"id\":\"$user_uuid\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$server_addr\",\"path\":\"/vmessws\",$tls_setting,\"allowInsecure\":true}" | base64 -w 0)
        vless_link="vless://$user_uuid@$server_addr:$web_port?encryption=none&security=$security_type&type=ws&host=$server_addr&path=%2Fvlessws&allowInsecure=1#$username-VLESS"
        trojan_link="trojan://$user_uuid@$server_addr:$web_port?security=$security_type&type=ws&host=$server_addr&path=%2Ftrojanws&allowInsecure=1#$username-Trojan"
    else
        # Valid certificate atau tanpa SSL
        vmess_link=$(echo -n "{\"v\":\"2\",\"ps\":\"$username-VMess\",\"add\":\"$server_addr\",\"port\":\"$web_port\",\"id\":\"$user_uuid\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$server_addr\",\"path\":\"/vmessws\",$tls_setting}" | base64 -w 0)
        vless_link="vless://$user_uuid@$server_addr:$web_port?encryption=none&security=$security_type&type=ws&host=$server_addr&path=%2Fvlessws#$username-VLESS"
        trojan_link="trojan://$user_uuid@$server_addr:$web_port?security=$security_type&type=ws&host=$server_addr&path=%2Ftrojanws#$username-Trojan"
    fi
    
    # Buat file konfigurasi untuk user
    cat > "/root/$username-config.txt" << EOF
KONFIGURASI XRAY UNTUK USER: $username
=====================================

Informasi Server:
Server: $server_addr
SSL Status: $([[ "$USE_SSL" == "true" ]] && echo "AKTIF" || echo "TIDAK AKTIF")
SSL Type: $([[ -n "$SSL_TYPE" ]] && echo "$SSL_TYPE" || echo "none")
Tanggal Dibuat: $(date)

VMess Configuration (WebSocket):
Server: $server_addr
Port: $web_port
UUID: $user_uuid
AlterID: 0
Security: auto
Network: ws
Path: /vmessws
TLS: $security_type
$([[ "$SSL_TYPE" == "selfsigned" ]] && echo "Allow Insecure: true")

VLESS Configuration (WebSocket):
Server: $server_addr
Port: $web_port
UUID: $user_uuid
Encryption: none
Network: ws
Path: /vlessws
TLS: $security_type
$([[ "$SSL_TYPE" == "selfsigned" ]] && echo "Allow Insecure: true")

Trojan Configuration (WebSocket):
Server: $server_addr
Port: $web_port
Password: $user_uuid
Network: ws
Path: /trojanws
TLS: $security_type
$([[ "$SSL_TYPE" == "selfsigned" ]] && echo "Allow Insecure: true")

Link Koneksi:
VMess: vmess://$vmess_link
VLESS: $vless_link
Trojan: $trojan_link

QR Code Links (simpan untuk aplikasi mobile):
vmess://$vmess_link
vless://$vless_link
trojan://$trojan_link

Catatan:
- Semua protocol menggunakan WebSocket untuk bypass firewall
- Path WebSocket: /vmessws, /vlessws, /trojanws
- Host header harus diset ke: $server_addr
$([[ "$USE_SSL" == "true" ]] && echo "- Koneksi dienkripsi dengan SSL/TLS")
$([[ "$SSL_TYPE" == "selfsigned" ]] && echo "- Perlu aktifkan 'Allow Insecure' di client")
EOF
    
    print_status "Konfigurasi user '$username' tersimpan di /root/$username-config.txt"
    
    # Tampilkan informasi singkat
    echo ""
    echo -e "${GREEN}Konfigurasi untuk user: $username${NC}"
    echo "UUID: $user_uuid"
    echo "Server: $server_addr:$web_port"
    echo "TLS: $security_type"
    echo ""
    echo "Link VMess: vmess://$vmess_link"
    echo "Link VLESS: $vless_link"
    echo "Link Trojan: $trojan_link"
    echo ""
}

# View service status
view_status() {
    echo ""
    print_status "Xray Service Status:"
    echo "====================="
    systemctl status xray --no-pager
    echo ""
    print_status "Service is: $(systemctl is-active xray)"
    print_status "Auto-start: $(systemctl is-enabled xray 2>/dev/null || echo 'unknown')"
}

# View service logs
view_logs() {
    echo ""
    print_status "Recent Xray logs:"
    echo "=================="
    journalctl -u xray --no-pager -n 50
    echo ""
    print_status "Access log:"
    if [[ -f /var/log/xray/access.log ]]; then
        tail -20 /var/log/xray/access.log
    else
        print_warning "Access log not found"
    fi
    echo ""
    print_status "Error log:"
    if [[ -f /var/log/xray/error.log ]]; then
        tail -20 /var/log/xray/error.log
    else
        print_warning "Error log not found"
    fi
}

# Update Xray
update_xray() {
    echo ""
    print_status "Updating Xray..."
    
    # Stop service
    systemctl stop xray
    
    # Download and install latest version
    wget -O xray-install.sh https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh
    chmod +x xray-install.sh
    ./xray-install.sh
    rm -f xray-install.sh
    
    # Start service
    systemctl start xray
    
    print_status "Xray updated successfully!"
    print_status "Current version: $(/usr/local/bin/xray version | head -1)"
}

# Show system information
show_system_info() {
    echo ""
    print_status "System Information:"
    echo "===================="
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "CPU: $(nproc) cores"
    echo "Memory: $(free -h | awk 'NR==2{printf \"%s/%s (%.1f%%)\\n\", $3,$2,$3*100/$2 }')"
    echo "Disk: $(df -h / | awk 'NR==2{printf \"%s/%s (%s)\\n\", $3,$2,$5}')"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime | cut -d',' -f1 | sed 's/.*up //')"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    print_status "Network Information:"
    echo "===================="
    echo "External IP: $(curl -s ifconfig.me 2>/dev/null || echo 'Unable to detect')"
    echo "Internal IP: $(hostname -I | awk '{print $1}')"
    echo ""
    if [[ -f /usr/local/bin/xray ]]; then
        print_status "Xray Information:"
        echo "================="
        echo "Version: $(/usr/local/bin/xray version | head -1)"
        echo "Config: /usr/local/etc/xray/config.json"
        echo "Status: $(systemctl is-active xray)"
        echo "Users: $(wc -l < /root/xray-users.txt 2>/dev/null || echo '0')"
    fi
}

# Backup configuration
backup_config() {
    echo ""
    print_status "Creating backup..."
    
    backup_dir="/root/xray-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup config files
    cp -r /usr/local/etc/xray/ "$backup_dir/"
    cp /root/xray-users.txt "$backup_dir/" 2>/dev/null || true
    cp /root/*-config.txt "$backup_dir/" 2>/dev/null || true
    
    # Create backup info
    cat > "$backup_dir/backup-info.txt" << EOF
Xray Backup Information
======================
Date: $(date)
Xray Version: $(/usr/local/bin/xray version | head -1 2>/dev/null || echo 'Unknown')
Users Count: $(wc -l < /root/xray-users.txt 2>/dev/null || echo '0')
Backup Location: $backup_dir
EOF
    
    # Create tar archive
    tar -czf "$backup_dir.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    print_status "Backup created: $backup_dir.tar.gz"
}

# Restore configuration
restore_config() {
    echo ""
    print_status "Available backups:"
    echo "=================="
    
    backup_files=($(ls /root/xray-backup-*.tar.gz 2>/dev/null))
    
    if [[ ${#backup_files[@]} -eq 0 ]]; then
        print_error "No backup files found!"
        return 1
    fi
    
    for i in "${!backup_files[@]}"; do
        echo "$((i+1)). $(basename "${backup_files[$i]}")"
    done
    
    echo ""
    read -p "Select backup file number: " choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#backup_files[@]} ]]; then
        print_error "Invalid selection!"
        return 1
    fi
    
    selected_backup="${backup_files[$((choice-1))]}"
    
    print_warning "This will replace current configuration. Continue? (y/N)"
    read -p "Confirm: " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_status "Restore cancelled."
        return 0
    fi
    
    # Stop service
    systemctl stop xray
    
    # Extract backup
    temp_dir="/tmp/xray-restore-$(date +%s)"
    mkdir -p "$temp_dir"
    tar -xzf "$selected_backup" -C "$temp_dir"
    
    # Restore files
    backup_folder=$(ls "$temp_dir")
    cp -r "$temp_dir/$backup_folder/xray/"* /usr/local/etc/xray/
    cp "$temp_dir/$backup_folder/xray-users.txt" /root/ 2>/dev/null || true
    cp "$temp_dir/$backup_folder/"*-config.txt /root/ 2>/dev/null || true
    
    # Clean up
    rm -rf "$temp_dir"
    
    # Start service
    systemctl start xray
    
    print_status "Configuration restored successfully!"
    print_status "Service status: $(systemctl is-active xray)"
}

# Loop menu manajemen
management_menu() {
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                add_user
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            2)
                delete_user
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            3)
                list_users
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            4)
                show_user_config
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            5)
                echo ""
                print_status "Edit Pengaturan User - Fitur segera hadir!"
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            6)
                view_traffic_stats
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            7)
                real_time_monitor
                ;;
            8)
                generate_usage_report
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            9)
                view_status
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            10)
                view_logs
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            11)
                print_status "Merestart service Xray..."
                systemctl restart xray
                print_status "Service direstart. Status: $(systemctl is-active xray)"
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            12)
                echo ""
                echo "Kontrol Service:"
                echo "1. Stop Service"
                echo "2. Start Service"
                read -p "Pilih [1-2]: " service_choice
                case $service_choice in
                    1)
                        print_status "Menghentikan service Xray..."
                        systemctl stop xray
                        print_status "Service dihentikan. Status: $(systemctl is-active xray)"
                        ;;
                    2)
                        print_status "Memulai service Xray..."
                        systemctl start xray
                        print_status "Service dimulai. Status: $(systemctl is-active xray)"
                        ;;
                    *)
                        print_error "Opsi tidak valid!"
                        ;;
                esac
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            13)
                update_xray
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            14)
                ssl_management_menu
                ;;
            15)
                echo ""
                print_status "Status Nginx Reverse Proxy:"
                echo "============================"
                echo "Status Service: $(systemctl is-active nginx)"
                echo "Auto-start: $(systemctl is-enabled nginx 2>/dev/null || echo 'unknown')"
                echo "Konfigurasi: $([[ -f /etc/nginx/sites-available/xray ]] && echo 'AKTIF' || echo 'TIDAK AKTIF')"
                echo "Port Listen: 80, 443"
                if [[ -f /var/log/nginx/xray_access.log ]]; then
                    echo "Total Request Hari Ini: $(grep "$(date +'%d/%b/%Y')" /var/log/nginx/xray_access.log 2>/dev/null | wc -l)"
                fi
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            16)
                print_status "Konfigurasi Ulang SSL..."
                setup_ssl_and_reverse_proxy
                print_status "Konfigurasi SSL selesai!"
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            17)
                dns_management_menu
                ;;
            18)
                show_bbr_status
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            19)
                network_speed_test
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            20)
                echo ""
                print_status "Konfigurasi Protocol:"
                echo "Protocol yang aktif saat ini:"
                python3 -c "import json,sys; config=json.load(open(sys.argv[1])); [print(f'- {i[\"protocol\"].upper()}: Port {i[\"port\"]}') for i in config['inbounds'] if i.get('protocol') not in ['dokodemo-door']]" "$CONFIG_DIR/config.json"
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            21)
                echo ""
                print_status "Audit Keamanan Lengkap:"
                echo "Memeriksa status keamanan sistem..."
                echo "- Xray service: $(systemctl is-active xray)"
                echo "- Nginx service: $(systemctl is-active nginx)"
                echo "- SSL Certificate: $([[ -f "$SSL_DIR/fullchain.pem" ]] && echo 'TERINSTALL' || echo 'TIDAK ADA')"
                echo "- Izin file config: $(ls -la $CONFIG_DIR/config.json | awk '{print $1}')"
                echo "- Direktori log: $(ls -ld $LOG_DIR | awk '{print $1}')"
                echo "- Port backend: $(netstat -tuln | grep -E '127.0.0.1:(10|20|30)[0-9]{3}' | wc -l) aktif (internal)"
                echo "- Port frontend: $(netstat -tuln | grep -E ':443|:80' | wc -l) aktif (public)"
                echo "- Status BBR: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'unknown')"
                echo "- DNS saat ini: $(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}' 2>/dev/null || echo 'default')"
                echo "- Firewall status: $([[ -x "$(command -v ufw)" ]] && ufw status | head -1 || echo 'tidak terdeteksi')"
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            22)
                backup_config
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            23)
                restore_config
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            24)
                echo ""
                print_status "Pembersihan Sistem Lengkap:"
                echo "Membersihkan file temporary dan log..."
                find /tmp -name "xray*" -type f -delete 2>/dev/null
                find "$LOG_DIR" -name "*.log" -size +100M -delete 2>/dev/null
                # Bersihkan log DNS test
                find /tmp -name "dns_test*" -type f -delete 2>/dev/null
                # Bersihkan log nginx yang besar
                find /var/log/nginx -name "*.log" -size +100M -exec truncate -s 0 {} \; 2>/dev/null
                # Bersihkan cache SSL temporary
                find /tmp -name "ssl_*" -type f -delete 2>/dev/null
                # Bersihkan cache DNS
                if command -v systemd-resolve >/dev/null 2>&1; then
                    systemd-resolve --flush-caches 2>/dev/null
                fi
                # Restart log rotation
                logrotate -f /etc/logrotate.conf 2>/dev/null || true
                print_status "Pembersihan sistem selesai!"
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            0)
                print_status "Selamat tinggal!"
                exit 0
                ;;
            *)
                print_error "Opsi tidak valid! Silakan coba lagi."
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
        esac
    done
}

# Periksa apakah ini pertama kali dijalankan atau mode manajemen
if [[ "$1" == "--manage" || "$1" == "-m" ]]; then
    management_menu
elif [[ -f /usr/local/bin/xray && -f "$CONFIG_DIR/config.json" ]]; then
    echo ""
    print_status "Xray sudah terinstall!"
    echo ""
    echo "Pilihan:"
    echo "1. Jalankan panel manajemen"
    echo "2. Install ulang Xray (dengan konfigurasi domain baru)"
    echo "3. Buat/Update perintah menu"
    echo "4. Optimasi BBR & DNS saja"
    echo "5. Setup SSL untuk instalasi yang sudah ada"
    echo "6. Keluar"
    echo ""
    read -p "Pilih opsi [1-6]: " option
    
    case $option in
        1)
            management_menu
            ;;
        2)
            print_warning "Ini akan menginstall ulang Xray dengan konfigurasi baru."
            print_warning "Semua konfigurasi dan user yang ada akan hilang!"
            read -p "Lanjutkan? (y/N): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                # Backup konfigurasi lama
                backup_dir="/root/xray-backup-before-reinstall-$(date +%Y%m%d-%H%M%S)"
                mkdir -p "$backup_dir"
                cp -r "$CONFIG_DIR" "$backup_dir/" 2>/dev/null || true
                cp "$USER_DB" "$backup_dir/" 2>/dev/null || true
                print_status "Backup disimpan di: $backup_dir"
                
                main
            else
                print_status "Instalasi ulang dibatalkan."
                exit 0
            fi
            ;;
        3)
            create_menu_command
            echo ""
            print_status "Perintah menu berhasil dibuat/diperbarui!"
            print_status "Anda sekarang bisa menjalankan 'sudo menu' dari mana saja."
            read -p "Tekan Enter untuk melanjutkan..."
            ;;
        4)
            print_status "Menjalankan optimasi BBR & DNS..."
            setup_bbr_optimization
            setup_dns_management
            print_status "Optimasi selesai!"
            read -p "Tekan Enter untuk melanjutkan..."
            ;;
        5)
            print_status "Setup SSL untuk instalasi yang sudah ada..."
            echo ""
            print_warning "Ini akan menambahkan SSL ke instalasi Xray yang sudah ada."
            read -p "Lanjutkan? (y/N): " confirm_ssl
            if [[ "$confirm_ssl" == "y" || "$confirm_ssl" == "Y" ]]; then
                # Load konfigurasi yang ada
                config_file="$CONFIG_DIR/config.json"
                VMESS_PORT=$(python3 -c "import json; config=json.load(open('$config_file')); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vmess'][0])" 2>/dev/null || echo "10001")
                VLESS_PORT=$(python3 -c "import json; config=json.load(open('$config_file')); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='vless'][0])" 2>/dev/null || echo "20001")
                TROJAN_PORT=$(python3 -c "import json; config=json.load(open('$config_file')); print([i['port'] for i in config['inbounds'] if i.get('protocol')=='trojan'][0])" 2>/dev/null || echo "30001")
                
                setup_domain_and_ssl_choice
                setup_ssl_and_reverse_proxy
                
                # Update konfigurasi Xray untuk menggunakan SSL
                create_config
                systemctl restart xray
                
                print_status "SSL berhasil ditambahkan ke instalasi yang ada!"
            else
                print_status "Setup SSL dibatalkan."
            fi
            read -p "Tekan Enter untuk melanjutkan..."
            ;;
        6)
            exit 0
            ;;
        *)
            print_error "Opsi tidak valid!"
            exit 1
            ;;
    esac
else
    main
fi
