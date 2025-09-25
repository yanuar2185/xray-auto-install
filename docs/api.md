# API Documentation

The Xray Auto Install Script provides a comprehensive API for managing users, monitoring traffic, and configuring the system programmatically.

## Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [User Management](#user-management)
4. [Traffic Monitoring](#traffic-monitoring)
5. [System Configuration](#system-configuration)
6. [SSL Management](#ssl-management)
7. [Error Handling](#error-handling)
8. [Examples](#examples)

## Overview

### Base URL
The API is accessed through the menu system or directly via script functions:

```bash
# Interactive menu
menu

# Direct function calls
source /root/xray-auto-install.sh
function_name parameters
```

### Response Format
All responses are returned in a structured format with status codes and messages.

## Authentication

### Root Access Required
All API functions require root privileges:

```bash
# Check root access
if [[ $EUID -ne 0 ]]; then
    echo "Root access required"
    exit 1
fi
```

### API Key (Optional)
For enhanced security, you can configure API key authentication:

```bash
export XRAY_API_KEY="your-secure-api-key"
```

## User Management

### Create User

Create a new user with specified parameters.

```bash
# Function: create_user
# Parameters: username, days_valid, traffic_limit_gb
create_user "testuser" 30 100
```

**Parameters:**
- `username` (string): Unique username
- `days_valid` (integer): Days until expiration
- `traffic_limit_gb` (integer): Traffic limit in GB (0 = unlimited)

**Response:**
```json
{
  "status": "success",
  "message": "User created successfully",
  "user": {
    "username": "testuser",
    "uuid": "550e8400-e29b-41d4-a716-446655440000",
    "expiry": "2024-02-25",
    "traffic_limit": "100GB",
    "protocols": ["vmess", "vless", "trojan"]
  },
  "configs": {
    "vmess": "vmess://eyJ2IjoiMi...",
    "vless": "vless://550e8400-e...",
    "trojan": "trojan://550e8400-e..."
  }
}
```

### List Users

Retrieve all user accounts with their status.

```bash
# Function: list_users
list_users
```

**Response:**
```json
{
  "status": "success",
  "users": [
    {
      "username": "testuser",
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "expiry": "2024-02-25",
      "status": "active",
      "traffic_used": "25.5GB",
      "traffic_limit": "100GB"
    }
  ],
  "total_users": 1,
  "active_users": 1
}
```

### Get User Details

Retrieve detailed information about a specific user.

```bash
# Function: get_user_info
# Parameters: username
get_user_info "testuser"
```

**Response:**
```json
{
  "status": "success",
  "user": {
    "username": "testuser",
    "uuid": "550e8400-e29b-41d4-a716-446655440000",
    "created": "2024-01-25",
    "expiry": "2024-02-25",
    "status": "active",
    "traffic_used": "25.5GB",
    "traffic_limit": "100GB",
    "last_connection": "2024-01-26 10:30:00",
    "protocols": ["vmess", "vless", "trojan"],
    "connections": {
      "current": 3,
      "peak": 5,
      "total": 125
    }
  }
}
```

### Update User

Modify user settings.

```bash
# Function: update_user
# Parameters: username, field, value
update_user "testuser" "traffic_limit" "200"
update_user "testuser" "expiry" "60"
```

**Parameters:**
- `username` (string): Target username
- `field` (string): Field to update (`traffic_limit`, `expiry`, `status`)
- `value` (string): New value

### Delete User

Remove a user account.

```bash
# Function: delete_user
# Parameters: username
delete_user "testuser"
```

**Response:**
```json
{
  "status": "success",
  "message": "User deleted successfully",
  "username": "testuser"
}
```

### Reset User Traffic

Reset traffic statistics for a user.

```bash
# Function: reset_user_traffic
# Parameters: username
reset_user_traffic "testuser"
```

## Traffic Monitoring

### Get System Statistics

Retrieve overall system traffic statistics.

```bash
# Function: get_system_stats
get_system_stats
```

**Response:**
```json
{
  "status": "success",
  "stats": {
    "total_users": 10,
    "active_users": 8,
    "total_traffic": "1.2TB",
    "monthly_traffic": "450GB",
    "daily_traffic": "15.2GB",
    "current_connections": 25,
    "peak_connections": 45,
    "uptime": "15 days, 6 hours",
    "protocols": {
      "vmess": "60%",
      "vless": "25%",
      "trojan": "15%"
    }
  }
}
```

### Get User Traffic

Retrieve traffic statistics for a specific user.

```bash
# Function: get_user_traffic
# Parameters: username, period (optional: day/week/month)
get_user_traffic "testuser" "month"
```

**Response:**
```json
{
  "status": "success",
  "traffic": {
    "username": "testuser",
    "period": "month",
    "upload": "12.5GB",
    "download": "25.8GB",
    "total": "38.3GB",
    "limit": "100GB",
    "remaining": "61.7GB",
    "daily_average": "1.24GB",
    "protocols": {
      "vmess": "20.1GB",
      "vless": "10.2GB",
      "trojan": "8.0GB"
    }
  }
}
```

### Export Traffic Data

Export traffic data in various formats.

```bash
# Function: export_traffic_data
# Parameters: format (json/csv/xml), period, output_file
export_traffic_data "json" "month" "/tmp/traffic-report.json"
```

## System Configuration

### Get System Configuration

Retrieve current system configuration.

```bash
# Function: get_system_config
get_system_config
```

**Response:**
```json
{
  "status": "success",
  "config": {
    "version": "2.0.0",
    "domain": "example.com",
    "ssl_method": "letsencrypt",
    "protocols": ["vmess", "vless", "trojan"],
    "ports": {
      "vmess": 10001,
      "vless": 10002,
      "trojan": 10003,
      "nginx": [80, 443]
    },
    "bbr_enabled": true,
    "dns_provider": "cloudflare",
    "backup_enabled": true,
    "monitoring_enabled": true
  }
}
```

### Update Configuration

Modify system configuration.

```bash
# Function: update_config
# Parameters: section, key, value
update_config "ssl" "method" "letsencrypt"
update_config "monitoring" "enabled" "true"
```

### Restart Services

Restart Xray and related services.

```bash
# Function: restart_services
# Parameters: service (optional: xray/nginx/all)
restart_services "all"
```

## SSL Management

### Get SSL Status

Check SSL certificate status.

```bash
# Function: get_ssl_status
get_ssl_status
```

**Response:**
```json
{
  "status": "success",
  "ssl": {
    "method": "letsencrypt",
    "domain": "example.com",
    "valid": true,
    "expires": "2024-04-25",
    "days_remaining": 89,
    "auto_renewal": true,
    "certificate_path": "/etc/xray-ssl/cert.pem",
    "key_path": "/etc/xray-ssl/key.pem"
  }
}
```

### Renew SSL Certificate

Manually renew SSL certificate.

```bash
# Function: renew_ssl_cert
renew_ssl_cert
```

### Update SSL Configuration

Change SSL settings.

```bash
# Function: update_ssl_config
# Parameters: domain, method
update_ssl_config "newdomain.com" "letsencrypt"
```

## Error Handling

### Standard Error Responses

All API functions return standardized error responses:

```json
{
  "status": "error",
  "error_code": "USER_NOT_FOUND",
  "message": "User 'testuser' not found",
  "details": {
    "requested_user": "testuser",
    "available_users": ["user1", "user2"]
  }
}
```

### Common Error Codes

| Code | Description |
|------|-------------|
| `USER_NOT_FOUND` | Requested user does not exist |
| `USER_EXISTS` | User already exists |
| `INVALID_PARAMETER` | Invalid parameter provided |
| `PERMISSION_DENIED` | Insufficient permissions |
| `SERVICE_UNAVAILABLE` | Required service is not running |
| `SSL_ERROR` | SSL certificate issue |
| `NETWORK_ERROR` | Network connectivity issue |
| `DISK_FULL` | Insufficient disk space |
| `CONFIG_ERROR` | Configuration file error |

## Examples

### Batch User Creation

Create multiple users from a CSV file:

```bash
#!/bin/bash
# batch_create_users.sh

while IFS=',' read -r username days_valid traffic_limit; do
    echo "Creating user: $username"
    create_user "$username" "$days_valid" "$traffic_limit"
done < users.csv
```

### Automated Traffic Monitoring

Set up automated traffic monitoring:

```bash
#!/bin/bash
# monitor_traffic.sh

# Check for users exceeding 80% of their limit
get_system_stats | jq -r '.stats.users[] | select(.traffic_usage_percent > 80) | .username' | while read -r user; do
    echo "Warning: User $user has exceeded 80% traffic limit"
    # Send notification
done
```

### SSL Certificate Monitoring

Monitor SSL certificate expiration:

```bash
#!/bin/bash
# ssl_monitor.sh

ssl_status=$(get_ssl_status)
days_remaining=$(echo "$ssl_status" | jq -r '.ssl.days_remaining')

if [ "$days_remaining" -lt 30 ]; then
    echo "SSL certificate expires in $days_remaining days"
    renew_ssl_cert
fi
```

### User Management Dashboard

Create a simple dashboard:

```bash
#!/bin/bash
# dashboard.sh

echo "=== Xray Server Dashboard ==="
echo "System Status:"
get_system_stats | jq -r '
  "Total Users: " + (.stats.total_users | tostring) + "\n" +
  "Active Users: " + (.stats.active_users | tostring) + "\n" +
  "Total Traffic: " + .stats.total_traffic + "\n" +
  "Current Connections: " + (.stats.current_connections | tostring)
'

echo -e "\nRecent Users:"
list_users | jq -r '.users[] | .username + " - " + .status + " (" + .traffic_used + "/" + .traffic_limit + ")"'
```

### Configuration Backup

Automated configuration backup:

```bash
#!/bin/bash
# backup_config.sh

backup_dir="/root/xray-backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# Backup configuration files
cp -r /usr/local/etc/xray "$backup_dir/"
cp /root/xray-users.db "$backup_dir/"
cp /root/xray-ports.conf "$backup_dir/"

# Create archive
tar -czf "$backup_dir.tar.gz" -C "$backup_dir" .
rm -rf "$backup_dir"

echo "Backup created: $backup_dir.tar.gz"
```

---

**Note**: This API documentation covers the programmatic interface. For interactive usage, see the [User Guide](user-guide.md).
