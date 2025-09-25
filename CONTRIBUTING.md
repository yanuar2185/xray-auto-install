# Contributing to Xray Auto-Install Script

Terima kasih atas minat Anda untuk berkontribusi pada proyek Xray Auto-Install Script! Kontribusi dari komunitas sangat berharga untuk meningkatkan kualitas dan fitur script ini.

## 🎯 Cara Berkontribusi

### 1. Reporting Issues
Jika Anda menemukan bug atau masalah:
- Buka [GitHub Issues](https://github.com/yourusername/xray-auto-install/issues)
- Gunakan template issue yang sesuai
- Berikan informasi yang lengkap:
  - OS dan versi
  - Langkah-langkah untuk reproduce
  - Log error yang relevan
  - Expected vs actual behavior

### 2. Feature Requests
Untuk request fitur baru:
- Buka [GitHub Discussions](https://github.com/yourusername/xray-auto-install/discussions)
- Jelaskan use case dan benefit fitur tersebut
- Berikan contoh implementasi jika memungkinkan

### 3. Code Contributions
#### Fork & Clone
```bash
# Fork repository di GitHub, kemudian clone
git clone https://github.com/yourusername/xray-auto-install.git
cd xray-auto-install

# Add upstream remote
git remote add upstream https://github.com/originaluser/xray-auto-install.git
```

#### Create Feature Branch
```bash
# Update master branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
```

#### Development Guidelines
```bash
# Test script pada clean environment
# Gunakan VM atau container untuk testing

# Test multiple OS
- Ubuntu 20.04/22.04
- Debian 10/11
- CentOS 7/8

# Test different scenarios
- Fresh install
- Upgrade from previous version
- Different SSL configurations
```

## 📝 Coding Standards

### Bash Script Standards
```bash
# Gunakan set untuk error handling
set -euo pipefail

# Function naming: snake_case
function_name() {
    local var_name="value"
}

# Variable naming: UPPER_CASE untuk global, lower_case untuk local
GLOBAL_VAR="value"
local_var="value"

# Always quote variables
if [[ "$variable" == "value" ]]; then
    echo "Quoted variables"
fi

# Use meaningful function names
check_root_privileges() {
    # Clear and descriptive
}
```

### Documentation Standards
```bash
# Document functions
# Function: install_xray
# Purpose: Install Xray core with advanced configuration
# Parameters: None
# Returns: 0 on success, 1 on failure
install_xray() {
    # Implementation
}

# Comment complex logic
# Check if domain resolves to server IP
domain_ip=$(dig +short "$domain" @8.8.8.8 2>/dev/null | tail -1)
if [[ "$domain_ip" == "$server_ip" ]]; then
    # Domain correctly points to this server
fi
```

### Error Handling
```bash
# Always handle errors
if ! command_that_might_fail; then
    print_error "Command failed"
    return 1
fi

# Use trap for cleanup
cleanup() {
    rm -f /tmp/temporary-file
}
trap cleanup EXIT

# Validate inputs
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]]; then
        print_error "Invalid domain format"
        return 1
    fi
}
```

## 🧪 Testing

### Manual Testing Checklist
```bash
# Fresh Installation
□ Ubuntu 20.04 fresh install
□ Ubuntu 22.04 fresh install  
□ Debian 10 fresh install
□ Debian 11 fresh install
□ CentOS 7 fresh install

# SSL Configurations
□ Let's Encrypt with valid domain
□ Let's Encrypt with invalid domain (should fallback)
□ Self-signed certificate
□ HTTP only mode

# User Management
□ Add user with different expiry options
□ Add user with different traffic limits
□ Delete user
□ Generate user configuration
□ User configuration works in client

# Menu System
□ All menu options work
□ Error handling for invalid inputs
□ Navigation between menus
□ Exit functionality

# Service Management
□ Start/stop/restart services
□ Service auto-start after reboot
□ Log viewing functionality
□ Status monitoring

# Network Features
□ BBR optimization works
□ DNS management functions
□ Speed test functionality
□ Firewall configuration
```

### Automated Testing (Future)
```bash
# Unit tests for functions
test_validate_domain() {
    # Test valid domains
    validate_domain "example.com" || fail "Valid domain failed"
    
    # Test invalid domains
    ! validate_domain "invalid..domain" || fail "Invalid domain passed"
}

# Integration tests
test_fresh_install() {
    # Test complete installation process
}
```

## 📋 Pull Request Process

### Before Submitting
1. **Test thoroughly** pada multiple OS
2. **Update documentation** jika diperlukan
3. **Follow coding standards**
4. **Add comments** untuk logic yang complex
5. **Ensure backward compatibility**

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Ubuntu 20.04
- [ ] Tested on Debian 11
- [ ] Tested fresh installation
- [ ] Tested upgrade scenario

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process
1. **Automated checks** akan berjalan
2. **Maintainer review** kode dan testing
3. **Community feedback** jika diperlukan
4. **Merge** setelah approval

## 🎨 Development Areas

### High Priority
- **Windows support** (WSL/native)
- **Web dashboard** interface
- **API endpoints** untuk automation
- **Docker containerization**
- **Automated testing** framework

### Medium Priority
- **Additional protocols** (Shadowsocks, etc)
- **Load balancing** features
- **Advanced routing** rules
- **Monitoring dashboard** improvements
- **Mobile app** integration

### Nice to Have
- **Multi-server management**
- **CDN integration**
- **Advanced analytics**
- **Custom branding** options
- **Plugin system**

## 🏆 Recognition

### Contributors
Semua contributor akan:
- **Listed** dalam README.md
- **Credited** dalam release notes
- **Invited** to contributor team (untuk regular contributors)

### Hall of Fame
Special recognition untuk:
- **First-time contributors**
- **Major feature contributors**  
- **Bug hunters**
- **Documentation improvers**

## 📞 Getting Help

### Development Support
- **Discord**: [Join our dev channel](https://discord.gg/xray-auto-install)
- **GitHub Discussions**: Untuk pertanyaan development
- **Email**: dev@yourdomain.com untuk private inquiries

### Mentorship Program
New contributors bisa mendapat:
- **Code review** yang detailed
- **Pair programming** sessions
- **Guidance** untuk first contribution
- **Best practices** sharing

## 🎉 Appreciation

Terima kasih kepada semua contributor yang telah membantu:
- **Bug reports** dan **feature requests**
- **Code contributions** dan **improvements**
- **Documentation** dan **translations**
- **Testing** dan **feedback**

Your contributions make this project better for everyone! 🚀

---

**Happy Contributing!** 🎯

*"The best way to predict the future is to create it."* - Peter Drucker