# Project Structure

This document provides a comprehensive overview of the Xray Auto Install Script project structure and organization.

## Repository Structure

```
xray-auto-install/
├── README.md                              # Main project documentation
├── CHANGELOG.md                          # Version history and changes
├── LICENSE                               # MIT license file
├── CONTRIBUTING.md                       # Contribution guidelines
├── SECURITY.md                          # Security policy and reporting
├── Makefile                             # Build system and automation
├── .gitignore                           # Git ignore patterns
├── xray-auto-install.sh                 # Main installation script
│
├── .github/                             # GitHub configuration
│   ├── ISSUE_TEMPLATE/                  # Issue templates
│   │   ├── bug_report.yml              # Bug report template
│   │   ├── feature_request.yml         # Feature request template
│   │   └── config.yml                  # Issue template configuration
│   ├── workflows/                       # GitHub Actions workflows
│   │   ├── ci.yml                      # Continuous integration
│   │   └── release.yml                 # Release automation
│   └── pull_request_template.md        # Pull request template
│
├── docs/                               # Documentation
│   ├── installation.md                # Detailed installation guide
│   ├── api.md                         # API documentation
│   └── troubleshooting.md             # Troubleshooting guide
│
└── examples/                           # Example scripts and configurations
    ├── batch-create-users.sh          # Batch user creation script
    ├── traffic-monitor.sh             # Traffic monitoring script
    └── users.csv                      # Sample user data
```

## File Descriptions

### Core Files

#### `xray-auto-install.sh`
The main installation and management script containing:
- **Installation Functions**: System detection, package installation, service setup
- **User Management**: Create, delete, list, and manage users
- **SSL Management**: Let's Encrypt integration, certificate handling
- **Traffic Monitoring**: User traffic tracking and statistics
- **Network Optimization**: BBR setup, system tuning
- **Configuration Management**: Xray and Nginx configuration
- **Menu System**: Interactive command-line interface

**Key Features:**
- Multi-protocol support (VMess, VLESS, Trojan)
- Automatic SSL certificate management
- WebSocket support with reverse proxy
- User expiry and traffic limits
- Real-time traffic monitoring
- Global menu command (`menu`)

### Documentation

#### `README.md`
Comprehensive project overview including:
- Feature highlights and capabilities
- Quick installation instructions
- Usage examples and configuration
- Client setup guides
- Troubleshooting section
- API reference

#### `CHANGELOG.md`
Detailed version history with:
- New features and enhancements
- Bug fixes and improvements
- Breaking changes and migrations
- Security updates

#### `CONTRIBUTING.md`
Development guidelines covering:
- Code style and standards
- Testing requirements
- Pull request process
- Development environment setup
- Issue reporting guidelines

#### `SECURITY.md`
Security policy including:
- Vulnerability reporting process
- Security best practices
- Supported versions
- Response timelines
- Contact information

### GitHub Integration

#### `.github/ISSUE_TEMPLATE/`
Structured issue templates for:
- **Bug Reports**: System info, reproduction steps, logs
- **Feature Requests**: Use cases, implementation details
- **Configuration**: Community guidelines, contact links

#### `.github/workflows/`
Automated workflows for:
- **CI Pipeline**: Code linting, syntax checking, security scans
- **Release Automation**: Package creation, asset uploads

### Documentation (`docs/`)

#### `installation.md`
Comprehensive installation guide covering:
- System requirements and prerequisites
- Step-by-step installation process
- Custom installation options
- Post-installation configuration
- Advanced setup scenarios

#### `api.md`
Complete API documentation including:
- Function reference and parameters
- Response formats and error codes
- Usage examples and best practices
- Batch operations and automation
- Integration guidelines

#### `troubleshooting.md`
Detailed troubleshooting guide with:
- Common issues and solutions
- Log analysis and debugging
- Performance optimization
- Network and firewall issues
- Recovery procedures

### Examples (`examples/`)

#### `batch-create-users.sh`
Advanced script for bulk user management:
- CSV-based user import
- Automated configuration generation
- Email notifications
- QR code generation
- Logging and error handling

#### `traffic-monitor.sh`
Comprehensive traffic monitoring system:
- Real-time usage tracking
- Alert notifications (Email/Telegram)
- Automatic user suspension
- Traffic reporting and analytics
- Monthly statistics reset

#### `users.csv`
Sample data file for batch operations with:
- User account information
- Expiry dates and traffic limits
- Email addresses for notifications
- Various user types (trial, regular, VIP)

### Build System

#### `Makefile`
Complete build automation with targets for:
- **Installation**: System-wide deployment
- **Testing**: Syntax validation, function checks
- **Linting**: Code quality verification
- **Packaging**: Distribution archive creation
- **Documentation**: Validation and generation
- **Development**: Environment setup, dev tools

#### `.gitignore`
Comprehensive ignore patterns for:
- Build artifacts and temporary files
- Runtime configuration and logs
- SSL certificates and keys
- User data and statistics
- System-generated files

## Directory Structure (Runtime)

When installed, the script creates the following directory structure:

```
System Directories:
├── /usr/local/etc/xray/           # Xray configuration
├── /var/log/xray/                 # Xray logs
├── /var/xray-stats/               # Traffic statistics
├── /etc/xray-ssl/                 # SSL certificates
├── /etc/nginx/sites-available/    # Nginx configurations
├── /etc/systemd/system/           # Service files
└── /root/                         # Management files
    ├── xray-users.db             # User database
    ├── xray-ports.conf           # Port configuration
    ├── xray-domain.conf          # Domain settings
    └── xray-backups/             # Configuration backups
```

## Configuration Files

### Xray Configuration
- **Location**: `/usr/local/etc/xray/config.json`
- **Purpose**: Main Xray server configuration
- **Contains**: Inbound/outbound rules, routing, logging

### Nginx Configuration
- **Location**: `/etc/nginx/sites-available/xray-*`
- **Purpose**: Reverse proxy and SSL termination
- **Contains**: Server blocks, WebSocket proxying, SSL settings

### User Database
- **Location**: `/root/xray-users.db`
- **Format**: `username:uuid:expiry:limit:status`
- **Purpose**: User account management and tracking

### Port Configuration
- **Location**: `/root/xray-ports.conf`
- **Format**: Environment variables
- **Purpose**: Port assignments and consistency

## Development Workflow

### Local Development
1. Clone repository
2. Run `make dev-setup` to install dependencies
3. Use `make lint` for code quality checks
4. Run `make test` for validation
5. Use `make dev-install` for testing

### Testing Process
1. **Syntax Validation**: Bash syntax checking
2. **Function Testing**: Required function presence
3. **Template Validation**: Configuration template checks
4. **Linting**: ShellCheck code analysis
5. **Integration Testing**: Full installation testing

### Release Process
1. Update version numbers
2. Update CHANGELOG.md
3. Run `make release` for packaging
4. Create GitHub release
5. Upload distribution files

## Security Considerations

### File Permissions
- Scripts: `755` (executable)
- Configuration: `644` (readable)
- Sensitive data: `600` (owner only)
- SSL certificates: `600` (secure)

### Data Protection
- User database encryption (optional)
- SSL certificate security
- Log file rotation and cleanup
- Backup file encryption

### Network Security
- Firewall rule management
- Port security and configuration
- SSL/TLS best practices
- DDoS protection measures

## Maintenance

### Regular Tasks
- Certificate renewal monitoring
- User account cleanup
- Log file rotation
- Traffic statistics archival
- Security updates

### Monitoring
- Service health checks
- Resource usage monitoring
- Error log analysis
- Performance metrics

### Backup Strategy
- Configuration backup automation
- User data export procedures
- SSL certificate backup
- Recovery testing procedures

## Integration Points

### External Services
- **Let's Encrypt**: SSL certificate automation
- **DNS Providers**: Domain validation
- **Email Services**: Notification delivery
- **Telegram**: Alert messaging
- **Monitoring Systems**: Health checks

### Client Applications
- **v2rayNG** (Android)
- **Shadowrocket** (iOS)
- **v2rayN** (Windows)
- **V2rayU** (macOS)
- **Qv2ray** (Linux/Cross-platform)

---

This project structure ensures maintainability, scalability, and ease of use while following best practices for open-source software development.