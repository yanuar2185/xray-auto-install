# 🚀 Xray Auto-Install Script - Advanced Edition

[![Version](https://img.shields.io/badge/version-2.0-blue.svg)](https://github.com/yourusername/xray-auto-install)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![OS](https://img.shields.io/badge/os-Ubuntu%20%7C%20Debian%20%7C%20CentOS-lightgrey.svg)](#supported-operating-systems)
[![SSL](https://img.shields.io/badge/ssl-Let's%20Encrypt%20%7C%20Self--Signed-orange.svg)](#ssl-configuration)

Script otomatis untuk instalasi dan manajemen Xray proxy server dengan fitur enterprise-grade. Mendukung multiple protokol, SSL/TLS encryption, reverse proxy, dan sistem manajemen user yang lengkap.

## ✨ Fitur Utama

### 🔐 **Keamanan & SSL**
- **Let's Encrypt SSL** - Certificate otomatis dengan auto-renewal
- **Self-Signed SSL** - Fallback untuk penggunaan tanpa domain
- **Nginx Reverse Proxy** - Sembunyikan server backend
- **Website Camouflage** - Menyamar sebagai website biasa
- **Security Headers** - HSTS, XSS Protection, dll

### 🌐 **Multi-Protocol Support**
- **VMess** dengan WebSocket + TLS
- **VLESS** dengan WebSocket + TLS
- **Trojan** dengan WebSocket + TLS
- **Multiple Inbound** dalam satu server

### 👥 **User Management**
- **Add/Delete Users** dengan UUID unik
- **User Expiry** - Set masa berlaku akun
- **Traffic Limits** - Batas penggunaan per user
- **User Statistics** - Monitor penggunaan traffic
- **Bulk Operations** - Operasi multiple user

### 📊 **Monitoring & Analytics**
- **Real-time Statistics** - Monitor koneksi live
- **Traffic Analytics** - Analisis penggunaan bandwidth
- **Usage Reports** - Laporan penggunaan berkala
- **System Performance** - Monitor server resources

### ⚡ **Network Optimization**
- **BBR Congestion Control** - Optimasi TCP untuk speed
- **Smart DNS Management** - Auto-select DNS tercepat
- **Network Speed Test** - Tes performa koneksi
- **Automatic Tuning** - Optimasi parameter jaringan

### 🛠️ **Management Interface**
- **Interactive Menu** - Interface berbasis CLI yang mudah
- **Global Menu Command** - Akses `sudo menu` dari mana saja
- **Web-based Dashboard** (Coming Soon)
- **API Management** - RESTful API untuk integrasi

## 🚀 Quick Start

### Instalasi Otomatis
```bash
# Download script
wget -O xray-auto-install.sh https://raw.githubusercontent.com/yanuar2185/xray-auto-install/main/xray-auto-install.sh

# Buat executable
chmod +x xray-auto-install.sh

# Jalankan instalasi
sudo ./xray-auto-install.sh
```

### Konfigurasi Domain (Opsional tapi Direkomendasikan)
1. **Siapkan Domain**: Beli domain atau gunakan subdomain
2. **Setup DNS Record**: Buat A record yang mengarah ke IP server
3. **Verifikasi DNS**: `ping yourdomain.com` harus mengarah ke server
4. **Jalankan Script**: Pilih opsi "Let's Encrypt SSL" saat instalasi

## 📋 Panduan Instalasi Lengkap

### Persyaratan Sistem
- **OS**: Ubuntu 18.04+, Debian 9+, CentOS 7+
- **RAM**: Minimal 512MB (Rekomendasi: 1GB+)
- **Storage**: Minimal 1GB free space
- **Network**: Port 80, 443 terbuka untuk SSL
- **Root Access**: Script harus dijalankan sebagai root

### Langkah-langkah Detail

#### 1. Persiapan Server
```bash
# Update sistem
sudo apt update && sudo apt upgrade -y

# Install dependencies dasar
sudo apt install curl wget unzip -y
```

#### 2. Download dan Instalasi
```bash
# Method 1: Direct download
curl -O https://raw.githubusercontent.com/yourusername/xray-auto-install/main/xray-auto-install.sh

# Method 2: Clone repository
git clone https://github.com/yourusername/xray-auto-install.git
cd xray-auto-install

# Buat executable
chmod +x xray-auto-install.sh

# Jalankan instalasi
sudo ./xray-auto-install.sh
```

#### 3. Konfigurasi SSL
Script akan menanyakan pilihan SSL:

**Opsi 1: Let's Encrypt (Direkomendasikan)**
- Masukkan domain yang sudah mengarah ke server
- Masukkan email untuk notifikasi renewal
- Certificate akan otomatis diperbaharui

**Opsi 2: Self-Signed**
- Menggunakan IP server langsung
- Client perlu setting "Allow Insecure"
- Cocok untuk testing atau penggunaan internal

**Opsi 3: HTTP Only**
- Tanpa encryption (tidak direkomendasikan)
- Hanya untuk testing atau environment khusus

## 🎮 Penggunaan

### Menu Manajemen
Setelah instalasi, akses panel manajemen dengan:
```bash
sudo menu
```

### Fitur Menu Utama
```
📊 USER MANAGEMENT:
1.  Tambah User Baru (dengan expiry & limits)
2.  Hapus User
3.  Lihat Semua User (dengan statistik)
4.  Tampilkan Konfigurasi User
5.  Edit Pengaturan User

📈 MONITORING & STATISTIK:
6.  Lihat Statistik Traffic
7.  Monitor Sistem Real-time
8.  Generate Laporan Penggunaan

⚙️  SERVICE MANAGEMENT:
9.  Lihat Status Service
10. Lihat Log Service
11. Restart Xray Service
12. Stop/Start Xray Service
13. Update Xray

🔒 SSL & REVERSE PROXY:
14. Manajemen SSL Certificate
15. Status Nginx Reverse Proxy
16. Konfigurasi Ulang SSL

🌐 OPTIMASI JARINGAN:
17. Manajemen DNS
18. Status Optimasi BBR
19. Tes Kecepatan Jaringan

🔧 FITUR CANGGIH:
20. Konfigurasi Protocol
21. Audit Keamanan
22. Backup Konfigurasi
23. Restore Konfigurasi
24. Pembersihan Sistem
```

### Command Line Tools

#### DNS Management
```bash
# Auto-select DNS tercepat
xray-dns-manager auto

# Set DNS provider
xray-dns-manager set cloudflare

# Test DNS speed
xray-dns-manager test 1.1.1.1

# Lihat status DNS
xray-dns-manager status
```

#### SSL Management
```bash
# Renew SSL certificate
/usr/local/bin/xray-ssl-renew

# Check SSL status
openssl x509 -in /etc/xray-ssl/fullchain.pem -noout -dates
```

## 🔧 Konfigurasi Lanjutan

### Structure File
```
/usr/local/etc/xray/
├── config.json              # Konfigurasi utama Xray
/var/log/xray/
├── access.log               # Log akses
├── error.log                # Log error
/root/
├── xray-users.db            # Database user
├── xray-ports.conf          # Konfigurasi ports
├── xray-ssl-config.txt      # Konfigurasi client utama
├── username-config.txt      # Konfigurasi per user
/etc/xray-ssl/
├── fullchain.pem            # SSL certificate
├── privkey.pem              # SSL private key
/var/xray-stats/
├── traffic-YYYY-MM.log      # Traffic log bulanan
/etc/nginx/sites-available/
├── xray                     # Konfigurasi Nginx reverse proxy
```

### Port Configuration
```bash
# Backend ports (internal)
VMess:  127.0.0.1:10xxx-19xxx
VLESS:  127.0.0.1:20xxx-29xxx
Trojan: 127.0.0.1:30xxx-39xxx
Stats:  127.0.0.1:8xxx

# Frontend ports (public)
HTTP:   80   → Redirect ke HTTPS
HTTPS:  443  → Reverse proxy ke backend
```

### WebSocket Paths
```
VMess:  /vmessws
VLESS:  /vlessws
Trojan: /trojanws
```

## 📱 Client Configuration

### Supported Clients
- **Android**: V2rayNG, Clash for Android
- **iOS**: Shadowrocket, Quantumult X
- **Windows**: V2rayN, Clash for Windows
- **macOS**: ClashX, V2rayU
- **Linux**: V2ray core, Clash

### Connection Examples

#### VMess Configuration
```json
{
  "server": "yourdomain.com",
  "port": 443,
  "uuid": "user-uuid-here",
  "alterId": 0,
  "security": "auto",
  "network": "ws",
  "path": "/vmessws",
  "tls": "tls"
}
```

#### VLESS Configuration
```
vless://uuid@yourdomain.com:443?encryption=none&security=tls&type=ws&path=%2Fvlessws#Your-VLESS
```

#### Trojan Configuration
```
trojan://uuid@yourdomain.com:443?security=tls&type=ws&path=%2Ftrojanws#Your-Trojan
```

## 🔍 Troubleshooting

### Common Issues

#### 1. SSL Certificate Failed
```bash
# Check domain DNS
dig +short yourdomain.com

# Check ports
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Manual certificate request
sudo certbot certonly --standalone -d yourdomain.com
```

#### 2. Connection Failed
```bash
# Check Xray service
sudo systemctl status xray

# Check Nginx service
sudo systemctl status nginx

# Check configuration
sudo nginx -t
sudo /usr/local/bin/xray test -config /usr/local/etc/xray/config.json
```

#### 3. User Cannot Connect
```bash
# Check user exists in config
sudo cat /usr/local/etc/xray/config.json | grep "user-uuid"

# Regenerate user config
sudo menu
# Pilih: 4. Tampilkan Konfigurasi User
```

### Log Analysis
```bash
# Xray logs
sudo journalctl -u xray -f

# Nginx logs
sudo tail -f /var/log/nginx/xray_access.log
sudo tail -f /var/log/nginx/xray_error.log

# System logs
sudo dmesg | tail
```

### Performance Tuning
```bash
# Check BBR status
sysctl net.ipv4.tcp_congestion_control

# Check network performance
sudo menu
# Pilih: 19. Tes Kecepatan Jaringan

# Optimize DNS
xray-dns-manager auto
```

## 🔄 Update & Maintenance

### Update Script
```bash
# Update Xray core
sudo menu
# Pilih: 13. Update Xray

# Update script
wget -O xray-auto-install-new.sh https://raw.githubusercontent.com/yourusername/xray-auto-install/main/xray-auto-install.sh
chmod +x xray-auto-install-new.sh
sudo ./xray-auto-install-new.sh
# Pilih: 2. Install ulang Xray
```

### Backup & Restore
```bash
# Create backup
sudo menu
# Pilih: 22. Backup Konfigurasi

# Restore backup
sudo menu
# Pilih: 23. Restore Konfigurasi
```

### System Maintenance
```bash
# Clean system
sudo menu
# Pilih: 24. Pembersihan Sistem

# Check system health
sudo menu
# Pilih: 21. Audit Keamanan
```

## 🤝 Contributing

Kami menyambut kontribusi dari komunitas! Silakan baca [CONTRIBUTING.md](CONTRIBUTING.md) untuk panduan kontribusi.

### Development Setup
```bash
# Clone repository
git clone https://github.com/yourusername/xray-auto-install.git
cd xray-auto-install

# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and test
# ...

# Submit pull request
```

## 📄 License

Script ini dilisensikan di bawah [MIT License](LICENSE). Lihat file LICENSE untuk detail lengkap.

## 🙏 Acknowledgments

- **Xray-core Team** - Core Xray proxy software
- **Let's Encrypt** - Free SSL certificates
- **Nginx** - Reverse proxy server
- **Community Contributors** - Bug reports dan improvements

## 📞 Support

### Getting Help
- **Documentation**: Baca dokumentasi lengkap di [Wiki](https://github.com/yourusername/xray-auto-install/wiki)
- **Issues**: Laporkan bug di [GitHub Issues](https://github.com/yourusername/xray-auto-install/issues)
- **Discussions**: Diskusi di [GitHub Discussions](https://github.com/yourusername/xray-auto-install/discussions)

### Commercial Support
Untuk dukungan komersial atau kustomisasi enterprise, hubungi: [support@yourdomain.com](mailto:support@yourdomain.com)

---

**⭐ Jika script ini membantu Anda, silakan berikan star di repository ini!**


**🔄 Stay updated dengan follow repository ini untuk mendapat notifikasi update terbaru.**
