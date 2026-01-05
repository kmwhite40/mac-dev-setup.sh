# Microsoft 365 Installer - Intune Admin Guide

## SBS Federal IT Administration Guide

**Version:** 1.2.0
**Last Updated:** 2025-01-05
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Package Contents](#package-contents)
4. [Creating the Intune Package](#creating-the-intune-package)
5. [Uploading to Intune](#uploading-to-intune)
6. [Configuring the App](#configuring-the-app)
7. [Assignment and Deployment](#assignment-and-deployment)
8. [Monitoring Deployment](#monitoring-deployment)
9. [Troubleshooting](#troubleshooting)
10. [FAQ](#faq)

---

## Overview

The SBS Federal M365 Installer automates the deployment of Microsoft 365 applications to Windows endpoints via Microsoft Intune Company Portal. This package includes:

### Applications Installed
| Application | Description |
|-------------|-------------|
| Microsoft Office 365 | Word, Excel, PowerPoint, Outlook, OneNote |
| Microsoft Teams | Collaboration and communication |
| Microsoft OneDrive | Cloud storage and sync |
| Microsoft Edge | Web browser |
| Company Portal | Intune management |
| Netskope Client | Security client |

### Prerequisites Auto-Installed
| Prerequisite | Purpose |
|--------------|---------|
| .NET Framework 4.8 | Required for Office apps |
| Visual C++ 2015-2022 | Runtime libraries |
| WebView2 Runtime | Required for new Teams |
| Windows Subsystem for Linux | Developer tools |
| TLS 1.2 | Secure downloads |

---

## Prerequisites

### Admin Requirements
- Microsoft Intune Administrator role (or equivalent)
- Access to Microsoft Endpoint Manager admin center
- Windows device with Microsoft Win32 Content Prep Tool

### Endpoint Requirements
- Windows 10 Build 17763 (version 1809) or later
- Windows 11 (any version)
- 15 GB free disk space
- Internet connectivity
- Local administrator rights (handled by Intune)

---

## Package Contents

```
windows-m365-installer/
├── scripts/
│   └── windows-m365-installer.ps1    # Main installer script
├── intune/
│   ├── install.ps1                    # Intune install wrapper
│   ├── uninstall.ps1                  # Uninstall script
│   ├── detection.ps1                  # Detection script
│   └── package-info.json              # Package metadata
└── docs/
    ├── INTUNE-ADMIN-GUIDE.md          # This guide
    └── DEPLOYMENT-CHECKLIST.md        # Deployment checklist
```

---

## Creating the Intune Package

### Step 1: Download Win32 Content Prep Tool

1. Download from: https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool
2. Extract `IntuneWinAppUtil.exe` to a convenient location

### Step 2: Prepare the Package Folder

1. Create a folder structure:
   ```
   C:\IntunePackages\M365Installer\
   ├── install.ps1
   ├── uninstall.ps1
   ├── detection.ps1
   └── windows-m365-installer.ps1
   ```

2. Copy all required files from the repository to this folder

### Step 3: Create the .intunewin Package

1. Open Command Prompt as Administrator

2. Navigate to the Win32 Content Prep Tool location

3. Run the packaging command:
   ```cmd
   IntuneWinAppUtil.exe -c "C:\IntunePackages\M365Installer" -s "install.ps1" -o "C:\IntunePackages\Output" -q
   ```

   Parameters:
   - `-c` = Source folder containing your files
   - `-s` = Setup file (entry point)
   - `-o` = Output folder for .intunewin file
   - `-q` = Quiet mode (optional)

4. The tool creates: `install.intunewin`

---

## Uploading to Intune

### Step 1: Access Microsoft Endpoint Manager

1. Navigate to: https://endpoint.microsoft.com
2. Sign in with your Intune admin credentials
3. Go to **Apps** > **Windows**

### Step 2: Add New App

1. Click **+ Add**
2. Select app type: **Windows app (Win32)**
3. Click **Select**

### Step 3: Configure App Information

Fill in the following fields:

| Field | Value |
|-------|-------|
| **Name** | SBS Federal M365 Installer |
| **Description** | Automated Microsoft 365 application installer with prerequisites. Installs Office 365, Teams, OneDrive, Edge, Company Portal, and Netskope Client. |
| **Publisher** | SBS Federal |
| **App Version** | 1.2.0 |
| **Category** | Productivity |
| **Information URL** | (optional) |
| **Privacy URL** | (optional) |
| **Developer** | SBS Federal IT |
| **Owner** | IT Department |
| **Notes** | Contact it@sbsfederal.com for support |

Click **Next**

### Step 4: Upload Package

1. Click **Select app package file**
2. Browse to and select: `install.intunewin`
3. Click **OK**
4. Click **Next**

### Step 5: Configure Program Settings

| Field | Value |
|-------|-------|
| **Install command** | `powershell.exe -ExecutionPolicy Bypass -File install.ps1` |
| **Uninstall command** | `powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1` |
| **Install behavior** | System |
| **Device restart behavior** | Determine behavior based on return codes |
| **Return codes** | (use defaults + add custom if needed) |

**Return Codes:**
| Code | Type |
|------|------|
| 0 | Success |
| 1707 | Success |
| 3010 | Soft reboot |
| 1641 | Hard reboot |
| 1618 | Retry |

Click **Next**

### Step 6: Configure Requirements

| Field | Value |
|-------|-------|
| **Operating system architecture** | 64-bit |
| **Minimum operating system** | Windows 10 1809 |
| **Disk space required (MB)** | 15360 |
| **Physical memory required (MB)** | 4096 |

Click **Next**

### Step 7: Configure Detection Rules

1. Select **Rules format:** Use a custom detection script
2. Click **Add**
3. Configure:
   | Field | Value |
   |-------|-------|
   | **Script file** | Upload `detection.ps1` |
   | **Run script as 32-bit process** | No |
   | **Enforce script signature check** | No |
   | **Run script in 64-bit PowerShell** | Yes |

4. Click **OK**
5. Click **Next**

### Step 8: Dependencies (Optional)

- No dependencies required
- Click **Next**

### Step 9: Supersedence (Optional)

- Configure if replacing an older version
- Click **Next**

### Step 10: Assignments

See [Assignment and Deployment](#assignment-and-deployment) section below.

### Step 11: Review + Create

1. Review all settings
2. Click **Create**

---

## Configuring the App

### App Configuration Options

The installer supports several configuration options via registry or command-line parameters:

#### Silent Mode (Default for Intune)
```powershell
powershell.exe -ExecutionPolicy Bypass -File install.ps1
```

#### Skip Specific Prerequisites
Not recommended for Intune deployments. All prerequisites should be installed.

#### Custom Logging Location
Logs are stored at:
- User-level: `%USERPROFILE%\.m365-installer\installer.log`
- Intune-level: `%ProgramData%\SBSFederal\M365Installer\Logs\`

---

## Assignment and Deployment

### Deployment Options

#### Option 1: Required Deployment (Recommended for New Devices)
- Automatically installs on assigned devices
- No user interaction required
- Best for: Device onboarding, compliance requirements

#### Option 2: Available Deployment (Recommended for Existing Devices)
- Appears in Company Portal for user self-service
- User initiates installation
- Best for: User choice, gradual rollout

### Creating Assignments

1. In the app properties, go to **Assignments**
2. Click **+ Add group**

#### For Required Deployment:
| Setting | Value |
|---------|-------|
| **Assignment type** | Required |
| **Group** | Select target device/user group |
| **End user notifications** | Show all toast notifications |
| **Availability** | As soon as possible |
| **Installation deadline** | (set appropriate deadline) |
| **Restart grace period** | 1440 minutes (24 hours) |

#### For Available Deployment:
| Setting | Value |
|---------|-------|
| **Assignment type** | Available for enrolled devices |
| **Group** | Select target device/user group |
| **End user notifications** | Show all toast notifications |

### Recommended Deployment Strategy

**Phase 1: Pilot (Week 1)**
- Deploy to IT test group
- Monitor for issues
- Verify all apps install correctly

**Phase 2: Early Adopters (Week 2)**
- Deploy to volunteer users
- Gather feedback
- Address any issues

**Phase 3: General Availability (Week 3+)**
- Deploy to all users via Company Portal
- Make available for self-service installation

---

## Monitoring Deployment

### Viewing Installation Status

1. Go to **Apps** > **Monitor** > **App install status**
2. Select "SBS Federal M365 Installer"
3. Review:
   - Device install status
   - User install status
   - Installation failures

### Status Codes

| Status | Meaning |
|--------|---------|
| Installed | Successfully installed |
| Pending | Waiting to install |
| Failed | Installation failed |
| Not Applicable | Device doesn't meet requirements |
| Not Installed | Available but not yet installed |

### Accessing Logs

**On the device:**
```powershell
# View Intune logs
Get-Content "$env:ProgramData\SBSFederal\M365Installer\Logs\*.log"

# View installer logs
Get-Content "$env:USERPROFILE\.m365-installer\installer.log"
```

**In Intune:**
1. Go to **Devices** > **All devices**
2. Select the device
3. Click **Diagnostics**
4. Collect diagnostics

---

## Troubleshooting

### Common Issues

#### Issue: Installation Fails with Exit Code 1
**Cause:** Prerequisites failed to install
**Solution:**
1. Check if device has internet connectivity
2. Verify device meets minimum requirements
3. Check logs for specific error

#### Issue: Installation Fails with Exit Code 3010
**Cause:** Restart required to complete installation
**Solution:**
- This is expected behavior
- Device will restart and continue
- Mark as "Soft reboot" in return codes

#### Issue: Detection Script Returns "Not Detected"
**Cause:** Registry key not created or Office not installed
**Solution:**
1. Verify installation completed
2. Check registry: `HKLM:\SOFTWARE\SBSFederal\M365Installer`
3. Verify Office applications are installed

#### Issue: WSL Installation Requires Restart
**Cause:** Windows features need restart to enable
**Solution:**
- Expected behavior
- User will be prompted to restart
- Installation continues after restart

#### Issue: "Access Denied" During Installation
**Cause:** Script not running with admin privileges
**Solution:**
1. Verify "Install behavior" is set to "System"
2. Check Intune agent is functioning

### Diagnostic Commands

Run on affected device (as Administrator):

```powershell
# Check Intune management extension logs
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Tail 100

# Check if Office is installed
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue

# Check detection registry key
Get-ItemProperty "HKLM:\SOFTWARE\SBSFederal\M365Installer" -ErrorAction SilentlyContinue

# Check WSL status
wsl --status

# List installed apps
Get-AppxPackage | Where-Object { $_.Name -like "*Microsoft*" }
```

---

## FAQ

### Q: How long does installation take?
**A:** Typically 30-60 minutes depending on network speed and system performance.

### Q: Can users cancel the installation?
**A:** For "Required" deployments, no. For "Available" deployments, users control when to start but cannot cancel once started.

### Q: What happens if Office is already installed?
**A:** The installer detects existing installations and skips them.

### Q: Does this work on Windows 11?
**A:** Yes, Windows 11 is fully supported.

### Q: How do I update the package?
**A:** Create a new .intunewin package with updated scripts, upload as a new version, and use supersedence.

### Q: Can I deploy to Azure AD joined devices only?
**A:** Yes, use device filters or groups based on join type.

### Q: What if a user doesn't have admin rights?
**A:** The "System" install behavior runs with SYSTEM privileges, so user rights don't matter.

### Q: How do I uninstall Office apps?
**A:** Use the Office Deployment Tool or uninstall individually from Settings > Apps.

---

## Support

For assistance with deployment issues:

- **Email:** it@sbsfederal.com
- **Documentation:** This guide and related docs in the repository
- **Logs:** Always include logs when reporting issues

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.2.0 | 2025-01-05 | Added WSL prerequisite |
| 1.1.0 | 2025-01-05 | Added comprehensive prerequisites |
| 1.0.0 | 2025-01-01 | Initial release |

---

*SBS Federal IT Department*
*Confidential - Internal Use Only*
