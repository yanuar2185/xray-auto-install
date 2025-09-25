# Changelog

All notable changes to the Xray Auto Install Script will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2024-12-25

### Added
- Complete rewrite with advanced features
- Multi-protocol support (VMess, VLESS, Trojan)
- Automatic SSL certificate management with Let's Encrypt
- Nginx reverse proxy integration
- BBR network optimization
- DNS management with multiple providers (Cloudflare, Google, Quad9)
- User management system with expiry dates
- Traffic monitoring and statistics
- Global menu command accessible from anywhere
- Domain input during installation process
- Comprehensive backup and restore functionality
- User database with traffic limits
- WebSocket support for all protocols
- Real-time traffic monitoring
- Automated certificate renewal
- Self-signed certificate fallback
- Professional logging system

### Enhanced
- Error handling and validation
- User interface with colored output
- Configuration management
- Security hardening
- Performance optimizations

### Fixed
- Port configuration consistency between Xray and Nginx
- WebSocket path standardization across all protocols
- User database file consistency
- Client configuration generation accuracy
- SSL certificate handling
- Domain validation and DNS checks

### Security
- Improved SSL/TLS configuration
- Enhanced firewall rules
- Better certificate validation
- Secure user authentication

## [1.0.0] - 2024-01-01

### Added
- Initial release
- Basic Xray installation
- Simple user management
- Basic SSL support
- Manual configuration options

### Features
- Single protocol support (VMess)
- Basic user creation and deletion
- Manual SSL certificate setup
- Simple installation process