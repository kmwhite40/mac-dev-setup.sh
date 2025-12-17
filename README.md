# SBS Federal - macOS Automation & Compliance Tools

Enterprise-grade macOS management tools for automated deployment, configuration, and security compliance.

---

## 📦 Available Packages

### 1. Mac Dev Setup
**Automated development environment setup with comprehensive tooling**

- 🛠️ Installs 14 GUI applications (Docker, VS Code, Cursor, IntelliJ, etc.)
- 💻 Installs 21 CLI tools (git, kubectl, terraform, AWS/Azure/GCP CLIs, etc.)
- 🔄 Automatic system updates every 4 days
- 🎨 Creates desktop shortcuts for quick access
- 📝 Comprehensive logging and error handling
- ⚙️ Intune-ready deployment package

**[View Documentation →](packages/mac-dev-setup/)**

### 2. NIST 800-53 Compliance Scanner
**Automated security compliance scanning with detailed reporting**

- 🔒 Scans 25+ NIST 800-53 security controls
- 📊 Generates beautiful HTML compliance reports
- 📈 Exports JSON for SIEM/GRC integration
- ✅ Color-coded pass/fail/warning indicators
- 💡 Actionable remediation recommendations
- ⏰ Optional weekly automated scanning

**[View Documentation →](packages/compliance-scanner/)**

---

## 🚀 Quick Start

### For Individual Use

```bash
# Mac Dev Setup
cd packages/mac-dev-setup/scripts/
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh

# Compliance Scanner
cd packages/compliance-scanner/scripts/
chmod +x nist-800-53-scanner.sh
./nist-800-53-scanner.sh
```

### For Intune Deployment

```bash
# Build Mac Dev Setup package
cd packages/mac-dev-setup/intune/
./build-package.sh

# Build Compliance Scanner package
cd packages/compliance-scanner/intune/
./build-package.sh

# Convert to .intunemac and upload to Intune
# See deployment guides in each package
```

---

## 📁 Repository Structure

```
.
├── README.md                          # This file
│
├── docs/                              # General documentation
│   ├── INDEX.md                       # Documentation index
│   ├── QUICK_START.md                 # Quick start guide
│   ├── COMPLETE-SUMMARY.md            # Complete project overview
│   ├── OPERATIONS.md                  # Technical operations guide
│   ├── TROUBLESHOOTING.md             # Troubleshooting guide
│   ├── PROJECT_STRUCTURE.md           # Repository structure
│   └── README.md                      # Original documentation
│
└── packages/                          # Application packages
    │
    ├── mac-dev-setup/                 # Mac Dev Setup Package
    │   ├── scripts/
    │   │   └── mac-dev-setup.sh       # Main setup script
    │   ├── intune/                    # Intune deployment files
    │   │   ├── install.sh
    │   │   ├── uninstall.sh
    │   │   ├── detection.sh
    │   │   ├── preinstall.sh
    │   │   ├── postinstall.sh
    │   │   ├── build-package.sh
    │   │   ├── package-info.json
    │   │   ├── README-INTUNE.md
    │   │   ├── INTUNE-QUICK-START.md
    │   │   ├── INTUNE-UPLOAD-GUIDE.md
    │   │   └── DEPLOYMENT-CHECKLIST.md
    │   └── docs/                      # Package documentation
    │
    └── compliance-scanner/            # Compliance Scanner Package
        ├── scripts/
        │   └── nist-800-53-scanner.sh # Main scanner script
        ├── intune/                    # Intune deployment files
        │   ├── install.sh
        │   ├── uninstall.sh
        │   ├── detection.sh
        │   ├── preinstall.sh
        │   ├── postinstall.sh
        │   ├── build-package.sh
        │   └── package-info.json
        └── docs/                      # Package documentation
            └── README.md
```

---

## 🎯 Package Comparison

| Feature | Mac Dev Setup | Compliance Scanner |
|---------|--------------|-------------------|
| **Purpose** | Development environment setup | Security compliance scanning |
| **Target Users** | Developers, Engineers | Security, Compliance, IT |
| **Installation Time** | 45-90 minutes | 30-60 seconds |
| **Requires Admin** | Yes (for system updates) | No (for scanning) |
| **Intune Ready** | ✅ Yes | ✅ Yes |
| **Auto-Updates** | Every 4 days | On-demand |
| **Report Output** | Terminal logs | HTML + JSON reports |
| **Applications** | 35 total | System scan only |
| **Command** | `mac-dev-setup` | `compliance-scan` |

---

## 🏢 Company Configuration

Both packages are pre-configured for **SBS Federal**:

- **Company Name:** SBS Federal
- **IT Support:** it@sbsfederal.com
- **Update Interval:** 4 days (Mac Dev Setup)
- **Branding:** SBS Federal colors and logo

---

## 📚 Documentation

### General Documentation
- **[Documentation Index](docs/INDEX.md)** - Central navigation
- **[Quick Start Guide](docs/QUICK_START.md)** - Get started in 5 minutes
- **[Complete Summary](docs/COMPLETE-SUMMARY.md)** - Full project overview
- **[Operations Guide](docs/OPERATIONS.md)** - Technical execution details
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Problem solving

### Package-Specific Documentation
- **[Mac Dev Setup Intune Guide](packages/mac-dev-setup/intune/README-INTUNE.md)**
- **[Mac Dev Setup Quick Start](packages/mac-dev-setup/intune/INTUNE-QUICK-START.md)**
- **[Mac Dev Setup Deployment Checklist](packages/mac-dev-setup/intune/DEPLOYMENT-CHECKLIST.md)**
- **[Compliance Scanner Guide](packages/compliance-scanner/docs/README.md)**

---

## 🔧 Installation Methods

### Method 1: Intune Company Portal (Recommended)
1. Build package with `build-package.sh`
2. Convert to .intunemac format
3. Upload to Intune
4. Users install from Company Portal
5. Run commands: `mac-dev-setup` or `compliance-scan`

### Method 2: Direct Script Execution
1. Clone this repository
2. Navigate to package scripts directory
3. Make executable: `chmod +x *.sh`
4. Run script: `./script-name.sh`

### Method 3: Manual Download
1. Download script from GitHub
2. Make executable
3. Run locally

---

## 🎓 Training & Support

### For End Users
- **Mac Dev Setup:** Run `mac-dev-setup` and follow prompts
- **Compliance Scanner:** Run `compliance-scan` and view HTML report
- **Help:** Contact it@sbsfederal.com

### For IT Administrators
- Review Intune deployment guides in each package
- Follow deployment checklists for production rollout
- Monitor via Intune console and log files
- Customize company settings in install.sh files

### For Developers
- Clone repository for local development
- Modify scripts in `packages/*/scripts/` directories
- Test locally before building packages
- Update version numbers in package-info.json

---

## 🔐 Security & Compliance

### Mac Dev Setup
- ✅ Installs from official Homebrew repositories
- ✅ Verifies package signatures
- ✅ Comprehensive logging for audit trail
- ✅ Individual error handling
- ✅ No credential storage

### Compliance Scanner
- ✅ Read-only system checks
- ✅ No system modifications
- ✅ No external data transmission
- ✅ Local report storage only
- ✅ NIST 800-53 control coverage
- ✅ Audit-ready JSON exports

---

## 📊 Deployment Statistics

### Mac Dev Setup
- **Applications:** 14 GUI + 21 CLI = 35 total
- **Install Time:** 45-90 minutes (first run)
- **Update Time:** 5-15 minutes (subsequent)
- **Disk Space:** ~30 GB required
- **Script Size:** 8.6 KB
- **Package Size:** ~60 KB

### Compliance Scanner
- **Controls Checked:** 25+ NIST 800-53 controls
- **Scan Time:** 30-60 seconds
- **Report Size:** ~500 KB (HTML + JSON)
- **Disk Space:** 1 GB required
- **Script Size:** 1,100+ lines
- **Package Size:** ~50 KB

---

## 🛠️ Development

### Requirements
- macOS 10.15 (Catalina) or later
- Bash 3.2+
- Internet connection (for Mac Dev Setup)
- Optional: Xcode Command Line Tools

### Build Process
```bash
# Navigate to package intune directory
cd packages/[package-name]/intune/

# Build .pkg installer
./build-package.sh

# Convert for Intune (requires IntuneAppUtil)
./IntuneAppUtil -c PackageName-1.0.0.pkg -o . -i com.sbsfederal.packageid -n 1.0.0

# Output: PackageName-1.0.0.intunemac
```

### Testing
```bash
# Test package installation
sudo installer -pkg PackageName-1.0.0.pkg -target /

# Test detection
./detection.sh
echo $?  # Should return 0

# Test execution
mac-dev-setup
# or
compliance-scan

# Test uninstallation
sudo ./uninstall.sh
```

---

## 📈 Roadmap

### Planned Features
- [ ] Additional compliance frameworks (CIS, PCI-DSS, HIPAA)
- [ ] Automated remediation for compliance failures
- [ ] Integration with ServiceNow/Jira
- [ ] Real-time compliance monitoring
- [ ] Custom control definition support
- [ ] Multi-language support
- [ ] Dark mode for HTML reports
- [ ] PDF export option

### Under Consideration
- [ ] Windows compatibility (PowerShell version)
- [ ] Linux support
- [ ] Mobile app for report viewing
- [ ] Slack/Teams notifications
- [ ] REST API for remote scanning

---

## 🤝 Contributing

This is an internal SBS Federal repository. For contributions:

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Update documentation
5. Submit for review

---

## 📞 Support

### Internal Support
- **Email:** it@sbsfederal.com
- **Documentation:** This repository
- **Logs:**
  - Mac Dev Setup: `~/.mac-dev-setup.log`
  - Compliance Scanner: `~/.compliance-scanner/scanner.log`

### External Resources
- **NIST 800-53:** https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- **Homebrew Docs:** https://docs.brew.sh/
- **Intune Docs:** https://docs.microsoft.com/mem/intune/
- **macOS Security:** https://support.apple.com/guide/deployment/

---

## 📄 License

Internal use only - SBS Federal
Confidential and Proprietary

---

## 🎉 Quick Commands Reference

```bash
# Mac Dev Setup
cd packages/mac-dev-setup/scripts/
./mac-dev-setup.sh                    # Run setup
tail -f ~/.mac-dev-setup.log         # View logs

# Compliance Scanner
cd packages/compliance-scanner/scripts/
./nist-800-53-scanner.sh             # Run scan
open ~/.compliance-scanner/reports/*.html  # View report

# Build Packages
cd packages/*/intune/
./build-package.sh                   # Build installer

# Deploy to Intune
# See individual package README files
```

---

## 📊 Project Statistics

- **Total Files:** 28
- **Total Lines:** 8,000+
- **Documentation Pages:** 15
- **Scripts:** 13
- **Packages:** 2
- **Supported Controls:** 25+
- **Applications Installed:** 35

---

**Last Updated:** 2025-12-17
**Repository:** https://github.com/kmwhite40/mac-dev-setup.sh
**Company:** SBS Federal
**Version:** 2.0.0 (Mac Dev Setup), 1.0.0 (Compliance Scanner)

---

🤖 *Generated and maintained by Kevin White
