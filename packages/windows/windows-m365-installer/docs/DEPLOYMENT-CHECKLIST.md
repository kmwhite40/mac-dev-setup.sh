# M365 Installer - Intune Deployment Checklist

## SBS Federal Help Desk Deployment Guide

**Version:** 1.2.0
**Estimated Time:** 30-45 minutes
**Contact:** it@sbsfederal.com

---

## Quick Reference

| Item | Value |
|------|-------|
| Package Name | SBS Federal M365 Installer |
| Version | 1.2.0 |
| Install Command | `powershell.exe -ExecutionPolicy Bypass -File install.ps1` |
| Uninstall Command | `powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1` |
| Detection | Custom script (detection.ps1) |
| Install Behavior | System |
| Min OS | Windows 10 1809 |
| Disk Space | 15 GB |

---

## Pre-Deployment Checklist

### 1. Gather Required Files
- [ ] `windows-m365-installer.ps1` (main script)
- [ ] `install.ps1` (Intune wrapper)
- [ ] `uninstall.ps1` (uninstall script)
- [ ] `detection.ps1` (detection script)

### 2. Verify Prerequisites
- [ ] Microsoft Endpoint Manager admin access
- [ ] Win32 Content Prep Tool downloaded
- [ ] Test device available for pilot

### 3. Prepare Package Folder
- [ ] Create folder: `C:\IntunePackages\M365Installer\`
- [ ] Copy all 4 scripts to folder
- [ ] Verify all files present

---

## Package Creation Checklist

### 4. Create .intunewin Package
- [ ] Open Command Prompt as Administrator
- [ ] Navigate to Win32 Content Prep Tool folder
- [ ] Run command:
  ```cmd
  IntuneWinAppUtil.exe -c "C:\IntunePackages\M365Installer" -s "install.ps1" -o "C:\IntunePackages\Output" -q
  ```
- [ ] Verify `install.intunewin` created in Output folder

---

## Intune Upload Checklist

### 5. Create App in Intune
- [ ] Navigate to https://endpoint.microsoft.com
- [ ] Go to Apps > Windows
- [ ] Click + Add
- [ ] Select "Windows app (Win32)"

### 6. App Information
- [ ] Name: `SBS Federal M365 Installer`
- [ ] Description: `Automated Microsoft 365 installer with prerequisites`
- [ ] Publisher: `SBS Federal`
- [ ] Version: `1.2.0`
- [ ] Category: `Productivity`

### 7. Upload Package
- [ ] Click "Select app package file"
- [ ] Upload `install.intunewin`
- [ ] Wait for upload to complete

### 8. Program Settings
- [ ] Install command: `powershell.exe -ExecutionPolicy Bypass -File install.ps1`
- [ ] Uninstall command: `powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1`
- [ ] Install behavior: `System`
- [ ] Device restart behavior: `Determine behavior based on return codes`

### 9. Return Codes
- [ ] 0 = Success
- [ ] 1707 = Success
- [ ] 3010 = Soft reboot
- [ ] 1641 = Hard reboot
- [ ] 1618 = Retry

### 10. Requirements
- [ ] OS architecture: `64-bit`
- [ ] Minimum OS: `Windows 10 1809`
- [ ] Disk space: `15360 MB`
- [ ] Memory: `4096 MB`

### 11. Detection Rules
- [ ] Rules format: `Use a custom detection script`
- [ ] Upload `detection.ps1`
- [ ] Run as 32-bit: `No`
- [ ] Enforce signature check: `No`
- [ ] Run in 64-bit PowerShell: `Yes`

### 12. Review and Create
- [ ] Review all settings
- [ ] Click Create
- [ ] Wait for app to be created

---

## Assignment Checklist

### 13. Pilot Deployment
- [ ] Add assignment: Required
- [ ] Select: IT Test Devices group
- [ ] Set availability: As soon as possible
- [ ] Enable notifications: Yes
- [ ] Save assignment

### 14. Verify Pilot
- [ ] Wait for Intune sync (up to 8 hours or force sync)
- [ ] Check device for installation
- [ ] Verify all apps installed:
  - [ ] Microsoft Office (Word, Excel, PowerPoint, Outlook)
  - [ ] Microsoft Teams
  - [ ] OneDrive
  - [ ] Microsoft Edge
  - [ ] Company Portal
  - [ ] Netskope Client
- [ ] Review logs for errors
- [ ] Test app functionality

### 15. Production Deployment
- [ ] Add assignment: Available for enrolled devices
- [ ] Select: All Users or target group
- [ ] Enable notifications: Yes
- [ ] Save assignment
- [ ] Communicate to users

---

## Post-Deployment Verification

### 16. Monitor Deployment
- [ ] Check Apps > Monitor > App install status
- [ ] Review installation success rate
- [ ] Identify and resolve failures
- [ ] Document any issues

### 17. User Communication
- [ ] Send announcement email
- [ ] Include Company Portal instructions
- [ ] Provide support contact info
- [ ] Set expectations for install time

---

## Troubleshooting Quick Reference

### Check Installation Logs
```powershell
# Intune logs
Get-Content "$env:ProgramData\SBSFederal\M365Installer\Logs\*.log"

# Installer logs
Get-Content "$env:USERPROFILE\.m365-installer\installer.log"
```

### Check Registry Detection
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\SBSFederal\M365Installer"
```

### Force Intune Sync
```powershell
# From device
Start-Process "intunemanagementextension://syncapp"
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Stuck at "Downloading" | Check network, retry |
| Exit code 1 | Check prerequisites |
| Exit code 3010 | Restart required |
| Not detected | Check registry key |

---

## Sign-Off

**Deployed By:** _________________________ **Date:** _____________

**Verified By:** _________________________ **Date:** _____________

**Notes:**
```




```

---

## Support Escalation

| Level | Contact | Response Time |
|-------|---------|---------------|
| Tier 1 | Help Desk | Same day |
| Tier 2 | IT Admin | 4 hours |
| Tier 3 | it@sbsfederal.com | 24 hours |

---

*SBS Federal IT Department - Confidential*
