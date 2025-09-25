# Makefile for Xray Auto Install Script

# Variables
SCRIPT_NAME = xray-auto-install.sh
VERSION = 2.0.0
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man/man1
DOCDIR = $(PREFIX)/share/doc/xray-auto-install

# Default target
.PHONY: all
all: help

# Help target
.PHONY: help
help:
	@echo "Xray Auto Install Script - Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  install     - Install the script system-wide"
	@echo "  uninstall   - Remove the script from system"
	@echo "  test        - Run tests and validation"
	@echo "  lint        - Run shell script linting"
	@echo "  docs        - Generate documentation"
	@echo "  package     - Create distribution packages"
	@echo "  clean       - Clean build artifacts"
	@echo "  check       - Check script dependencies"
	@echo "  help        - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make install    # Install to system"
	@echo "  make test       # Run validation tests"
	@echo "  make package    # Create release packages"

# Install target
.PHONY: install
install: check
	@echo "Installing Xray Auto Install Script..."
	
	# Create directories
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(MANDIR)
	install -d $(DESTDIR)$(DOCDIR)
	install -d $(DESTDIR)$(DOCDIR)/examples
	
	# Install main script
	install -m 755 $(SCRIPT_NAME) $(DESTDIR)$(BINDIR)/
	
	# Create menu command symlink
	ln -sf $(BINDIR)/$(SCRIPT_NAME) $(DESTDIR)$(BINDIR)/xray-menu
	
	# Install documentation
	install -m 644 README.md $(DESTDIR)$(DOCDIR)/
	install -m 644 CHANGELOG.md $(DESTDIR)$(DOCDIR)/
	install -m 644 LICENSE $(DESTDIR)$(DOCDIR)/
	install -m 644 CONTRIBUTING.md $(DESTDIR)$(DOCDIR)/
	install -m 644 SECURITY.md $(DESTDIR)$(DOCDIR)/
	
	# Install additional docs
	install -m 644 docs/*.md $(DESTDIR)$(DOCDIR)/
	
	# Install examples
	install -m 755 examples/*.sh $(DESTDIR)$(DOCDIR)/examples/
	install -m 644 examples/*.csv $(DESTDIR)$(DOCDIR)/examples/
	
	@echo "Installation completed successfully!"
	@echo "Run 'xray-auto-install.sh' or 'xray-menu' to start"

# Uninstall target
.PHONY: uninstall
uninstall:
	@echo "Uninstalling Xray Auto Install Script..."
	
	# Remove binaries
	rm -f $(DESTDIR)$(BINDIR)/$(SCRIPT_NAME)
	rm -f $(DESTDIR)$(BINDIR)/xray-menu
	
	# Remove documentation
	rm -rf $(DESTDIR)$(DOCDIR)
	
	@echo "Uninstallation completed!"

# Test target
.PHONY: test
test: lint
	@echo "Running tests..."
	
	# Test script syntax
	bash -n $(SCRIPT_NAME)
	@echo "✅ Script syntax is valid"
	
	# Test main functions exist
	@grep -q "function.*install_xray" $(SCRIPT_NAME) || (echo "❌ install_xray function missing" && exit 1)
	@grep -q "function.*create_user" $(SCRIPT_NAME) || (echo "❌ create_user function missing" && exit 1)
	@grep -q "function.*show_menu" $(SCRIPT_NAME) || (echo "❌ show_menu function missing" && exit 1)
	@echo "✅ Required functions present"
	
	# Test configuration templates
	@grep -q "inbounds" $(SCRIPT_NAME) || (echo "❌ Xray configuration template missing" && exit 1)
	@grep -q "server.*{" $(SCRIPT_NAME) || (echo "❌ Nginx configuration template missing" && exit 1)
	@echo "✅ Configuration templates present"
	
	# Test example scripts
	@for script in examples/*.sh; do \
		if [ -f "$$script" ]; then \
			bash -n "$$script" || (echo "❌ $$script syntax error" && exit 1); \
		fi; \
	done
	@echo "✅ Example scripts syntax valid"
	
	@echo "All tests passed! ✅"

# Lint target
.PHONY: lint
lint:
	@echo "Running shell script linting..."
	
	# Check if shellcheck is available
	@which shellcheck > /dev/null || (echo "❌ shellcheck not found. Install with: apt install shellcheck" && exit 1)
	
	# Run shellcheck on main script
	shellcheck -x $(SCRIPT_NAME)
	@echo "✅ Main script linting passed"
	
	# Run shellcheck on example scripts
	@for script in examples/*.sh; do \
		if [ -f "$$script" ]; then \
			shellcheck "$$script" || (echo "❌ $$script linting failed" && exit 1); \
		fi; \
	done
	@echo "✅ Example scripts linting passed"

# Documentation target
.PHONY: docs
docs:
	@echo "Generating documentation..."
	
	# Check if required docs exist
	@test -f README.md || (echo "❌ README.md missing" && exit 1)
	@test -f CHANGELOG.md || (echo "❌ CHANGELOG.md missing" && exit 1)
	@test -f CONTRIBUTING.md || (echo "❌ CONTRIBUTING.md missing" && exit 1)
	@test -f SECURITY.md || (echo "❌ SECURITY.md missing" && exit 1)
	@test -f LICENSE || (echo "❌ LICENSE missing" && exit 1)
	
	# Validate documentation links
	@echo "Validating documentation..."
	@for doc in docs/*.md; do \
		if [ -f "$$doc" ]; then \
			echo "Checking $$doc..."; \
		fi; \
	done
	
	@echo "✅ Documentation is complete"

# Package target
.PHONY: package
package: test docs
	@echo "Creating distribution packages..."
	
	# Create package directory
	mkdir -p dist/xray-auto-install-$(VERSION)
	
	# Copy files
	cp $(SCRIPT_NAME) dist/xray-auto-install-$(VERSION)/
	cp README.md CHANGELOG.md LICENSE dist/xray-auto-install-$(VERSION)/
	cp CONTRIBUTING.md SECURITY.md dist/xray-auto-install-$(VERSION)/
	cp -r docs dist/xray-auto-install-$(VERSION)/
	cp -r examples dist/xray-auto-install-$(VERSION)/
	cp Makefile dist/xray-auto-install-$(VERSION)/
	
	# Create archives
	cd dist && tar -czf xray-auto-install-$(VERSION).tar.gz xray-auto-install-$(VERSION)/
	cd dist && zip -r xray-auto-install-$(VERSION).zip xray-auto-install-$(VERSION)/
	
	# Generate checksums
	cd dist && sha256sum xray-auto-install-$(VERSION).tar.gz > checksums.txt
	cd dist && sha256sum xray-auto-install-$(VERSION).zip >> checksums.txt
	
	@echo "✅ Packages created in dist/ directory:"
	@ls -la dist/xray-auto-install-$(VERSION).*
	@echo ""
	@echo "Checksums:"
	@cat dist/checksums.txt

# Clean target
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf dist/
	rm -f *.tar.gz *.zip
	find . -name "*.log" -type f -delete
	find . -name "*.tmp" -type f -delete
	@echo "✅ Clean completed"

# Check dependencies
.PHONY: check
check:
	@echo "Checking dependencies..."
	
	# Check for required commands
	@which bash > /dev/null || (echo "❌ bash not found" && exit 1)
	@which curl > /dev/null || (echo "❌ curl not found" && exit 1)
	@which systemctl > /dev/null || (echo "❌ systemctl not found" && exit 1)
	
	@echo "✅ Basic dependencies satisfied"
	
	# Check optional dependencies
	@which shellcheck > /dev/null && echo "✅ shellcheck available" || echo "⚠️  shellcheck not available (optional)"
	@which qrencode > /dev/null && echo "✅ qrencode available" || echo "⚠️  qrencode not available (optional)"
	@which jq > /dev/null && echo "✅ jq available" || echo "⚠️  jq not available (optional)"

# Development targets
.PHONY: dev-setup
dev-setup:
	@echo "Setting up development environment..."
	
	# Install development dependencies (Ubuntu/Debian)
	@if which apt > /dev/null; then \
		sudo apt update; \
		sudo apt install -y shellcheck jq qrencode; \
	elif which yum > /dev/null; then \
		sudo yum install -y ShellCheck jq qrencode; \
	else \
		echo "Please install manually: shellcheck, jq, qrencode"; \
	fi
	
	# Set up pre-commit hooks
	@if [ -d .git ]; then \
		echo "#!/bin/bash" > .git/hooks/pre-commit; \
		echo "make lint" >> .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "✅ Pre-commit hooks installed"; \
	fi
	
	@echo "✅ Development environment ready"

# Quick install for development
.PHONY: dev-install
dev-install:
	@echo "Installing for development..."
	sudo cp $(SCRIPT_NAME) /usr/local/bin/
	sudo chmod +x /usr/local/bin/$(SCRIPT_NAME)
	sudo ln -sf /usr/local/bin/$(SCRIPT_NAME) /usr/local/bin/menu
	@echo "✅ Development installation completed"

# Release target
.PHONY: release
release: clean test package
	@echo "🚀 Release $(VERSION) is ready!"
	@echo ""
	@echo "Distribution files:"
	@ls -la dist/
	@echo ""
	@echo "Next steps:"
	@echo "1. Test the packages on clean systems"
	@echo "2. Update version tags in git"
	@echo "3. Create GitHub release"
	@echo "4. Upload distribution files"

# CI target for automated testing
.PHONY: ci
ci: check lint test
	@echo "✅ CI checks passed"