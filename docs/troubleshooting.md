# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the Xray Auto Install Script.

## Table of Contents

1. [General Troubleshooting Steps](#general-troubleshooting-steps)
2. [Installation Issues](#installation-issues)
3. [SSL Certificate Problems](#ssl-certificate-problems)
4. [Connection Issues](#connection-issues)
5. [User Management Problems](#user-management-problems)
6. [Performance Issues](#performance-issues)
7. [System Service Problems](#system-service-problems)
8. [Network and Firewall Issues](#network-and-firewall-issues)
9. [Log Analysis](#log-analysis)
10. [Advanced Debugging](#advanced-debugging)

## General Troubleshooting Steps

### 1. Check System Status

First, verify the basic system status:

```bash
# Run the global menu
menu

# Or check services directly
systemctl status xray
systemctl status nginx
```

### 2. Review Logs

Check the latest log entries:

```bash
# Xray logs
tail -n 50 /var/log/xray/error.log
tail -n 50 /var/log/xray/access.log

# Nginx logs
tail -n 50 /var/log/nginx/error.log
tail -n 50 /var/log/nginx/access.log

# System logs
journalctl -u xray -n 50
journalctl -u nginx -n 50
```

### 3. Verify Configuration

Check configuration files:

```bash
# Test Xray configuration
xray test -config /usr/local/etc/xray/config.json

# Test Nginx configuration
nginx -t

# Check port configuration
cat /root/xray-ports.conf
```

## Installation Issues

### Issue: Script Fails During Installation

**Symptoms:**
- Installation stops with errors
- Permission denied errors
- Package installation failures

**Solutions:**

1. **Check Root Privileges:**
   ```bash
   whoami  # Should return 'root'
   sudo su  # Switch to root if needed
   ```

2. **Update System:**
   ```bash
   # Ubuntu/Debian
   apt update && apt upgrade -y
   
   # CentOS/Rocky Linux
   yum update -y
   ```

3. **Check Disk Space:**
   ```bash
   df -h  # Should have at least 1GB free
   ```

4. **Verify Internet Connection:**
   ```bash
   ping -c 4 google.com
   curl -I https://github.com
   ```

### Issue: Incompatible Operating System

**Symptoms:**
- "Unsupported operating system" error
- Package manager not found

**Solutions:**

1. **Check OS Version:**
   ```bash
   cat /etc/os-release
   uname -a
   ```

2. **Supported Systems:**
   - Ubuntu 20.04+ ✅
   - Debian 10+ ✅
   - CentOS 7+ ✅
   - Rocky Linux 8+ ✅

3. **Manual Installation:**
   If your OS is compatible but not detected, modify the `detect_os()` function.

## SSL Certificate Problems

### Issue: Let's Encrypt Certificate Fails

**Symptoms:**
- SSL certificate generation fails
- "Failed to verify domain" error
- Certificate not trusted by clients

**Solutions:**

1. **Verify Domain DNS:**
   ```bash
   # Check if domain points to your server
   nslookup your-domain.com
   dig A your-domain.com
   
   # Should return your server's IP
   ```

2. **Check Port 80 Access:**
   ```bash
   # Ensure port 80 is accessible
   netstat -tlnp | grep :80
   curl -I http://your-domain.com
   ```

3. **Domain Validation Issues:**
   ```bash
   # Check if domain is accessible
   curl -v http://your-domain.com/.well-known/acme-challenge/test
   ```

4. **Firewall Configuration:**
   ```bash
   # Check firewall status
   ufw status
   
   # Allow HTTP/HTTPS if blocked
   ufw allow 80/tcp
   ufw allow 443/tcp
   ```

5. **Manual Certificate Generation:**
   ```bash
   # Try manual certificate generation
   certbot certonly --standalone -d your-domain.com
   ```

### Issue: Self-Signed Certificate Warnings

**Symptoms:**
- Browser shows certificate warnings
- Clients refuse to connect

**Solutions:**

1. **Switch to Let's Encrypt:**
   ```bash
   menu
   # Select SSL management
   # Choose Let's Encrypt option
   ```

2. **Add Certificate to Client:**
   - Download the certificate from `/etc/xray-ssl/cert.pem`
   - Add to client's trusted certificates

## Connection Issues

### Issue: Cannot Connect to Proxy

**Symptoms:**
- Connection timeout
- "Connection refused" error
- Proxy not working

**Solutions:**

1. **Check Service Status:**
   ```bash
   systemctl status xray
   systemctl status nginx
   
   # Restart if needed
   systemctl restart xray nginx
   ```

2. **Verify Port Configuration:**
   ```bash
   # Check if ports are listening
   netstat -tlnp | grep -E "(80|443|10001|10002|10003)"
   ss -tlnp | grep -E "(80|443|10001|10002|10003)"
   ```

3. **Test Local Connection:**
   ```bash
   # Test Xray directly
   curl -v --socks5 127.0.0.1:10808 http://google.com
   
   # Test via Nginx
   curl -v https://your-domain.com
   ```

4. **Check Firewall Rules:**
   ```bash
   # Ubuntu/Debian
   ufw status
   
   # CentOS/Rocky
   firewall-cmd --list-all
   ```

### Issue: Slow Connection Speed

**Symptoms:**
- Very slow browsing
- Frequent disconnections
- High latency

**Solutions:**

1. **Check BBR Status:**
   ```bash
   sysctl net.ipv4.tcp_congestion_control
   # Should show: bbr
   ```

2. **Optimize Network Settings:**
   ```bash
   # Re-run network optimization
   menu
   # Select optimization options
   ```

3. **Check Server Resources:**
   ```bash
   top
   htop
   iostat 1 5
   ```

4. **Test Network Speed:**
   ```bash
   # Install speedtest
   curl -s https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
   speedtest
   ```

## User Management Problems

### Issue: User Creation Fails

**Symptoms:**
- "Failed to create user" error
- Generated config doesn't work
- User not added to database

**Solutions:**

1. **Check Database File:**
   ```bash
   # Verify database exists and is writable
   ls -la /root/xray-users.db
   touch /root/xray-users.db
   chmod 600 /root/xray-users.db
   ```

2. **Validate Username:**
   ```bash
   # Username should be alphanumeric
   # No special characters except underscore and hyphen
   ```

3. **Check UUID Generation:**
   ```bash
   # Test UUID generation
   uuidgen
   cat /proc/sys/kernel/random/uuid
   ```

4. **Manual User Creation:**
   ```bash
   # Create user manually
   uuid=$(uuidgen)
   echo "username:$uuid:$(date -d '+30 days' '+%Y-%m-%d'):100GB:active" >> /root/xray-users.db
   ```

### Issue: User Config Not Working

**Symptoms:**
- Client shows connection failed
- Generated QR code doesn't work
- Config seems invalid

**Solutions:**

1. **Verify Port Configuration:**
   ```bash
   # Check port mapping
   cat /root/xray-ports.conf
   
   # Verify ports match in Nginx config
   grep -r "proxy_pass" /etc/nginx/sites-available/
   ```

2. **Check WebSocket Paths:**
   ```bash
   # Verify WebSocket paths are consistent
   grep -r "vmessws\|vlessws\|trojanws" /usr/local/etc/xray/config.json
   grep -r "vmessws\|vlessws\|trojanws" /etc/nginx/sites-available/
   ```

3. **Test Configuration:**
   ```bash
   # Validate Xray config
   xray test -config /usr/local/etc/xray/config.json
   ```

## Performance Issues

### Issue: High CPU Usage

**Symptoms:**
- Server becomes unresponsive
- High load average
- Slow connections

**Solutions:**

1. **Identify Process:**
   ```bash
   top -p $(pgrep xray)
   htop
   ```

2. **Check Connection Count:**
   ```bash
   # Count active connections
   netstat -an | grep ESTABLISHED | wc -l
   ss -s
   ```

3. **Optimize Configuration:**
   ```bash
   # Reduce log level
   sed -i 's/"loglevel": "info"/"loglevel": "warning"/' /usr/local/etc/xray/config.json
   systemctl restart xray
   ```

### Issue: High Memory Usage

**Symptoms:**
- Out of memory errors
- System swap usage high
- Services get killed

**Solutions:**

1. **Check Memory Usage:**
   ```bash
   free -h
   ps aux --sort=-%mem | head -10
   ```

2. **Optimize Memory:**
   ```bash
   # Clear caches
   echo 3 > /proc/sys/vm/drop_caches
   
   # Restart services
   systemctl restart xray nginx
   ```

## System Service Problems

### Issue: Xray Service Won't Start

**Symptoms:**
- `systemctl start xray` fails
- Service shows "failed" status
- Error in systemd logs

**Solutions:**

1. **Check Service Status:**
   ```bash
   systemctl status xray -l
   journalctl -u xray -n 50
   ```

2. **Validate Configuration:**
   ```bash
   xray test -config /usr/local/etc/xray/config.json
   ```

3. **Check File Permissions:**
   ```bash
   # Fix permissions
   chown -R xray:xray /usr/local/etc/xray
   chmod 644 /usr/local/etc/xray/config.json
   ```

4. **Recreate Service File:**
   ```bash
   # Reinstall service
   menu
   # Select reinstall option
   ```

### Issue: Nginx Configuration Error

**Symptoms:**
- Nginx won't start
- "Configuration test failed" error
- SSL-related errors

**Solutions:**

1. **Test Configuration:**
   ```bash
   nginx -t
   ```

2. **Check SSL Certificates:**
   ```bash
   ls -la /etc/xray-ssl/
   openssl x509 -in /etc/xray-ssl/cert.pem -text -noout
   ```

3. **Fix Common Issues:**
   ```bash
   # Remove duplicate server blocks
   grep -n "server {" /etc/nginx/sites-available/xray*
   
   # Check for syntax errors
   nginx -T | grep -i error
   ```

## Network and Firewall Issues

### Issue: Ports Not Accessible

**Symptoms:**
- Connection refused from outside
- Ports show as closed in external scans
- Local connections work, remote don't

**Solutions:**

1. **Check Firewall Rules:**
   ```bash
   # Ubuntu/Debian with UFW
   ufw status numbered
   ufw allow 80/tcp
   ufw allow 443/tcp
   
   # CentOS/Rocky with firewalld
   firewall-cmd --list-all
   firewall-cmd --add-port=80/tcp --permanent
   firewall-cmd --add-port=443/tcp --permanent
   firewall-cmd --reload
   ```

2. **Check Cloud Provider Security Groups:**
   - AWS: Check Security Groups
   - Google Cloud: Check Firewall Rules
   - Azure: Check Network Security Groups
   - DigitalOcean: Check Firewalls

3. **Test Port Accessibility:**
   ```bash
   # From external machine
   telnet your-server-ip 443
   nmap -p 80,443 your-server-ip
   ```

### Issue: DNS Resolution Problems

**Symptoms:**
- Domain doesn't resolve
- Intermittent connection issues
- DNS-related timeouts

**Solutions:**

1. **Check DNS Configuration:**
   ```bash
   # Test DNS resolution
   nslookup your-domain.com
   dig A your-domain.com
   
   # Check system DNS
   cat /etc/resolv.conf
   ```

2. **Update DNS Settings:**
   ```bash
   # Use reliable DNS servers
   echo "nameserver 8.8.8.8" > /etc/resolv.conf
   echo "nameserver 1.1.1.1" >> /etc/resolv.conf
   ```

## Log Analysis

### Understanding Xray Logs

**Access Logs** (`/var/log/xray/access.log`):
```
2024-01-26 10:30:15 [Info] [1234567890] proxy/vmess/inbound: connection opened
2024-01-26 10:30:15 [Info] [1234567890] app/dispatcher: taking detour [direct]
```

**Error Logs** (`/var/log/xray/error.log`):
```
2024-01-26 10:30:15 [Warning] [1234567890] app/proxyman/inbound: connection ends
2024-01-26 10:30:15 [Error] [1234567890] proxy/vmess/inbound: failed to read request
```

### Understanding Nginx Logs

**Access Logs** (`/var/log/nginx/access.log`):
```
192.168.1.100 - - [26/Jan/2024:10:30:15 +0000] "GET /vmessws HTTP/1.1" 101 0
```

**Error Logs** (`/var/log/nginx/error.log`):
```
2024/01/26 10:30:15 [error] 12345#12345: *1 upstream prematurely closed connection
```

### Common Log Messages

| Message | Meaning | Solution |
|---------|---------|----------|
| `connection opened` | Successful connection | Normal operation |
| `failed to read request` | Invalid client request | Check client config |
| `upstream prematurely closed` | Backend connection lost | Check Xray service |
| `certificate verify failed` | SSL certificate issue | Update certificate |
| `connection refused` | Service not responding | Check service status |

## Advanced Debugging

### Enable Debug Mode

1. **Xray Debug Mode:**
   ```bash
   # Edit config to enable debug logging
   sed -i 's/"loglevel": "warning"/"loglevel": "debug"/' /usr/local/etc/xray/config.json
   systemctl restart xray
   ```

2. **Nginx Debug Mode:**
   ```bash
   # Add debug log to nginx config
   echo "error_log /var/log/nginx/debug.log debug;" >> /etc/nginx/nginx.conf
   nginx -s reload
   ```

### Network Packet Analysis

1. **Install tcpdump:**
   ```bash
   apt install tcpdump -y  # Ubuntu/Debian
   yum install tcpdump -y  # CentOS
   ```

2. **Capture Traffic:**
   ```bash
   # Capture traffic on port 443
   tcpdump -i any -nn port 443 -w capture.pcap
   
   # Monitor in real-time
   tcpdump -i any -nn port 443
   ```

3. **Analyze with Wireshark:**
   - Download capture.pcap
   - Open in Wireshark for detailed analysis

### Performance Monitoring

1. **Install Monitoring Tools:**
   ```bash
   apt install htop iotop nethogs -y
   ```

2. **Monitor System Resources:**
   ```bash
   # CPU and memory
   htop
   
   # Disk I/O
   iotop
   
   # Network usage by process
   nethogs
   
   # Real-time stats
   watch -n 1 'ss -s && free -h'
   ```

### Configuration Validation

1. **Validate JSON Configuration:**
   ```bash
   # Check JSON syntax
   python3 -m json.tool /usr/local/etc/xray/config.json
   jq . /usr/local/etc/xray/config.json
   ```

2. **Compare Configurations:**
   ```bash
   # Compare with working config
   diff /usr/local/etc/xray/config.json /backup/config.json
   ```

## Getting Additional Help

### Information to Collect

When seeking help, collect this information:

```bash
# System Information
uname -a
cat /etc/os-release
df -h
free -h

# Service Status
systemctl status xray
systemctl status nginx

# Configuration
cat /root/xray-ports.conf
nginx -T
xray test -config /usr/local/etc/xray/config.json

# Recent Logs
tail -n 100 /var/log/xray/error.log
tail -n 100 /var/log/nginx/error.log
```

### Support Channels

1. **GitHub Issues**: For bug reports and feature requests
2. **Discussions**: For questions and community support
3. **Documentation**: Check README.md and other docs

### Emergency Recovery

If the system is completely broken:

1. **Stop All Services:**
   ```bash
   systemctl stop xray nginx
   ```

2. **Backup Current Config:**
   ```bash
   cp -r /usr/local/etc/xray /root/xray-backup-$(date +%Y%m%d)
   ```

3. **Reinstall:**
   ```bash
   ./xray-auto-install.sh --reinstall
   ```

4. **Restore User Data:**
   ```bash
   cp /root/xray-backup-*/xray-users.db /root/
   ```

---

**Note**: If you encounter issues not covered here, please check the [FAQ](faq.md) or create an issue on GitHub with detailed information about your problem.
