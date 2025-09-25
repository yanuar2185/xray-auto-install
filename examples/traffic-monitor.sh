#!/bin/bash

# Traffic monitoring script for Xray users
# This script monitors user traffic and sends alerts when limits are reached

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/traffic-monitor.log"
ALERT_THRESHOLD=80  # Alert when usage exceeds 80%
SUSPEND_THRESHOLD=95  # Suspend when usage exceeds 95%

# Email settings (configure these)
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
EMAIL_FROM="admin@yourserver.com"
EMAIL_PASSWORD=""  # Use app password for Gmail

# Telegram settings (optional)
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_message "${RED}This script must be run as root${NC}"
    exit 1
fi

# Source main script functions
if [[ -f "/root/xray-auto-install.sh" ]]; then
    source /root/xray-auto-install.sh
else
    log_message "${RED}Xray auto-install script not found${NC}"
    exit 1
fi

# Function to get user traffic in bytes
get_user_traffic_bytes() {
    local username="$1"
    local user_uuid=$(grep "^$username:" /root/xray-users.db | cut -d: -f2)
    
    if [[ -z "$user_uuid" ]]; then
        echo "0"
        return
    fi
    
    # Get traffic from Xray statistics
    local traffic_file="/var/xray-stats/user_${username}.stats"
    if [[ -f "$traffic_file" ]]; then
        cat "$traffic_file" | grep "traffic_total" | cut -d: -f2 || echo "0"
    else
        echo "0"
    fi
}

# Function to convert bytes to human readable
bytes_to_human() {
    local bytes="$1"
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [[ $bytes -gt 1024 && $unit -lt 4 ]]; do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done
    
    echo "${bytes}${units[$unit]}"
}

# Function to send email alert
send_email_alert() {
    local subject="$1"
    local message="$2"
    local recipient="$3"
    
    if [[ -z "$EMAIL_PASSWORD" ]]; then
        log_message "${YELLOW}Email not configured, skipping email alert${NC}"
        return
    fi
    
    cat << EOF | python3 -c "
import smtplib
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

msg = MIMEMultipart()
msg['From'] = '$EMAIL_FROM'
msg['To'] = '$recipient'
msg['Subject'] = '$subject'

body = '''$message'''
msg.attach(MIMEText(body, 'plain'))

try:
    server = smtplib.SMTP('$SMTP_SERVER', $SMTP_PORT)
    server.starttls()
    server.login('$EMAIL_FROM', '$EMAIL_PASSWORD')
    text = msg.as_string()
    server.sendmail('$EMAIL_FROM', '$recipient', text)
    server.quit()
    print('Email sent successfully')
except Exception as e:
    print(f'Failed to send email: {e}')
"
}

# Function to send Telegram alert
send_telegram_alert() {
    local message="$1"
    
    if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
        log_message "${YELLOW}Telegram not configured, skipping Telegram alert${NC}"
        return
    fi
    
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d text="$message" \
        -d parse_mode="Markdown" > /dev/null
}

# Function to suspend user
suspend_user() {
    local username="$1"
    
    # Update user status in database
    sed -i "s/^$username:\(.*\):active$/$username:\1:suspended/" /root/xray-users.db
    
    # Remove user from Xray configuration
    remove_user_from_config "$username"
    
    # Restart Xray to apply changes
    systemctl restart xray
    
    log_message "${RED}User $username has been suspended due to traffic limit exceeded${NC}"
}

# Function to generate traffic report
generate_traffic_report() {
    local report_file="/tmp/traffic-report-$(date +%Y%m%d).txt"
    
    cat << EOF > "$report_file"
Xray Traffic Report - $(date)
================================

System Overview:
- Server: $(hostname)
- Uptime: $(uptime -p)
- Total Users: $(wc -l < /root/xray-users.db)

User Traffic Summary:
EOF
    
    while IFS=':' read -r username uuid expiry limit status; do
        if [[ "$status" == "active" ]]; then
            local traffic_bytes=$(get_user_traffic_bytes "$username")
            local traffic_human=$(bytes_to_human "$traffic_bytes")
            local limit_bytes=$((limit * 1024 * 1024 * 1024))  # Convert GB to bytes
            local usage_percent=0
            
            if [[ $limit_bytes -gt 0 ]]; then
                usage_percent=$(( (traffic_bytes * 100) / limit_bytes ))
            fi
            
            printf "%-15s %-10s %-8s %3d%%\n" "$username" "$traffic_human" "$limit" "$usage_percent" >> "$report_file"
        fi
    done < /root/xray-users.db
    
    echo "$report_file"
}

# Main monitoring function
monitor_traffic() {
    log_message "${BLUE}Starting traffic monitoring check...${NC}"
    
    local alerts_sent=0
    local users_suspended=0
    
    while IFS=':' read -r username uuid expiry limit status; do
        if [[ "$status" != "active" ]]; then
            continue
        fi
        
        # Skip unlimited users (limit = 0)
        if [[ "$limit" == "0" ]]; then
            continue
        fi
        
        local traffic_bytes=$(get_user_traffic_bytes "$username")
        local limit_bytes=$((limit * 1024 * 1024 * 1024))  # Convert GB to bytes
        local usage_percent=0
        
        if [[ $limit_bytes -gt 0 ]]; then
            usage_percent=$(( (traffic_bytes * 100) / limit_bytes ))
        fi
        
        local traffic_human=$(bytes_to_human "$traffic_bytes")
        
        # Check if user should be suspended
        if [[ $usage_percent -ge $SUSPEND_THRESHOLD ]]; then
            suspend_user "$username"
            users_suspended=$((users_suspended + 1))
            
            local alert_message="🚨 *User Suspended*
            
User: \`$username\`
Traffic Used: $traffic_human / ${limit}GB (${usage_percent}%)
Status: Suspended due to traffic limit exceeded
Time: $(date)"
            
            send_telegram_alert "$alert_message"
            send_email_alert "User Suspended: $username" "$alert_message" "admin@yourserver.com"
            
        # Check if alert should be sent
        elif [[ $usage_percent -ge $ALERT_THRESHOLD ]]; then
            # Check if alert was already sent today
            local alert_file="/tmp/alert-sent-$username-$(date +%Y%m%d)"
            if [[ ! -f "$alert_file" ]]; then
                alerts_sent=$((alerts_sent + 1))
                touch "$alert_file"
                
                local alert_message="⚠️ *Traffic Alert*
                
User: \`$username\`
Traffic Used: $traffic_human / ${limit}GB (${usage_percent}%)
Status: Approaching limit
Time: $(date)"
                
                send_telegram_alert "$alert_message"
                send_email_alert "Traffic Alert: $username" "$alert_message" "admin@yourserver.com"
                
                log_message "${YELLOW}Alert sent for user $username (${usage_percent}% usage)${NC}"
            fi
        fi
        
        # Log current usage
        log_message "User: $username, Traffic: $traffic_human/${limit}GB (${usage_percent}%)"
        
    done < /root/xray-users.db
    
    log_message "${GREEN}Traffic monitoring completed. Alerts: $alerts_sent, Suspended: $users_suspended${NC}"
}

# Function to cleanup old alert files
cleanup_old_alerts() {
    find /tmp -name "alert-sent-*" -mtime +7 -delete 2>/dev/null
}

# Function to reset monthly traffic (call on 1st of each month)
reset_monthly_traffic() {
    log_message "${BLUE}Resetting monthly traffic statistics...${NC}"
    
    # Clear traffic statistics files
    find /var/xray-stats -name "user_*.stats" -exec rm -f {} \;
    
    # Reactivate suspended users (optional)
    sed -i 's/:suspended$/:active/' /root/xray-users.db
    
    # Restart Xray to apply changes
    systemctl restart xray
    
    log_message "${GREEN}Monthly traffic reset completed${NC}"
}

# Function to generate daily report
generate_daily_report() {
    local report_file=$(generate_traffic_report)
    local report_content=$(cat "$report_file")
    
    local daily_message="📊 *Daily Traffic Report*

$(cat "$report_file")

Generated: $(date)
Server: $(hostname)"
    
    send_telegram_alert "$daily_message"
    send_email_alert "Daily Traffic Report - $(date +%Y-%m-%d)" "$report_content" "admin@yourserver.com"
    
    rm -f "$report_file"
}

# Main script logic
case "${1:-monitor}" in
    "monitor")
        cleanup_old_alerts
        monitor_traffic
        ;;
    "report")
        generate_daily_report
        ;;
    "reset")
        reset_monthly_traffic
        ;;
    "test-alerts")
        log_message "${BLUE}Testing alert systems...${NC}"
        send_telegram_alert "🧪 *Test Alert*\n\nThis is a test message from Xray traffic monitor.\nTime: $(date)"
        send_email_alert "Test Alert" "This is a test email from Xray traffic monitor." "admin@yourserver.com"
        ;;
    *)
        echo "Usage: $0 {monitor|report|reset|test-alerts}"
        echo ""
        echo "Commands:"
        echo "  monitor     - Check user traffic and send alerts"
        echo "  report      - Generate and send daily traffic report"  
        echo "  reset       - Reset monthly traffic statistics"
        echo "  test-alerts - Test notification systems"
        echo ""
        echo "Add to crontab for automated monitoring:"
        echo "  # Check every hour"
        echo "  0 * * * * /path/to/traffic-monitor.sh monitor"
        echo "  # Daily report at 9 AM"
        echo "  0 9 * * * /path/to/traffic-monitor.sh report"
        echo "  # Monthly reset on 1st day at midnight"
        echo "  0 0 1 * * /path/to/traffic-monitor.sh reset"
        exit 1
        ;;
esac