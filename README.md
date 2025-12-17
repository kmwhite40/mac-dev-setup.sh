# DevHelpDeskTools

**Enterprise IT Management & Compliance Tools for macOS and Windows**

Comprehensive suite of IT automation, deployment, and compliance tools designed for SBS Federal. Streamline endpoint management with automated installation, configuration, and security compliance scanning across macOS and Windows platforms.

---

## 🎯 Overview

DevHelpDeskTools provides IT administrators and help desk teams with powerful automation scripts for:

- **Automated Development Environment Setup** - Deploy complete dev toolchains in minutes
- **Microsoft 365 Deployment** - Streamlined M365 suite installation
- **NIST 800-53 Compliance Scanning** - Automated security compliance verification
- **Intune Integration** - Enterprise deployment via Microsoft Intune/Company Portal

**Platforms Supported:**
- macOS 10.14+ (Mojave and later)
- Windows 10/11 (Build 17763+)

---

## 📦 Available Packages

### macOS Packages

#### 1. Mac Dev Setup
**Automated development environment setup with comprehensive tooling**

- 🛠️ Installs 14 GUI applications (Docker, VS Code, Cursor, IntelliJ, etc.)
- 💻 Installs 21 CLI tools (git, kubectl, terraform, AWS/Azure/GCP CLIs, etc.)
- 🔄 Automatic system updates every 4 days
- 🎨 Creates desktop shortcuts for quick access
- 📝 Comprehensive logging and error handling
- ⚙️ Intune-ready deployment package

**[View Documentation →](packages/macos/mac-dev-setup/)**

#### 2. macOS Compliance Scanner
**Automated NIST 800-53 security compliance scanning**

- 🔒 Scans 25+ NIST 800-53 security controls
- 📊 Generates beautiful HTML compliance reports
- 📈 Exports JSON for SIEM/GRC integration
- ✅ Color-coded pass/fail/warning indicators
- 💡 Actionable remediation recommendations
- ⏰ Optional weekly automated scanning

**[View Documentation →](packages/macos/compliance-scanner/)**

#### 3. Microsoft 365 Installer (macOS)
**Automated Microsoft 365 suite installation**

- 📦 Installs Office Suite (Word, Excel, PowerPoint, Outlook, OneNote)
- 💬 Installs Teams, OneDrive, Edge, Company Portal
- ✅ Smart detection of existing installations
- 🎨 Desktop shortcuts creation
- 📝 Comprehensive logging
- ⚙️ Downloads from official Microsoft CDN

**[View Documentation →](packages/macos/m365-installer/)**

---

### Windows Packages

#### 1. Windows Dev Setup
**Automated development environment setup via Chocolatey**

- 🛠️ Installs VS Code, IntelliJ IDEA, Docker Desktop
- 💻 Installs Python, Node.js, Go, .NET, OpenJDK
- 🔄 Automatic Windows Updates every 4 days
- 🎨 Creates desktop shortcuts for quick access
- 📝 PowerShell-based with comprehensive logging
- ⚙️ Intune-ready deployment package

**[View Documentation →](packages/windows/windows-dev-setup/)**

#### 2. Windows Compliance Scanner
**Automated NIST 800-53 security compliance scanning**

- 🔒 Scans 16+ NIST 800-53 security controls for Windows
- 📊 Generates HTML compliance reports
- 📈 Exports JSON for SIEM integration
- ✅ Checks BitLocker, Firewall, Defender, Password Policy
- 💡 Detailed remediation recommendations
- 🔐 PowerShell-based security scanning

**[View Documentation →](packages/windows/windows-compliance-scanner/)**

#### 3. Microsoft 365 Installer (Windows)
**Automated Microsoft 365 suite installation**

- 📦 Installs Office 365 Suite via deployment tool
- 💬 Installs Teams, OneDrive, Edge, Company Portal
- ✅ Smart detection of existing installations
- 🎨 Desktop shortcuts creation
- 📝 Comprehensive logging
- ⚙️ Downloads from official Microsoft CDN

**[View Documentation →](packages/windows/windows-m365-installer/)**

---

## 🚀 Quick Start

### macOS Quick Start

```bash
# Mac Dev Setup
cd packages/macos/mac-dev-setup/scripts/
chmod +x mac-dev-setup.sh
./mac-dev-setup.sh

# macOS Compliance Scanner
cd packages/macos/compliance-scanner/scripts/
chmod +x nist-800-53-scanner.sh
./nist-800-53-scanner.sh

# M365 Installer (macOS)
cd packages/macos/m365-installer/scripts/
chmod +x m365-installer.sh
./m365-installer.sh
```

### Windows Quick Start

```powershell
# Windows Dev Setup (Run as Administrator)
cd packages\windows\windows-dev-setup\scripts\
powershell.exe -ExecutionPolicy Bypass -File windows-dev-setup.ps1

# Windows Compliance Scanner (Run as Administrator)
cd packages\windows\windows-compliance-scanner\scripts\
powershell.exe -ExecutionPolicy Bypass -File windows-compliance-scanner.ps1

# M365 Installer (Windows - Run as Administrator)
cd packages\windows\windows-m365-installer\scripts\
powershell.exe -ExecutionPolicy Bypass -File windows-m365-installer.ps1
```

---

## 📁 Repository Structure

```
DevHelpDeskTools/
├── README.md                          # This file
│
├── docs/                              # General documentation
│   ├── INDEX.md                       # Documentation index
│   ├── QUICK_START.md                 # Quick start guide
│   ├── COMPLETE-SUMMARY.md            # Complete project overview
│   ├── OPERATIONS.md                  # Technical operations guide
│   ├── TROUBLESHOOTING.md             # Troubleshooting guide
│   └── PROJECT_STRUCTURE.md           # Repository structure
│
└── packages/                          # Platform-specific packages
    │
    ├── macos/                         # macOS Packages
    │   │
    │   ├── mac-dev-setup/             # Mac Dev Setup Package
    │   │   ├── scripts/
    │   │   │   └── mac-dev-setup.sh   # Main setup script
    │   │   ├── intune/                # Intune deployment files
    │   │   │   ├── install.sh
    │   │   │   ├── uninstall.sh
    │   │   │   ├── detection.sh
    │   │   │   ├── build-package.sh
    │   │   │   └── package-info.json
    │   │   └── docs/                  # Package documentation
    │   │
    │   ├── compliance-scanner/        # Compliance Scanner Package
    │   │   ├── scripts/
    │   │   │   └── nist-800-53-scanner.sh
    │   │   ├── intune/                # Intune deployment files
    │   │   └── docs/                  # Package documentation
    │   │
    │   └── m365-installer/            # M365 Installer Package
    │       ├── scripts/
    │       │   └── m365-installer.sh
    │       ├── intune/                # Intune deployment files
    │       └── docs/                  # Package documentation
    │
    └── windows/                       # Windows Packages
        │
        ├── windows-dev-setup/         # Windows Dev Setup Package
        │   ├── scripts/
        │   │   └── windows-dev-setup.ps1
        │   ├── intune/                # Intune deployment files
        │   │   ├── install.ps1
        │   │   ├── uninstall.ps1
        │   │   ├── detection.ps1
        │   │   └── package-info.json
        │   └── docs/                  # Package documentation
        │
        ├── windows-compliance-scanner/ # Windows Compliance Scanner
        │   ├── scripts/
        │   │   └── windows-compliance-scanner.ps1
        │   ├── intune/                # Intune deployment files
        │   └── docs/                  # Package documentation
        │
        └── windows-m365-installer/    # Windows M365 Installer
            ├── scripts/
            │   └── windows-m365-installer.ps1
            ├── intune/                # Intune deployment files
            └── docs/                  # Package documentation
```

---

## 🎯 Package Comparison

| Feature | Dev Setup | M365 Installer | Compliance Scanner |
|---------|-----------|----------------|-------------------|
| **Purpose** | Development environment | M365 app deployment | Security compliance |
| **Target Users** | Developers, Engineers | All users | Security, IT |
| **macOS** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Windows** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Install Time** | 45-90 min (macOS)<br>30-60 min (Windows) | 20-45 min | 30-60 sec |
| **Requires Admin** | Yes | Yes | Yes (scanning) |
| **Intune Ready** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Auto-Updates** | Every 4 days | Manual | On-demand |
| **Report Output** | Terminal logs | Terminal logs | HTML + JSON |

---

## 🏢 Company Configuration

All packages are pre-configured for **SBS Federal**:

- **Company Name:** SBS Federal
- **IT Support:** it@sbsfederal.com
- **Update Interval:** 4 days (Dev Setup packages)
- **Branding:** SBS Federal colors and configuration

---

## 🔧 Installation Methods

### Method 1: Intune Company Portal (Recommended for Enterprise)

**macOS:**
```bash
cd packages/macos/[package-name]/intune/
./build-package.sh
# Upload to Intune, assign to groups
# Users install from Company Portal
```

**Windows:**
```powershell
cd packages\windows\[package-name]\intune\
# Follow Intune deployment guide in package docs
```

### Method 2: Direct Script Execution

**macOS:**
```bash
chmod +x packages/macos/[package-name]/scripts/*.sh
./packages/macos/[package-name]/scripts/script-name.sh
```

**Windows:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File packages\windows\[package-name]\scripts\script-name.ps1
```

### Method 3: Manual Download
1. Download specific script from GitHub
2. Make executable (macOS) or allow execution (Windows)
3. Run locally

---

## 📚 Documentation

### General Documentation
- **[Documentation Index](docs/INDEX.md)** - Central navigation
- **[Quick Start Guide](docs/QUICK_START.md)** - Get started in 5 minutes
- **[Complete Summary](docs/COMPLETE-SUMMARY.md)** - Full project overview
- **[Operations Guide](docs/OPERATIONS.md)** - Technical execution details
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Problem solving

### Package-Specific Documentation
- Each package contains detailed documentation in its `docs/` directory
- Intune deployment guides in each `intune/` directory
- README files with usage instructions and examples

---

## 🔐 Security & Compliance

### Development Environment Setup
- ✅ Installs from official repositories (Homebrew/Chocolatey)
- ✅ Verifies package signatures
- ✅ Comprehensive logging for audit trail
- ✅ No credential storage

### M365 Installer
- ✅ Downloads from official Microsoft CDN
- ✅ Package signature verification
- ✅ No credential handling
- ✅ Comprehensive logging

### Compliance Scanner
- ✅ Read-only system checks
- ✅ No system modifications
- ✅ No external data transmission
- ✅ Local report storage only
- ✅ NIST 800-53 control coverage
- ✅ Audit-ready JSON exports

---

## 📊 Deployment Statistics

### macOS Packages
- **Mac Dev Setup:** 35 applications, 45-90 min install, ~30GB disk space
- **M365 Installer:** 9 applications, 20-45 min install, ~10GB disk space
- **Compliance Scanner:** 25+ controls, 30-60 sec scan, ~1GB disk space

### Windows Packages
- **Windows Dev Setup:** 30+ applications, 30-60 min install, ~20GB disk space
- **Windows M365 Installer:** 9 applications, 20-45 min install, ~10GB disk space
- **Windows Compliance Scanner:** 16+ controls, 30-60 sec scan, ~500MB disk space

---

## 🎓 Training & Support

### For End Users
- **Dev Setup:** Run script and follow prompts, restart computer
- **M365 Installer:** Run script, sign in with SBS Federal credentials
- **Compliance Scanner:** Run scan, view HTML report in browser
- **Help:** Contact it@sbsfederal.com

### For IT Administrators
- Review Intune deployment guides in each package
- Follow deployment checklists for production rollout
- Monitor via Intune console and log files
- Customize company settings in installation scripts

### For Developers
- Clone repository for local development
- Modify scripts in `packages/*/scripts/` directories
- Test locally before building packages
- Update version numbers in package-info.json

---

## 🛠️ System Requirements

### macOS Requirements
- **OS:** macOS 10.14 (Mojave) or later
- **Disk Space:** 10-30 GB (varies by package)
- **RAM:** 4 GB minimum, 8 GB recommended
- **Internet:** Broadband connection required
- **Processor:** Intel or Apple Silicon

### Windows Requirements
- **OS:** Windows 10 Build 17763 or later
- **Disk Space:** 10-20 GB (varies by package)
- **RAM:** 4 GB minimum, 8 GB recommended
- **Internet:** Broadband connection required
- **Processor:** x64 architecture
- **Admin Rights:** Required for installation

---

## 📈 Roadmap

### Planned Features
- [ ] Linux support (Ubuntu, RHEL, Fedora)
- [ ] Additional compliance frameworks (CIS, PCI-DSS, HIPAA)
- [ ] Automated remediation for compliance failures
- [ ] Integration with ServiceNow/Jira ticketing
- [ ] Real-time compliance monitoring dashboard
- [ ] Custom control definition support
- [ ] Multi-language support (Spanish, French)
- [ ] PDF export for compliance reports

### Under Consideration
- [ ] Mobile app for report viewing
- [ ] Slack/Teams notification integration
- [ ] REST API for remote management
- [ ] Configuration drift detection
- [ ] Scheduled automated scans

---

## 🤝 Contributing

This is an internal SBS Federal repository. For contributions:

1. Create a feature branch from main
2. Make your changes with clear commit messages
3. Test thoroughly on both macOS and Windows (if applicable)
4. Update documentation
5. Submit for review to IT team

---

## 📞 Support

### Internal Support Channels
- **Email:** it@sbsfederal.com
- **Documentation:** This repository
- **Logs:**
  - **macOS:** `~/.mac-dev-setup.log`, `~/.m365-installer/installer.log`, `~/.compliance-scanner/scanner.log`
  - **Windows:** `%USERPROFILE%\.windows-dev-setup\setup.log`, `%USERPROFILE%\.m365-installer\installer.log`, `%USERPROFILE%\.nist-compliance\scanner.log`

### External Resources
- **NIST 800-53:** https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- **Homebrew Docs:** https://docs.brew.sh/
- **Chocolatey Docs:** https://docs.chocolatey.org/
- **Microsoft Intune:** https://docs.microsoft.com/mem/intune/
- **Microsoft 365:** https://support.microsoft.com/office

---

## 📄 License

**Internal Use Only - SBS Federal**
Confidential and Proprietary

All scripts and tools are for exclusive use by SBS Federal employees and authorized contractors. Unauthorized distribution or use is prohibited.

---

## 🎉 Quick Commands Reference

### macOS Commands
```bash
# Mac Dev Setup
./packages/macos/mac-dev-setup/scripts/mac-dev-setup.sh

# M365 Installer
./packages/macos/m365-installer/scripts/m365-installer.sh

# Compliance Scanner
./packages/macos/compliance-scanner/scripts/nist-800-53-scanner.sh

# View Logs
tail -f ~/.mac-dev-setup.log
tail -f ~/.m365-installer/installer.log
tail -f ~/.compliance-scanner/scanner.log

# Build Intune Package
cd packages/macos/[package-name]/intune/ && ./build-package.sh
```

### Windows Commands
```powershell
# Windows Dev Setup (Run as Admin)
powershell.exe -ExecutionPolicy Bypass -File packages\windows\windows-dev-setup\scripts\windows-dev-setup.ps1

# M365 Installer (Run as Admin)
powershell.exe -ExecutionPolicy Bypass -File packages\windows\windows-m365-installer\scripts\windows-m365-installer.ps1

# Compliance Scanner (Run as Admin)
powershell.exe -ExecutionPolicy Bypass -File packages\windows\windows-compliance-scanner\scripts\windows-compliance-scanner.ps1

# View Logs
notepad %USERPROFILE%\.windows-dev-setup\setup.log
notepad %USERPROFILE%\.m365-installer\installer.log
notepad %USERPROFILE%\.nist-compliance\scanner.log
```

---

## 📊 Project Statistics

- **Total Packages:** 6 (3 macOS + 3 Windows)
- **Total Files:** 60+
- **Total Lines of Code:** 15,000+
- **Documentation Pages:** 20+
- **Platforms Supported:** 2 (macOS, Windows)
- **Compliance Controls:** 40+ (25 macOS, 16 Windows)
- **Applications Managed:** 70+ total

---

**Last Updated:** 2025-12-17
**Repository:** https://github.com/kmwhite40/DevHelpDeskTools
**Company:** SBS Federal
**Maintained By:** Kevin White | IT Department

---

🤖 *Generated with [Claude Code](https://claude.com/claude-code)*

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
