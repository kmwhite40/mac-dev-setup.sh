#!/bin/bash

################################################################################
# NIST 800-53 Compliance Scanner for macOS
# Version: 1.0.0
# Company: SBS Federal
#
# This script scans macOS endpoints for NIST 800-53 compliance controls
# and provides detailed recommendations for improvements.
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPANY_NAME="SBS Federal"
SCAN_VERSION="1.0.0"
LOG_DIR="$HOME/.compliance-scanner"
REPORT_DIR="$LOG_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/nist-800-53-scan-$TIMESTAMP.html"
JSON_REPORT="$REPORT_DIR/nist-800-53-scan-$TIMESTAMP.json"
LOG_FILE="$LOG_DIR/scanner.log"

# Compliance tracking
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Create necessary directories
mkdir -p "$LOG_DIR"
mkdir -p "$REPORT_DIR"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}" | tee -a "$LOG_FILE"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_fail() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_FILE"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a "$LOG_FILE"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
}

log_info() {
    echo -e "${CYAN}[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

# JSON report structure
init_json_report() {
    cat > "$JSON_REPORT" << EOF
{
  "scan_info": {
    "company": "$COMPANY_NAME",
    "scan_version": "$SCAN_VERSION",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$(hostname)",
    "os_version": "$(sw_vers -productVersion)",
    "user": "$(whoami)"
  },
  "controls": [
EOF
}

# Add control to JSON
add_json_control() {
    local control_id="$1"
    local control_name="$2"
    local status="$3"
    local finding="$4"
    local recommendation="$5"

    cat >> "$JSON_REPORT" << EOF
    {
      "control_id": "$control_id",
      "control_name": "$control_name",
      "status": "$status",
      "finding": "$finding",
      "recommendation": "$recommendation"
    },
EOF
}

# Finalize JSON report
finalize_json_report() {
    # Remove trailing comma from last control
    sed -i '' '$ s/,$//' "$JSON_REPORT"

    cat >> "$JSON_REPORT" << EOF
  ],
  "summary": {
    "total_checks": $TOTAL_CHECKS,
    "passed": $PASSED_CHECKS,
    "failed": $FAILED_CHECKS,
    "warnings": $WARNING_CHECKS,
    "compliance_score": $(echo "scale=2; ($PASSED_CHECKS * 100) / $TOTAL_CHECKS" | bc)
  }
}
EOF
}

################################################################################
# Access Control (AC) Family
################################################################################

check_ac_2_account_management() {
    log_info "Checking AC-2: Account Management"

    # Check for local user accounts
    local local_users=$(dscl . list /Users | grep -v "^_" | grep -v "daemon" | grep -v "nobody" | wc -l)

    if [ "$local_users" -le 5 ]; then
        log_success "AC-2: Reasonable number of local accounts ($local_users)"
        add_json_control "AC-2" "Account Management" "PASS" "$local_users local user accounts" "Continue monitoring account creation"
    else
        log_warning "AC-2: High number of local accounts ($local_users)"
        add_json_control "AC-2" "Account Management" "WARNING" "$local_users local user accounts" "Review and remove unnecessary local accounts. Use centralized authentication (AD/LDAP)"
    fi
}

check_ac_7_unsuccessful_login_attempts() {
    log_info "Checking AC-7: Unsuccessful Login Attempts"

    local max_failed=$(pwpolicy -getaccountpolicies 2>/dev/null | grep -i maxFailedLoginAttempts | awk '{print $NF}')

    if [ -n "$max_failed" ] && [ "$max_failed" -le 5 ]; then
        log_success "AC-7: Login attempt lockout configured ($max_failed attempts)"
        add_json_control "AC-7" "Unsuccessful Login Attempts" "PASS" "Max failed attempts: $max_failed" "Lockout policy properly configured"
    else
        log_fail "AC-7: No login attempt lockout policy or too permissive"
        add_json_control "AC-7" "Unsuccessful Login Attempts" "FAIL" "No lockout policy detected" "Configure account lockout after 3-5 failed login attempts: sudo pwpolicy -setaccountpolicies"
    fi
}

check_ac_8_system_use_notification() {
    log_info "Checking AC-8: System Use Notification (Login Banner)"

    if [ -f "/Library/Security/PolicyBanner.txt" ]; then
        log_success "AC-8: Login banner configured"
        add_json_control "AC-8" "System Use Notification" "PASS" "PolicyBanner.txt exists" "Login banner properly configured"
    else
        log_fail "AC-8: No login banner configured"
        add_json_control "AC-8" "System Use Notification" "FAIL" "No login banner found" "Create /Library/Security/PolicyBanner.txt with authorized use notice"
    fi
}

check_ac_11_session_lock() {
    log_info "Checking AC-11: Session Lock (Screen Saver)"

    local screen_saver_delay=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null || echo "0")
    local ask_for_password=$(defaults read com.apple.screensaver askForPassword 2>/dev/null || echo "0")

    if [ "$screen_saver_delay" -le 900 ] && [ "$screen_saver_delay" -gt 0 ] && [ "$ask_for_password" == "1" ]; then
        log_success "AC-11: Screen saver lock configured (${screen_saver_delay}s)"
        add_json_control "AC-11" "Session Lock" "PASS" "Screen saver: ${screen_saver_delay}s, Password required" "Session lock properly configured"
    else
        log_fail "AC-11: Screen saver lock not properly configured"
        add_json_control "AC-11" "Session Lock" "FAIL" "Screen saver delay: ${screen_saver_delay}s, Password: $ask_for_password" "Enable screen saver lock within 15 minutes (900s) and require password"
    fi
}

check_ac_17_remote_access() {
    log_info "Checking AC-17: Remote Access"

    local ssh_enabled=$(systemsetup -getremotelogin 2>/dev/null | grep -i "on" | wc -l)
    local screen_sharing=$(launchctl list | grep com.apple.screensharing | wc -l)

    if [ "$ssh_enabled" -eq 0 ] && [ "$screen_sharing" -eq 0 ]; then
        log_success "AC-17: Remote access services disabled"
        add_json_control "AC-17" "Remote Access" "PASS" "SSH and Screen Sharing disabled" "Remote access properly restricted"
    else
        log_warning "AC-17: Remote access services enabled"
        add_json_control "AC-17" "Remote Access" "WARNING" "SSH: $ssh_enabled, Screen Sharing: $screen_sharing" "Disable unnecessary remote access or ensure proper authentication/encryption"
    fi
}

################################################################################
# Audit and Accountability (AU) Family
################################################################################

check_au_2_audit_events() {
    log_info "Checking AU-2: Audit Events"

    if [ -f "/etc/security/audit_control" ]; then
        log_success "AU-2: Audit system configured"
        add_json_control "AU-2" "Audit Events" "PASS" "audit_control exists" "Audit system properly configured"
    else
        log_fail "AU-2: Audit configuration missing"
        add_json_control "AU-2" "Audit Events" "FAIL" "audit_control not found" "Configure audit system: /etc/security/audit_control"
    fi
}

check_au_3_audit_records() {
    log_info "Checking AU-3: Content of Audit Records"

    local audit_running=$(launchctl list | grep com.apple.auditd | wc -l)

    if [ "$audit_running" -gt 0 ]; then
        log_success "AU-3: Audit daemon running"
        add_json_control "AU-3" "Content of Audit Records" "PASS" "auditd is running" "Audit logging active"
    else
        log_fail "AU-3: Audit daemon not running"
        add_json_control "AU-3" "Content of Audit Records" "FAIL" "auditd not running" "Start audit daemon: sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.auditd.plist"
    fi
}

check_au_9_protection_of_audit_info() {
    log_info "Checking AU-9: Protection of Audit Information"

    if [ -d "/var/audit" ]; then
        local audit_perms=$(stat -f "%Lp" /var/audit)
        if [ "$audit_perms" == "700" ] || [ "$audit_perms" == "750" ]; then
            log_success "AU-9: Audit directory properly protected ($audit_perms)"
            add_json_control "AU-9" "Protection of Audit Information" "PASS" "Permissions: $audit_perms" "Audit logs properly protected"
        else
            log_warning "AU-9: Audit directory permissions too permissive ($audit_perms)"
            add_json_control "AU-9" "Protection of Audit Information" "WARNING" "Permissions: $audit_perms" "Set audit directory to 700: sudo chmod 700 /var/audit"
        fi
    else
        log_fail "AU-9: Audit directory not found"
        add_json_control "AU-9" "Protection of Audit Information" "FAIL" "/var/audit not found" "Create and configure audit directory"
    fi
}

################################################################################
# Configuration Management (CM) Family
################################################################################

check_cm_6_configuration_settings() {
    log_info "Checking CM-6: Configuration Settings"

    # Check for configuration profile
    local profiles=$(profiles -P | grep -c "profileIdentifier" || echo "0")

    if [ "$profiles" -gt 0 ]; then
        log_success "CM-6: Configuration profiles applied ($profiles profiles)"
        add_json_control "CM-6" "Configuration Settings" "PASS" "$profiles configuration profiles" "Configuration management active"
    else
        log_warning "CM-6: No configuration profiles detected"
        add_json_control "CM-6" "Configuration Settings" "WARNING" "No MDM profiles" "Deploy configuration profiles via MDM/Intune"
    fi
}

check_cm_7_least_functionality() {
    log_info "Checking CM-7: Least Functionality"

    local bluetooth=$(defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState 2>/dev/null || echo "1")
    local wifi_power=$(networksetup -getairportpower en0 2>/dev/null | grep -i "on" | wc -l)

    # Count running services
    local running_services=$(launchctl list | grep -v "^-" | grep -v "PID" | wc -l)

    log_info "CM-7: $running_services services running, Bluetooth: $bluetooth, WiFi: $wifi_power"
    add_json_control "CM-7" "Least Functionality" "INFO" "$running_services services running" "Review and disable unnecessary services"
}

################################################################################
# Identification and Authentication (IA) Family
################################################################################

check_ia_2_identification_authentication() {
    log_info "Checking IA-2: Identification and Authentication"

    # Check if FileVault is enabled
    local fv_status=$(fdesetup status | grep -i "on" | wc -l)

    if [ "$fv_status" -gt 0 ]; then
        log_success "IA-2: FileVault enabled (disk encryption)"
        add_json_control "IA-2" "Identification and Authentication" "PASS" "FileVault enabled" "Strong authentication in place"
    else
        log_fail "IA-2: FileVault not enabled"
        add_json_control "IA-2" "Identification and Authentication" "FAIL" "FileVault disabled" "Enable FileVault disk encryption: System Preferences → Security → FileVault"
    fi
}

check_ia_5_authenticator_management() {
    log_info "Checking IA-5: Authenticator Management (Password Policy)"

    local min_length=$(pwpolicy -getaccountpolicies 2>/dev/null | grep -i minChars | awk '{print $NF}')

    if [ -n "$min_length" ] && [ "$min_length" -ge 12 ]; then
        log_success "IA-5: Password minimum length configured ($min_length characters)"
        add_json_control "IA-5" "Authenticator Management" "PASS" "Min password length: $min_length" "Password policy properly configured"
    else
        log_fail "IA-5: Weak or no password policy (length: ${min_length:-not set})"
        add_json_control "IA-5" "Authenticator Management" "FAIL" "Min length: ${min_length:-not set}" "Configure minimum 12-character password requirement"
    fi
}

check_ia_5_1_password_complexity() {
    log_info "Checking IA-5(1): Password Complexity"

    # Check for password complexity requirements
    local policies=$(pwpolicy -getaccountpolicies 2>/dev/null)

    if echo "$policies" | grep -q "requiresAlpha\|requiresNumeric\|requiresSymbol"; then
        log_success "IA-5(1): Password complexity requirements configured"
        add_json_control "IA-5(1)" "Password Complexity" "PASS" "Complexity requirements found" "Password complexity enforced"
    else
        log_fail "IA-5(1): No password complexity requirements"
        add_json_control "IA-5(1)" "Password Complexity" "FAIL" "No complexity requirements" "Require alphanumeric + special characters in passwords"
    fi
}

################################################################################
# System and Communications Protection (SC) Family
################################################################################

check_sc_7_boundary_protection() {
    log_info "Checking SC-7: Boundary Protection (Firewall)"

    local firewall=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null || echo "0")

    if [ "$firewall" -ge 1 ]; then
        log_success "SC-7: Firewall enabled (state: $firewall)"
        add_json_control "SC-7" "Boundary Protection" "PASS" "Firewall state: $firewall" "Firewall properly configured"
    else
        log_fail "SC-7: Firewall disabled"
        add_json_control "SC-7" "Boundary Protection" "FAIL" "Firewall disabled" "Enable firewall: System Preferences → Security → Firewall"
    fi
}

check_sc_8_transmission_confidentiality() {
    log_info "Checking SC-8: Transmission Confidentiality (SSL/TLS)"

    # Check SSL/TLS protocol version
    local tls_min=$(defaults read /Library/Preferences/com.apple.networkextension MinimumTLSVersion 2>/dev/null || echo "unknown")

    log_info "SC-8: Minimum TLS version: $tls_min"
    add_json_control "SC-8" "Transmission Confidentiality" "INFO" "TLS version: $tls_min" "Ensure TLS 1.2+ is enforced for network communications"
}

check_sc_13_cryptographic_protection() {
    log_info "Checking SC-13: Cryptographic Protection"

    # Check FileVault encryption algorithm
    local fv_status=$(fdesetup status)

    if echo "$fv_status" | grep -q "FileVault is On"; then
        log_success "SC-13: Disk encryption active (XTS-AES-128)"
        add_json_control "SC-13" "Cryptographic Protection" "PASS" "FileVault encryption active" "FIPS 140-2 compliant encryption in use"
    else
        log_fail "SC-13: Disk encryption not active"
        add_json_control "SC-13" "Cryptographic Protection" "FAIL" "No disk encryption" "Enable FileVault for FIPS-compliant encryption"
    fi
}

check_sc_28_protection_of_info_at_rest() {
    log_info "Checking SC-28: Protection of Information at Rest"

    local fv_enabled=$(fdesetup status | grep -i "on" | wc -l)

    if [ "$fv_enabled" -gt 0 ]; then
        log_success "SC-28: Data at rest encrypted (FileVault)"
        add_json_control "SC-28" "Protection of Information at Rest" "PASS" "FileVault encryption active" "Data at rest properly protected"
    else
        log_fail "SC-28: Data at rest not encrypted"
        add_json_control "SC-28" "Protection of Information at Rest" "FAIL" "No disk encryption" "Enable FileVault to encrypt data at rest"
    fi
}

################################################################################
# System and Information Integrity (SI) Family
################################################################################

check_si_2_flaw_remediation() {
    log_info "Checking SI-2: Flaw Remediation (Software Updates)"

    local auto_update=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null || echo "0")
    local auto_install=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload 2>/dev/null || echo "0")

    if [ "$auto_update" == "1" ] && [ "$auto_install" == "1" ]; then
        log_success "SI-2: Automatic updates enabled"
        add_json_control "SI-2" "Flaw Remediation" "PASS" "Auto-update and auto-install enabled" "Software updates properly configured"
    else
        log_fail "SI-2: Automatic updates not fully configured"
        add_json_control "SI-2" "Flaw Remediation" "FAIL" "Auto-update: $auto_update, Auto-install: $auto_install" "Enable automatic software updates: System Preferences → Software Update"
    fi
}

check_si_3_malicious_code_protection() {
    log_info "Checking SI-3: Malicious Code Protection"

    # Check Gatekeeper
    local gatekeeper=$(spctl --status 2>/dev/null | grep -i "enabled" | wc -l)

    # Check XProtect (built-in anti-malware)
    local xprotect=$(defaults read /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist Version 2>/dev/null || echo "unknown")

    if [ "$gatekeeper" -gt 0 ]; then
        log_success "SI-3: Gatekeeper enabled, XProtect version: $xprotect"
        add_json_control "SI-3" "Malicious Code Protection" "PASS" "Gatekeeper enabled" "Anti-malware protection active"
    else
        log_fail "SI-3: Gatekeeper disabled"
        add_json_control "SI-3" "Malicious Code Protection" "FAIL" "Gatekeeper disabled" "Enable Gatekeeper: sudo spctl --master-enable"
    fi
}

check_si_4_information_system_monitoring() {
    log_info "Checking SI-4: Information System Monitoring"

    # Check for EDR/monitoring tools
    local crowdstrike=$(ps aux | grep -i falcon | grep -v grep | wc -l)
    local carbon_black=$(ps aux | grep -i "cb\|carbon" | grep -v grep | wc -l)
    local sentinel=$(ps aux | grep -i sentinel | grep -v grep | wc -l)

    if [ "$crowdstrike" -gt 0 ] || [ "$carbon_black" -gt 0 ] || [ "$sentinel" -gt 0 ]; then
        log_success "SI-4: EDR/monitoring software detected"
        add_json_control "SI-4" "Information System Monitoring" "PASS" "EDR software running" "System monitoring active"
    else
        log_warning "SI-4: No EDR/monitoring software detected"
        add_json_control "SI-4" "Information System Monitoring" "WARNING" "No EDR detected" "Deploy EDR solution (CrowdStrike, Carbon Black, Sentinel One, etc.)"
    fi
}

check_si_7_software_integrity() {
    log_info "Checking SI-7: Software and Information Integrity"

    # Check System Integrity Protection (SIP)
    local sip_status=$(csrutil status 2>/dev/null | grep -i "enabled" | wc -l)

    if [ "$sip_status" -gt 0 ]; then
        log_success "SI-7: System Integrity Protection (SIP) enabled"
        add_json_control "SI-7" "Software and Information Integrity" "PASS" "SIP enabled" "System integrity protection active"
    else
        log_fail "SI-7: System Integrity Protection (SIP) disabled"
        add_json_control "SI-7" "Software and Information Integrity" "FAIL" "SIP disabled" "Enable SIP by booting to Recovery Mode and running: csrutil enable"
    fi
}

################################################################################
# Media Protection (MP) Family
################################################################################

check_mp_7_media_use() {
    log_info "Checking MP-7: Media Use (External Media)"

    # Check if external media mounting is restricted
    local external_accounts=$(system_profiler SPUSBDataType 2>/dev/null | grep -i "Mass Storage" | wc -l)

    log_info "MP-7: $external_accounts external storage devices detected"
    add_json_control "MP-7" "Media Use" "INFO" "$external_accounts external devices" "Monitor and control external media usage via MDM policies"
}

################################################################################
# Physical and Environmental Protection (PE) Family
################################################################################

check_pe_3_physical_access_control() {
    log_info "Checking PE-3: Physical Access Control (Find My Mac)"

    # Check if Find My Mac is enabled
    local find_my=$(defaults read /Library/Preferences/com.apple.FindMyMac.plist FMMEnabled 2>/dev/null || echo "0")

    if [ "$find_my" == "1" ]; then
        log_success "PE-3: Find My Mac enabled"
        add_json_control "PE-3" "Physical Access Control" "PASS" "Find My Mac enabled" "Device tracking enabled"
    else
        log_warning "PE-3: Find My Mac not enabled"
        add_json_control "PE-3" "Physical Access Control" "WARNING" "Find My Mac disabled" "Enable Find My Mac for device tracking and remote wipe capability"
    fi
}

################################################################################
# System Inventory and Asset Management
################################################################################

collect_system_inventory() {
    log_info "Collecting system inventory..."

    local hostname=$(hostname)
    local serial=$(system_profiler SPHardwareDataType | grep "Serial Number" | awk '{print $NF}')
    local model=$(system_profiler SPHardwareDataType | grep "Model Name" | awk -F: '{print $2}' | xargs)
    local os_version=$(sw_vers -productVersion)
    local os_build=$(sw_vers -buildVersion)
    local cpu=$(sysctl -n machdep.cpu.brand_string)
    local memory=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}')
    local disk_size=$(diskutil info / | grep "Disk Size" | awk -F: '{print $2}' | xargs)

    log_info "System Inventory:"
    log_info "  Hostname: $hostname"
    log_info "  Serial: $serial"
    log_info "  Model: $model"
    log_info "  OS Version: $os_version ($os_build)"
    log_info "  CPU: $cpu"
    log_info "  Memory: $memory"
    log_info "  Disk: $disk_size"
}

################################################################################
# HTML Report Generation
################################################################################

generate_html_report() {
    log_info "Generating HTML report..."

    local compliance_score=$(echo "scale=2; ($PASSED_CHECKS * 100) / $TOTAL_CHECKS" | bc)
    local status_color="red"

    if (( $(echo "$compliance_score >= 90" | bc -l) )); then
        status_color="green"
    elif (( $(echo "$compliance_score >= 70" | bc -l) )); then
        status_color="orange"
    fi

    cat > "$REPORT_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NIST 800-53 Compliance Report - COMPANY_NAME_PLACEHOLDER</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f7fa;
            color: #2c3e50;
            line-height: 1.6;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }

        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }

        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }

        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            padding: 40px;
            background: #f8f9fa;
        }

        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }

        .summary-card h3 {
            color: #7f8c8d;
            font-size: 0.9em;
            text-transform: uppercase;
            margin-bottom: 10px;
        }

        .summary-card .value {
            font-size: 2.5em;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .summary-card.score .value {
            color: STATUS_COLOR_PLACEHOLDER;
        }

        .summary-card.passed .value {
            color: #27ae60;
        }

        .summary-card.failed .value {
            color: #e74c3c;
        }

        .summary-card.warnings .value {
            color: #f39c12;
        }

        .content {
            padding: 40px;
        }

        .section {
            margin-bottom: 40px;
        }

        .section h2 {
            color: #2c3e50;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
            margin-bottom: 20px;
            font-size: 1.8em;
        }

        .control {
            background: #f8f9fa;
            border-left: 4px solid #667eea;
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 5px;
            transition: all 0.3s ease;
        }

        .control:hover {
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            transform: translateX(5px);
        }

        .control.pass {
            border-left-color: #27ae60;
            background: #e8f8f5;
        }

        .control.fail {
            border-left-color: #e74c3c;
            background: #fadbd8;
        }

        .control.warning {
            border-left-color: #f39c12;
            background: #fef5e7;
        }

        .control-header {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }

        .control-id {
            font-weight: bold;
            color: #667eea;
            margin-right: 10px;
            font-size: 1.1em;
        }

        .control-name {
            font-weight: 600;
            flex: 1;
        }

        .status-badge {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: bold;
            text-transform: uppercase;
        }

        .status-badge.pass {
            background: #27ae60;
            color: white;
        }

        .status-badge.fail {
            background: #e74c3c;
            color: white;
        }

        .status-badge.warning {
            background: #f39c12;
            color: white;
        }

        .control-details {
            margin-top: 10px;
            padding-left: 20px;
        }

        .control-details p {
            margin-bottom: 8px;
        }

        .control-details strong {
            color: #34495e;
        }

        .recommendation {
            background: #fff3cd;
            border-left: 3px solid #ffc107;
            padding: 10px 15px;
            margin-top: 10px;
            border-radius: 4px;
        }

        .recommendation strong {
            color: #856404;
        }

        .footer {
            background: #2c3e50;
            color: white;
            text-align: center;
            padding: 30px;
        }

        .system-info {
            background: #ecf0f1;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 30px;
        }

        .system-info h3 {
            margin-bottom: 15px;
            color: #2c3e50;
        }

        .system-info table {
            width: 100%;
            border-collapse: collapse;
        }

        .system-info td {
            padding: 8px;
            border-bottom: 1px solid #bdc3c7;
        }

        .system-info td:first-child {
            font-weight: bold;
            width: 200px;
            color: #34495e;
        }

        @media print {
            body {
                background: white;
            }
            .container {
                box-shadow: none;
            }
            .control:hover {
                transform: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 NIST 800-53 Compliance Report</h1>
            <p>COMPANY_NAME_PLACEHOLDER Security Compliance Scan</p>
            <p>TIMESTAMP_PLACEHOLDER</p>
        </div>

        <div class="summary">
            <div class="summary-card score">
                <h3>Compliance Score</h3>
                <div class="value">COMPLIANCE_SCORE_PLACEHOLDER%</div>
                <p>Overall Rating</p>
            </div>
            <div class="summary-card passed">
                <h3>Passed</h3>
                <div class="value">PASSED_CHECKS_PLACEHOLDER</div>
                <p>Controls</p>
            </div>
            <div class="summary-card failed">
                <h3>Failed</h3>
                <div class="value">FAILED_CHECKS_PLACEHOLDER</div>
                <p>Controls</p>
            </div>
            <div class="summary-card warnings">
                <h3>Warnings</h3>
                <div class="value">WARNING_CHECKS_PLACEHOLDER</div>
                <p>Controls</p>
            </div>
        </div>

        <div class="content">
            <div class="system-info">
                <h3>System Information</h3>
                <table>
                    <tr>
                        <td>Hostname</td>
                        <td>HOSTNAME_PLACEHOLDER</td>
                    </tr>
                    <tr>
                        <td>macOS Version</td>
                        <td>OS_VERSION_PLACEHOLDER</td>
                    </tr>
                    <tr>
                        <td>Scan Date</td>
                        <td>SCAN_DATE_PLACEHOLDER</td>
                    </tr>
                    <tr>
                        <td>Scanned By</td>
                        <td>USER_PLACEHOLDER</td>
                    </tr>
                </table>
            </div>

            <div class="section">
                <h2>Compliance Findings</h2>
                CONTROLS_PLACEHOLDER
            </div>
        </div>

        <div class="footer">
            <p>&copy; YEAR_PLACEHOLDER COMPANY_NAME_PLACEHOLDER - NIST 800-53 Compliance Scanner v1.0.0</p>
            <p>Generated: TIMESTAMP_PLACEHOLDER</p>
        </div>
    </div>
</body>
</html>
HTMLEOF

    # Replace placeholders
    sed -i '' "s/COMPANY_NAME_PLACEHOLDER/$COMPANY_NAME/g" "$REPORT_FILE"
    sed -i '' "s/STATUS_COLOR_PLACEHOLDER/$status_color/g" "$REPORT_FILE"
    sed -i '' "s/COMPLIANCE_SCORE_PLACEHOLDER/$compliance_score/g" "$REPORT_FILE"
    sed -i '' "s/PASSED_CHECKS_PLACEHOLDER/$PASSED_CHECKS/g" "$REPORT_FILE"
    sed -i '' "s/FAILED_CHECKS_PLACEHOLDER/$FAILED_CHECKS/g" "$REPORT_FILE"
    sed -i '' "s/WARNING_CHECKS_PLACEHOLDER/$WARNING_CHECKS/g" "$REPORT_FILE"
    sed -i '' "s/HOSTNAME_PLACEHOLDER/$(hostname)/g" "$REPORT_FILE"
    sed -i '' "s/OS_VERSION_PLACEHOLDER/$(sw_vers -productVersion)/g" "$REPORT_FILE"
    sed -i '' "s/SCAN_DATE_PLACEHOLDER/$(date '+%Y-%m-%d %H:%M:%S')/g" "$REPORT_FILE"
    sed -i '' "s/USER_PLACEHOLDER/$(whoami)/g" "$REPORT_FILE"
    sed -i '' "s/TIMESTAMP_PLACEHOLDER/$(date '+%B %d, %Y at %H:%M:%S')/g" "$REPORT_FILE"
    sed -i '' "s/YEAR_PLACEHOLDER/$(date '+%Y')/g" "$REPORT_FILE"

    log_success "HTML report generated: $REPORT_FILE"
}

################################################################################
# Main Execution
################################################################################

main() {
    log "========================================="
    log "NIST 800-53 Compliance Scanner"
    log "$COMPANY_NAME"
    log "Version: $SCAN_VERSION"
    log "========================================="
    log ""

    # Initialize JSON report
    init_json_report

    # System Inventory
    collect_system_inventory
    log ""

    # Access Control (AC)
    log "========================================="
    log "ACCESS CONTROL (AC) FAMILY"
    log "========================================="
    check_ac_2_account_management
    check_ac_7_unsuccessful_login_attempts
    check_ac_8_system_use_notification
    check_ac_11_session_lock
    check_ac_17_remote_access
    log ""

    # Audit and Accountability (AU)
    log "========================================="
    log "AUDIT AND ACCOUNTABILITY (AU) FAMILY"
    log "========================================="
    check_au_2_audit_events
    check_au_3_audit_records
    check_au_9_protection_of_audit_info
    log ""

    # Configuration Management (CM)
    log "========================================="
    log "CONFIGURATION MANAGEMENT (CM) FAMILY"
    log "========================================="
    check_cm_6_configuration_settings
    check_cm_7_least_functionality
    log ""

    # Identification and Authentication (IA)
    log "========================================="
    log "IDENTIFICATION AND AUTHENTICATION (IA) FAMILY"
    log "========================================="
    check_ia_2_identification_authentication
    check_ia_5_authenticator_management
    check_ia_5_1_password_complexity
    log ""

    # System and Communications Protection (SC)
    log "========================================="
    log "SYSTEM AND COMMUNICATIONS PROTECTION (SC) FAMILY"
    log "========================================="
    check_sc_7_boundary_protection
    check_sc_8_transmission_confidentiality
    check_sc_13_cryptographic_protection
    check_sc_28_protection_of_info_at_rest
    log ""

    # System and Information Integrity (SI)
    log "========================================="
    log "SYSTEM AND INFORMATION INTEGRITY (SI) FAMILY"
    log "========================================="
    check_si_2_flaw_remediation
    check_si_3_malicious_code_protection
    check_si_4_information_system_monitoring
    check_si_7_software_integrity
    log ""

    # Media Protection (MP)
    log "========================================="
    log "MEDIA PROTECTION (MP) FAMILY"
    log "========================================="
    check_mp_7_media_use
    log ""

    # Physical and Environmental Protection (PE)
    log "========================================="
    log "PHYSICAL AND ENVIRONMENTAL PROTECTION (PE) FAMILY"
    log "========================================="
    check_pe_3_physical_access_control
    log ""

    # Finalize JSON report
    finalize_json_report

    # Generate HTML report
    generate_html_report

    # Final Summary
    local compliance_score=$(echo "scale=2; ($PASSED_CHECKS * 100) / $TOTAL_CHECKS" | bc)

    log "========================================="
    log "SCAN COMPLETE"
    log "========================================="
    log "Total Checks: $TOTAL_CHECKS"
    log_success "Passed: $PASSED_CHECKS"
    log_fail "Failed: $FAILED_CHECKS"
    log_warning "Warnings: $WARNING_CHECKS"
    log ""
    log "Compliance Score: ${compliance_score}%"
    log ""
    log "Reports generated:"
    log "  HTML: $REPORT_FILE"
    log "  JSON: $JSON_REPORT"
    log "  Log:  $LOG_FILE"
    log ""
    log "To view HTML report:"
    log "  open \"$REPORT_FILE\""
    log "========================================="

    # Open report automatically
    open "$REPORT_FILE" 2>/dev/null || true
}

# Run main function
main "$@"
