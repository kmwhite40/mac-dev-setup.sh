###  NIST 800-53 Compliance Scanner for macOS

Automated security compliance scanner for macOS endpoints that checks against NIST 800-53 security controls and generates detailed HTML and JSON reports with remediation recommendations.

---

## 🎯 Overview

The NIST 800-53 Compliance Scanner is an enterprise-grade security assessment tool designed for **SBS Federal** that automatically scans macOS endpoints for compliance with NIST Special Publication 800-53 security controls.

**Key Features:**
- ✅ Scans 25+ NIST 800-53 security controls
- ✅ Generates beautiful HTML reports with compliance scoring
- ✅ Exports JSON data for integration with SIEM/GRC tools
- ✅ Provides actionable remediation recommendations
- ✅ Zero configuration required
- ✅ Can be deployed via Intune Company Portal
- ✅ Optional automated weekly scanning

---

## 📊 Compliance Controls Checked

### Access Control (AC) Family
- **AC-2**: Account Management
- **AC-7**: Unsuccessful Login Attempts
- **AC-8**: System Use Notification (Login Banner)
- **AC-11**: Session Lock (Screen Saver)
- **AC-17**: Remote Access

### Audit and Accountability (AU) Family
- **AU-2**: Audit Events
- **AU-3**: Content of Audit Records
- **AU-9**: Protection of Audit Information

### Configuration Management (CM) Family
- **CM-6**: Configuration Settings
- **CM-7**: Least Functionality

### Identification and Authentication (IA) Family
- **IA-2**: Identification and Authentication
- **IA-5**: Authenticator Management
- **IA-5(1)**: Password Complexity

### System and Communications Protection (SC) Family
- **SC-7**: Boundary Protection (Firewall)
- **SC-8**: Transmission Confidentiality
- **SC-13**: Cryptographic Protection
- **SC-28**: Protection of Information at Rest

### System and Information Integrity (SI) Family
- **SI-2**: Flaw Remediation (Software Updates)
- **SI-3**: Malicious Code Protection
- **SI-4**: Information System Monitoring
- **SI-7**: Software and Information Integrity

### Media Protection (MP) Family
- **MP-7**: Media Use

### Physical and Environmental Protection (PE) Family
- **PE-3**: Physical Access Control

---

## 🚀 Quick Start

### Individual Use

```bash
# Make executable
chmod +x nist-800-53-scanner.sh

# Run scan
./nist-800-53-scanner.sh
```

### After Intune Installation

```bash
# Simply run
compliance-scan
```

The scanner will:
1. Check all 25+ security controls
2. Generate an HTML report
3. Export JSON data
4. Automatically open the report in your browser

**Time:** 30-60 seconds

---

## 📁 File Locations

### User Installation
```
~/.compliance-scanner/
  ├── scanner.log                           # Scan execution log
  └── reports/
      ├── nist-800-53-scan-TIMESTAMP.html   # HTML report
      └── nist-800-53-scan-TIMESTAMP.json   # JSON export
```

### Intune Installation
```
/Library/Application Support/ComplianceScanner/
  └── nist-800-53-scanner.sh                # Main script

/Library/Logs/ComplianceScanner/
  ├── intune-install.log                    # Installation log
  ├── preinstall.log                        # Pre-install checks
  ├── postinstall.log                       # Post-install tasks
  └── scheduled-scan-*.log                  # Automated scan logs

/Users/Shared/ComplianceReports/
  └── [All scan reports accessible to all users]

/usr/local/bin/
  └── compliance-scan                       # Command wrapper
```

---

## 📈 Report Output

### HTML Report Features

The HTML report includes:

1. **Executive Dashboard**
   - Overall compliance score percentage
   - Pass/Fail/Warning counts
   - Visual compliance meter

2. **System Information**
   - Hostname, OS version, scan date
   - Hardware details
   - Current user

3. **Detailed Findings**
   - Color-coded control status (Green/Red/Yellow)
   - Control ID and name
   - Current finding
   - Specific recommendation for remediation

4. **Professional Styling**
   - Modern, responsive design
   - Print-friendly layout
   - SBS Federal branding

### JSON Export Features

The JSON export includes:
- Scan metadata (timestamp, version, hostname)
- Individual control results
- Compliance summary statistics
- Structured data for automation

**Use cases:**
- Import into Splunk/ELK
- Feed into GRC platforms
- Automated compliance dashboards
- Historical trending analysis

---

## 🔧 Configuration

### Company Settings

Edit the script to customize:

```bash
# Edit line 16-17
COMPANY_NAME="SBS Federal"
```

### Scheduled Automated Scans

Enable weekly automated scans (Mondays at 9 AM):

```bash
sudo launchctl load -w /Library/LaunchDaemons/com.sbsfederal.compliancescanner.plist
```

Disable automated scans:

```bash
sudo launchctl unload -w /Library/LaunchDaemons/com.sbsfederal.compliancescanner.plist
```

View automated scan logs:

```bash
tail -f /Library/Logs/ComplianceScanner/scheduled-scan-stdout.log
```

---

## 📊 Understanding Compliance Scores

### Score Interpretation

| Score | Rating | Meaning |
|-------|--------|---------|
| 90-100% | Excellent | Highly compliant, minor improvements needed |
| 70-89% | Good | Generally compliant, several areas need attention |
| 50-69% | Fair | Significant compliance gaps, remediation required |
| < 50% | Poor | Critical compliance issues, immediate action needed |

### Status Indicators

- **✅ PASS (Green)**: Control is properly configured and compliant
- **❌ FAIL (Red)**: Control is not compliant, remediation required
- **⚠️  WARNING (Yellow)**: Control needs review or improvement
- **ℹ️  INFO (Blue)**: Informational finding, no action required

---

## 🔍 Common Findings and Remediation

### Failed Control: FileVault Not Enabled

**Finding:** SC-28 - Protection of Information at Rest - FAIL

**Remediation:**
```bash
# Enable FileVault encryption
1. System Preferences → Security & Privacy
2. Click FileVault tab
3. Click "Turn On FileVault"
4. Follow prompts to create recovery key
5. Restart Mac to begin encryption
```

### Failed Control: Firewall Disabled

**Finding:** SC-7 - Boundary Protection - FAIL

**Remediation:**
```bash
# Enable macOS firewall
1. System Preferences → Security & Privacy
2. Click Firewall tab
3. Click lock to make changes
4. Click "Turn On Firewall"
5. Click "Firewall Options" to configure rules
```

### Failed Control: No Login Banner

**Finding:** AC-8 - System Use Notification - FAIL

**Remediation:**
```bash
# Create login banner
sudo nano /Library/Security/PolicyBanner.txt

# Add authorized use notice, example:
This system is for authorized use only. Unauthorized access is prohibited
and may be subject to criminal and civil penalties. All activities may be
monitored and recorded. By using this system, you consent to such monitoring.

# Save and restart
```

### Failed Control: Weak Password Policy

**Finding:** IA-5 - Authenticator Management - FAIL

**Remediation:**
```bash
# Configure password policy via MDM/Intune or locally:
sudo pwpolicy setaccountpolicies <policyfile>

# Or use macOS GUI:
1. System Preferences → Users & Groups
2. Click Login Options
3. Enable password requirements
4. Set minimum length to 12+ characters
```

---

## 🚀 Intune Deployment

### Build Package

```bash
cd intune/
./build-package.sh
```

### Convert for Intune

```bash
./IntuneAppUtil -c ComplianceScanner-1.0.0.pkg -o . -i com.sbsfederal.compliancescanner -n 1.0.0
```

### Upload to Intune

1. Go to https://intune.microsoft.com
2. Apps → macOS → Add → Line-of-business app
3. Upload `ComplianceScanner-1.0.0.intunemac`
4. Configure:
   - Name: NIST 800-53 Compliance Scanner
   - Publisher: SBS Federal IT
   - Category: Security & Compliance
   - Show in Company Portal: Yes
5. Detection: Upload `detection.sh`
6. Assign to groups

### User Experience

1. User opens Company Portal
2. Searches for "Compliance Scanner"
3. Clicks Install (takes 10 seconds)
4. Receives notification when complete
5. Opens Terminal, runs: `compliance-scan`
6. Report opens automatically in browser

---

## 🔐 Security Considerations

### What the Scanner Checks

- ✅ System security settings (read-only)
- ✅ Account policies (read-only)
- ✅ Firewall status (read-only)
- ✅ Encryption status (read-only)
- ✅ Running processes (read-only)
- ✅ Configuration profiles (read-only)

### What the Scanner Does NOT Do

- ❌ Modify any system settings
- ❌ Change security configurations
- ❌ Access user data
- ❌ Send data externally
- ❌ Require admin password (for scan only)

### Data Privacy

- Reports stored locally only
- No data transmitted to external servers
- Logs contain system configuration only (no personal data)
- Reports can be deleted by user at any time

---

## 📊 Integration with SIEM/GRC Tools

### Splunk Integration

```bash
# Index JSON reports
[monitor:///Users/Shared/ComplianceReports/*.json]
sourcetype = nist_compliance
index = security

# Create dashboards using compliance_score field
```

### ELK Stack Integration

```bash
# Filebeat configuration
filebeat.inputs:
- type: log
  paths:
    - /Users/Shared/ComplianceReports/*.json
  json.keys_under_root: true
  json.add_error_key: true
```

### ServiceNow GRC Integration

Use the JSON API to import scan results into ServiceNow Governance, Risk, and Compliance module.

---

## 🔧 Troubleshooting

### Scanner Fails to Run

**Issue:** Permission denied

**Solution:**
```bash
chmod +x nist-800-53-scanner.sh
./nist-800-53-scanner.sh
```

### Report Not Opening

**Issue:** Report generated but doesn't open in browser

**Solution:**
```bash
# Manually open report
open ~/.compliance-scanner/reports/nist-800-53-scan-*.html

# Or from shared location
open /Users/Shared/ComplianceReports/nist-800-53-scan-*.html
```

### Command Not Found

**Issue:** `compliance-scan: command not found`

**Solution:**
```bash
# Check if installed
ls -la /usr/local/bin/compliance-scan

# If missing, reinstall from Intune or run directly
/Library/Application\ Support/ComplianceScanner/nist-800-53-scanner.sh
```

### Incomplete Scan Results

**Issue:** Some checks show "unknown" or no results

**Solution:**
- Ensure running on macOS 10.15+
- Some checks require specific macOS versions
- Check scanner.log for errors
- Run with verbose output if issues persist

---

## 📝 Customization

### Adding Custom Controls

Edit `nist-800-53-scanner.sh` to add your own checks:

```bash
# Example: Check for custom security tool
check_custom_security() {
    log_info "Checking Custom Security Tool"

    if pgrep -x "SecurityTool" > /dev/null; then
        log_success "CUSTOM-1: Security tool running"
        add_json_control "CUSTOM-1" "Custom Security" "PASS" "Tool active" "Custom security properly configured"
    else
        log_fail "CUSTOM-1: Security tool not running"
        add_json_control "CUSTOM-1" "Custom Security" "FAIL" "Tool not active" "Install and run custom security tool"
    fi
}

# Add to main() function
check_custom_security
```

### Modifying Report Styling

Edit the HTML template in the `generate_html_report()` function to customize:
- Colors and branding
- Logo and company information
- Additional sections
- Chart visualizations

---

## 📅 Compliance Reporting Schedule

### Recommended Schedule

- **Daily**: Automated scans on critical systems
- **Weekly**: All managed endpoints
- **Monthly**: Compliance reporting to leadership
- **Quarterly**: Full compliance audit

### Automation Example

```bash
# Run scan and email report (requires mail configuration)
compliance-scan
LATEST_REPORT=$(ls -t ~/. compliance-scanner/reports/*.html | head -1)
mail -s "Compliance Scan Report - $(hostname)" it@sbsfederal.com < "$LATEST_REPORT"
```

---

## 🆘 Support

### Internal Support
- **Email:** it@sbsfederal.com
- **Documentation:** This file
- **Logs:** `/Library/Logs/ComplianceScanner/scanner.log`

### External Resources
- **NIST 800-53 Documentation:** https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final
- **macOS Security Guide:** https://support.apple.com/guide/deployment/intro-to-device-security-dep06e74b8e1/web
- **CIS Benchmarks for macOS:** https://www.cisecurity.org/benchmark/apple_os

---

## 📄 License

Internal use only - SBS Federal
Version 1.0.0
Last Updated: 2025-12-17

---

## 🎉 Quick Command Reference

```bash
# Run scan
compliance-scan

# View latest HTML report
open ~/. compliance-scanner/reports/nist-800-53-scan-*.html

# View latest JSON export
cat ~/.compliance-scanner/reports/nist-800-53-scan-*.json | jq

# Check scan history
ls -lh ~/.compliance-scanner/reports/

# View scan log
tail -50 ~/.compliance-scanner/scanner.log

# Enable automated scans
sudo launchctl load -w /Library/LaunchDaemons/com.sbsfederal.compliancescanner.plist

# Check installation
ls -la /Library/Application\ Support/ComplianceScanner/
```

---

**For deployment to Intune, see [intune/README-INTUNE.md](intune/README-INTUNE.md)**
