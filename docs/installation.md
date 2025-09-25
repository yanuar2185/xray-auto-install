# Installation Guide

This guide provides detailed instructions for installing and configuring the Xray Auto Install Script.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Installation](#quick-installation)
3. [Custom Installation](#custom-installation)
4. [Post-Installation Configuration](#post-installation-configuration)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Ubuntu 20.04+, Debian 10+, CentOS 7+, Rocky Linux 8+
- **Memory**: Minimum 512MB RAM (1GB+ recommended)
- **Storage**: At least 1GB free space
- **Network**: Public IP address with internet connectivity
- **Root Access**: Script must be run as root user

### Port Requirements

The script will use the following ports:
- **80**: HTTP (for SSL certificate validation)
- **443**: HTTPS (main proxy port)
- **Custom ports**: For direct Xray connections (auto-assigned)

Ensure these ports are not blocked by your firewall or hosting provider.

### Domain Requirements (Recommended)

For production use, you'll need:
- A registered domain name
- DNS access to create A records
- Domain pointing to your server's IP address

## Quick Installation

### One-Line Installation

```bash
# Download and run the script
curl -sL https://raw.githubusercontent.com/your-username/xray-auto-install/main/xray-auto-install.sh -o xray-auto-install.sh && chmod +x xray-auto-install.sh && ./xray-auto-install.sh
```

### Step-by-Step Installation

1. **Update your system**:
   ```bash
   # Ubuntu/Debian
   apt update && apt upgrade -y
   
   # CentOS/Rocky Linux
   yum update -y
   ```

2. **Download the script**:
   ```bash
   wget https://raw.githubusercontent.com/your-username/xray-auto-install/main/xray-auto-install.sh
   chmod +x xray-auto-install.sh
   ```

3. **Run the installation**:
   ```bash
   ./xray-auto-install.sh
   ```

4. **Follow the interactive prompts**:
   - Enter your domain name (or use IP for testing)
   - Choose SSL method (Let's Encrypt recommended)
   - Select protocols to enable
   - Configure additional options

## Custom Installation

### Environment Variables

You can pre-configure the installation using environment variables:

```bash
export XRAY_DOMAIN="your-domain.com"
export SSL_METHOD="letsencrypt"
export ENABLE_BBR="true"
export PROTOCOLS="vmess,vless,trojan"
./xray-auto-install.sh --auto
```

### Available Environment Variables

| Variable | Description | Default | Options |
|----------|-------------|---------|---------|
| `XRAY_DOMAIN` | Domain name for the server | Server IP | Any valid domain |
| `SSL_METHOD` | SSL certificate method | `letsencrypt` | `letsencrypt`, `selfsigned` |
| `ENABLE_BBR` | Enable BBR optimization | `true` | `true`, `false` |
| `PROTOCOLS` | Protocols to enable | `vmess,vless,trojan` | Comma-separated list |
| `AUTO_CREATE_USER` | Auto-create first user | `true` | `true`, `false` |
| `DEFAULT_USER` | Default username | `user001` | Any string |

### Silent Installation

For automated deployments:

```bash
./xray-auto-install.sh --silent \
  --domain=your-domain.com \
  --ssl=letsencrypt \
  --protocols=vmess,vless,trojan \
  --bbr=true
```

## Post-Installation Configuration

### Accessing the Management Menu

After installation, you can access the management interface:

```bash
menu
```

This command is available globally and provides access to all management functions.

### Initial User Creation

If you didn't auto-create a user during installation:

1. Run `menu`
2. Select option `1` (Create User)
3. Enter username and expiry date
4. Copy the generated configuration

### SSL Certificate Management

#### Let's Encrypt Certificates

Certificates are automatically renewed. To manually renew:

```bash
menu
# Select SSL management options
```

#### Custom Certificates

To use your own certificates:

1. Place certificate files in `/etc/xray-ssl/`
2. Update configuration via menu
3. Restart services

### Firewall Configuration

The script automatically configures firewall rules, but you may need to adjust them:

```bash
# Check current rules
ufw status

# Add custom rules if needed
ufw allow 8080/tcp
ufw reload
```

## Verification

### Check Service Status

```bash
# Check Xray service
systemctl status xray

# Check Nginx service
systemctl status nginx

# Check all processes
menu
# Select option for system status
```

### Test Connections

1. **Create a test user**:
   ```bash
   menu
   # Select create user option
   ```

2. **Download client configuration**

3. **Test connection with Xray client**

### View Logs

```bash
# Xray logs
tail -f /var/log/xray/error.log

# Nginx logs
tail -f /var/log/nginx/error.log

# Installation logs
tail -f /var/log/xray-install.log
```

## Advanced Configuration

### Custom Port Configuration

To use custom ports:

1. Edit `/root/xray-ports.conf`
2. Restart services via menu
3. Update client configurations

### DNS Configuration

The script supports multiple DNS providers:

```bash
menu
# Select DNS management
# Choose provider: Cloudflare, Google, Quad9
```

### Traffic Monitoring

Enable detailed traffic monitoring:

```bash
menu
# Select monitoring options
# Configure alerts and limits
```

### Backup Configuration

Create automatic backups:

```bash
menu
# Select backup/restore options
# Configure backup schedule
```

## Multiple Server Setup

### Load Balancing

For multiple servers:

1. Install script on each server
2. Use same domain with different subdomains
3. Configure load balancer (HAProxy/Nginx)

### Centralized Management

Set up centralized user management:

1. Configure shared database
2. Sync user configurations
3. Monitor all servers from central dashboard

## Performance Optimization

### BBR Optimization

BBR is enabled by default. To verify:

```bash
sysctl net.ipv4.tcp_congestion_control
# Should show: bbr
```

### System Tuning

Additional optimizations:

```bash
# Increase file limits
echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 65535" >> /etc/security/limits.conf

# Optimize kernel parameters
echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf
sysctl -p
```

## Security Hardening

### Additional Security Measures

1. **Change SSH port**:
   ```bash
   nano /etc/ssh/sshd_config
   # Change Port 22 to custom port
   systemctl restart ssh
   ```

2. **Configure fail2ban**:
   ```bash
   apt install fail2ban -y
   systemctl enable fail2ban
   ```

3. **Regular updates**:
   ```bash
   # Add to crontab
   0 2 * * * apt update && apt upgrade -y
   ```

## Troubleshooting

### Common Issues

1. **SSL certificate issues**: Check DNS propagation
2. **Port conflicts**: Verify no other services using ports
3. **Firewall blocks**: Ensure ports 80/443 are open
4. **Memory issues**: Increase server memory

### Getting Help

- Check the [Troubleshooting Guide](troubleshooting.md)
- Review server logs
- Contact support with system information

### Uninstallation

To completely remove the installation:

```bash
menu
# Select uninstall option
# Confirm removal
```

Or manually:

```bash
systemctl stop xray nginx
systemctl disable xray nginx
rm -rf /usr/local/etc/xray /var/log/xray /etc/nginx/sites-available/xray*
userdel -r xray 2>/dev/null
```

---

**Next Steps**: After installation, see the [User Guide](user-guide.md) for detailed usage instructions.
