#!/bin/bash

# Example script for batch user creation
# This script demonstrates how to create multiple users from a CSV file

# CSV format: username,days_valid,traffic_limit_gb,email
# Example:
# user001,30,50,user001@example.com
# user002,60,100,user002@example.com

CSV_FILE="${1:-users.csv}"
LOG_FILE="/var/log/batch-user-creation.log"

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Check if CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "CSV file not found: $CSV_FILE"
    echo "Usage: $0 [csv_file]"
    echo ""
    echo "CSV Format:"
    echo "username,days_valid,traffic_limit_gb,email"
    echo "user001,30,50,user001@example.com"
    exit 1
fi

# Source the main script functions
if [[ -f "/root/xray-auto-install.sh" ]]; then
    source /root/xray-auto-install.sh
else
    echo "Xray auto-install script not found. Please install first."
    exit 1
fi

# Initialize log
echo "=== Batch User Creation Started: $(date) ===" >> "$LOG_FILE"

# Read CSV file and create users
total_users=0
successful_users=0
failed_users=0

while IFS=',' read -r username days_valid traffic_limit email; do
    # Skip header line
    if [[ "$username" == "username" ]]; then
        continue
    fi
    
    # Skip empty lines
    if [[ -z "$username" ]]; then
        continue
    fi
    
    total_users=$((total_users + 1))
    
    echo "Processing user: $username"
    echo "Creating user: $username (${days_valid} days, ${traffic_limit}GB)" >> "$LOG_FILE"
    
    # Create user
    if create_user "$username" "$days_valid" "$traffic_limit"; then
        successful_users=$((successful_users + 1))
        echo "✅ User $username created successfully"
        echo "SUCCESS: User $username created" >> "$LOG_FILE"
        
        # Generate configuration files
        config_dir="/root/user-configs/$username"
        mkdir -p "$config_dir"
        
        # Get user info
        user_uuid=$(grep "^$username:" /root/xray-users.db | cut -d: -f2)
        domain=$(cat /root/xray-domain.conf 2>/dev/null || hostname -I | awk '{print $1}')
        
        # Generate VMess config
        generate_vmess_config "$username" "$user_uuid" "$domain" > "$config_dir/vmess.json"
        
        # Generate VLESS config  
        generate_vless_config "$username" "$user_uuid" "$domain" > "$config_dir/vless.json"
        
        # Generate Trojan config
        generate_trojan_config "$username" "$user_uuid" "$domain" > "$config_dir/trojan.json"
        
        # Generate QR codes if qrencode is available
        if command -v qrencode >/dev/null 2>&1; then
            vmess_link=$(generate_vmess_link "$user_uuid" "$domain")
            vless_link=$(generate_vless_link "$user_uuid" "$domain")
            trojan_link=$(generate_trojan_link "$user_uuid" "$domain")
            
            echo "$vmess_link" | qrencode -o "$config_dir/vmess-qr.png"
            echo "$vless_link" | qrencode -o "$config_dir/vless-qr.png"
            echo "$trojan_link" | qrencode -o "$config_dir/trojan-qr.png"
        fi
        
        # Send email if configured
        if [[ -n "$email" ]] && command -v sendmail >/dev/null 2>&1; then
            send_user_config_email "$username" "$email" "$config_dir"
        fi
        
    else
        failed_users=$((failed_users + 1))
        echo "❌ Failed to create user: $username"
        echo "FAILED: User $username creation failed" >> "$LOG_FILE"
    fi
    
    echo "---"
    
done < "$CSV_FILE"

# Summary
echo ""
echo "=== Batch User Creation Summary ==="
echo "Total users processed: $total_users"
echo "Successful: $successful_users"
echo "Failed: $failed_users"
echo ""

# Log summary
echo "=== Summary ===" >> "$LOG_FILE"
echo "Total: $total_users, Success: $successful_users, Failed: $failed_users" >> "$LOG_FILE"
echo "=== Batch User Creation Ended: $(date) ===" >> "$LOG_FILE"

# Helper functions for configuration generation
generate_vmess_config() {
    local username="$1"
    local uuid="$2"  
    local domain="$3"
    
    cat << EOF
{
  "v": "2",
  "ps": "$username-vmess",
  "add": "$domain",
  "port": "443",
  "id": "$uuid",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "$domain",
  "path": "/vmessws",
  "tls": "tls",
  "sni": "$domain",
  "alpn": ""
}
EOF
}

generate_vless_config() {
    local username="$1"
    local uuid="$2"
    local domain="$3"
    
    cat << EOF
{
  "protocol": "vless",
  "ps": "$username-vless",
  "add": "$domain",
  "port": "443",
  "id": "$uuid",
  "net": "ws",
  "type": "none",
  "host": "$domain", 
  "path": "/vlessws",
  "tls": "tls",
  "sni": "$domain",
  "flow": ""
}
EOF
}

generate_trojan_config() {
    local username="$1"
    local uuid="$2"
    local domain="$3"
    
    cat << EOF
{
  "protocol": "trojan",
  "ps": "$username-trojan",
  "add": "$domain",
  "port": "443", 
  "password": "$uuid",
  "net": "ws",
  "type": "none",
  "host": "$domain",
  "path": "/trojanws",
  "tls": "tls",
  "sni": "$domain"
}
EOF
}

send_user_config_email() {
    local username="$1"
    local email="$2"
    local config_dir="$3"
    
    cat << EOF | sendmail "$email"
Subject: Your Xray Proxy Configuration - $username

Hello,

Your Xray proxy account has been created successfully!

Username: $username
Configuration files are attached.

You can use any of the following protocols:
- VMess (recommended for general use)
- VLESS (lightweight protocol)
- Trojan (looks like HTTPS traffic)

Client Applications:
- Android: v2rayNG, SagerNet
- iOS: Shadowrocket, Quantumult X
- Windows: v2rayN, Qv2ray
- macOS: V2rayU, ClashX
- Linux: Qv2ray, v2ray-core

Support: If you need help, please contact support.

Best regards,
Xray Server Team
EOF
}