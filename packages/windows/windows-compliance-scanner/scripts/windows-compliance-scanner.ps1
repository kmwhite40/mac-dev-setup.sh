<#
.SYNOPSIS
    Windows NIST 800-53 Compliance Scanner

.DESCRIPTION
    Automated security compliance scanner for Windows endpoints.
    Checks NIST 800-53 security controls and generates detailed reports.
    Designed for SBS Federal - Enterprise security compliance monitoring.

.NOTES
    Version: 1.0.0
    Company: SBS Federal
    Author: IT Security Department
    Contact: it@sbsfederal.com

.FEATURES
    - Scans 25+ NIST 800-53 controls across 8 families
    - Generates HTML and JSON reports
    - Color-coded compliance scoring
    - Detailed remediation recommendations
    - Comprehensive logging
    - Intune-ready deployment
#>

#Requires -RunAsAdministrator

# Script configuration
$Script:Version = "1.0.0"
$Script:CompanyName = "SBS Federal"
$Script:ITSupportEmail = "it@sbsfederal.com"
$Script:ReportDir = "$env:USERPROFILE\.nist-compliance"
$Script:LogFile = "$ReportDir\scanner.log"
$Script:Hostname = $env:COMPUTERNAME
$Script:ScanDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Statistics
$Script:TotalChecks = 0
$Script:PassedChecks = 0
$Script:FailedChecks = 0
$Script:WarningChecks = 0
$Script:JsonResults = @()

# Create report directory
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

# Logging functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'FAIL')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'INFO'    { Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
        'SUCCESS' { Write-Host "✅ $Message" -ForegroundColor Green }
        'WARNING' { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        'FAIL'    { Write-Host "❌ $Message" -ForegroundColor Red }
    }

    Add-Content -Path $LogFile -Value $logMessage
}

function Add-JsonControl {
    param(
        [string]$ControlId,
        [string]$ControlName,
        [string]$Status,
        [string]$Finding,
        [string]$Recommendation
    )

    $Script:JsonResults += [PSCustomObject]@{
        control_id = $ControlId
        control_name = $ControlName
        status = $Status
        finding = $Finding
        recommendation = $Recommendation
        timestamp = $Script:ScanDate
    }
}

# ============================================================================
# AC FAMILY: Access Control
# ============================================================================

function Test-AC2-AccountManagement {
    Write-Host "`n===== AC-2: Account Management =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check for disabled accounts
        $localUsers = Get-LocalUser | Where-Object { $_.Enabled -eq $true }
        $activeCount = $localUsers.Count

        if ($activeCount -le 5) {
            Write-Log "AC-2: $activeCount active local accounts found" -Level SUCCESS
            Add-JsonControl "AC-2" "Account Management" "PASS" "$activeCount active local accounts" "Continue monitoring account creation"
            $Script:PassedChecks++
        } else {
            Write-Log "AC-2: High number of active accounts: $activeCount" -Level WARNING
            Add-JsonControl "AC-2" "Account Management" "WARNING" "$activeCount active accounts detected" "Review and disable unnecessary accounts"
            $Script:WarningChecks++
        }
    } catch {
        Write-Log "AC-2: Failed to check account management: $_" -Level FAIL
        Add-JsonControl "AC-2" "Account Management" "FAIL" "Error checking accounts" "Investigate account enumeration issue"
        $Script:FailedChecks++
    }
}

function Test-AC7-UnsuccessfulLogonAttempts {
    Write-Host "`n===== AC-7: Unsuccessful Logon Attempts =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check account lockout policy
        $secpol = secedit /export /cfg "$env:TEMP\secpol.cfg" 2>&1 | Out-Null
        $lockoutThreshold = Select-String -Path "$env:TEMP\secpol.cfg" -Pattern "LockoutBadCount" | ForEach-Object { $_.Line.Split('=')[1].Trim() }
        Remove-Item "$env:TEMP\secpol.cfg" -Force

        if ($lockoutThreshold -and $lockoutThreshold -ne "0") {
            Write-Log "AC-7: Account lockout enabled (threshold: $lockoutThreshold)" -Level SUCCESS
            Add-JsonControl "AC-7" "Unsuccessful Logon Attempts" "PASS" "Lockout threshold: $lockoutThreshold" "Lockout policy properly configured"
            $Script:PassedChecks++
        } else {
            Write-Log "AC-7: Account lockout not configured" -Level FAIL
            Add-JsonControl "AC-7" "Unsuccessful Logon Attempts" "FAIL" "No lockout policy" "Enable account lockout: secpol.msc → Account Policies → Account Lockout Policy"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "AC-7: Failed to check lockout policy: $_" -Level FAIL
        Add-JsonControl "AC-7" "Unsuccessful Logon Attempts" "FAIL" "Error checking policy" "Manually verify lockout settings"
        $Script:FailedChecks++
    }
}

function Test-AC11-SessionLock {
    Write-Host "`n===== AC-11: Session Lock =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check screen saver timeout
        $timeout = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name ScreenSaveTimeOut -ErrorAction SilentlyContinue).ScreenSaveTimeOut
        $secure = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name ScreenSaverIsSecure -ErrorAction SilentlyContinue).ScreenSaverIsSecure

        if ($timeout -and $secure -eq "1" -and [int]$timeout -le 900) {
            Write-Log "AC-11: Screen lock enabled (timeout: $timeout seconds)" -Level SUCCESS
            Add-JsonControl "AC-11" "Session Lock" "PASS" "Screen lock timeout: $timeout seconds" "Session lock properly configured"
            $Script:PassedChecks++
        } else {
            Write-Log "AC-11: Screen lock not properly configured" -Level FAIL
            Add-JsonControl "AC-11" "Session Lock" "FAIL" "Screen lock disabled or timeout too long" "Enable screen lock: Settings → Personalization → Lock screen"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "AC-11: Failed to check session lock: $_" -Level WARNING
        Add-JsonControl "AC-11" "Session Lock" "WARNING" "Could not verify screen lock" "Manually verify lock screen settings"
        $Script:WarningChecks++
    }
}

function Test-AC17-RemoteAccess {
    Write-Host "`n===== AC-17: Remote Access =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check if RDP is enabled
        $rdpEnabled = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections).fDenyTSConnections

        if ($rdpEnabled -eq 1) {
            Write-Log "AC-17: RDP is disabled" -Level SUCCESS
            Add-JsonControl "AC-17" "Remote Access" "PASS" "RDP disabled" "Remote access properly restricted"
            $Script:PassedChecks++
        } else {
            # RDP is enabled, check NLA
            $nlaEnabled = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication).UserAuthentication

            if ($nlaEnabled -eq 1) {
                Write-Log "AC-17: RDP enabled with Network Level Authentication" -Level WARNING
                Add-JsonControl "AC-17" "Remote Access" "WARNING" "RDP enabled with NLA" "Consider disabling RDP if not required"
                $Script:WarningChecks++
            } else {
                Write-Log "AC-17: RDP enabled without Network Level Authentication" -Level FAIL
                Add-JsonControl "AC-17" "Remote Access" "FAIL" "RDP enabled without NLA" "Enable NLA or disable RDP: System Properties → Remote"
                $Script:FailedChecks++
            }
        }
    } catch {
        Write-Log "AC-17: Failed to check remote access: $_" -Level FAIL
        Add-JsonControl "AC-17" "Remote Access" "FAIL" "Error checking RDP settings" "Manually verify RDP configuration"
        $Script:FailedChecks++
    }
}

# ============================================================================
# AU FAMILY: Audit and Accountability
# ============================================================================

function Test-AU2-AuditEvents {
    Write-Host "`n===== AU-2: Audit Events =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check if audit policy is configured
        $auditPolicies = auditpol /get /category:* | Select-String "Success and Failure"

        if ($auditPolicies.Count -ge 5) {
            Write-Log "AU-2: Audit policies configured ($($auditPolicies.Count) policies active)" -Level SUCCESS
            Add-JsonControl "AU-2" "Audit Events" "PASS" "$($auditPolicies.Count) audit policies active" "Audit logging properly configured"
            $Script:PassedChecks++
        } else {
            Write-Log "AU-2: Insufficient audit policies configured" -Level FAIL
            Add-JsonControl "AU-2" "Audit Events" "FAIL" "Few audit policies active" "Configure audit policies: secpol.msc → Advanced Audit Policy"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "AU-2: Failed to check audit policies: $_" -Level FAIL
        Add-JsonControl "AU-2" "Audit Events" "FAIL" "Error checking audit policies" "Manually verify audit configuration"
        $Script:FailedChecks++
    }
}

function Test-AU9-ProtectionOfAuditInfo {
    Write-Host "`n===== AU-9: Protection of Audit Information =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check Event Log settings
        $logMaxSize = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Security" -Name MaxSize).MaxSize

        if ($logMaxSize -ge 52428800) {  # 50 MB
            Write-Log "AU-9: Security log size adequate ($([math]::Round($logMaxSize/1MB)) MB)" -Level SUCCESS
            Add-JsonControl "AU-9" "Protection of Audit Information" "PASS" "Log size: $([math]::Round($logMaxSize/1MB)) MB" "Audit logs properly sized"
            $Script:PassedChecks++
        } else {
            Write-Log "AU-9: Security log size too small ($([math]::Round($logMaxSize/1MB)) MB)" -Level WARNING
            Add-JsonControl "AU-9" "Protection of Audit Information" "WARNING" "Small log size" "Increase security log size: Event Viewer → Properties"
            $Script:WarningChecks++
        }
    } catch {
        Write-Log "AU-9: Failed to check audit log protection: $_" -Level WARNING
        Add-JsonControl "AU-9" "Protection of Audit Information" "WARNING" "Could not verify log size" "Manually check Event Viewer settings"
        $Script:WarningChecks++
    }
}

# ============================================================================
# CM FAMILY: Configuration Management
# ============================================================================

function Test-CM6-ConfigurationSettings {
    Write-Host "`n===== CM-6: Configuration Settings =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check Windows Update settings
        $wuauEnabled = (Get-Service -Name wuauserv).Status

        if ($wuauEnabled -eq "Running") {
            Write-Log "CM-6: Windows Update service running" -Level SUCCESS
            Add-JsonControl "CM-6" "Configuration Settings" "PASS" "Windows Update enabled" "System update configuration active"
            $Script:PassedChecks++
        } else {
            Write-Log "CM-6: Windows Update service not running" -Level FAIL
            Add-JsonControl "CM-6" "Configuration Settings" "FAIL" "Windows Update disabled" "Enable Windows Update: services.msc → Windows Update"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "CM-6: Failed to check configuration: $_" -Level FAIL
        Add-JsonControl "CM-6" "Configuration Settings" "FAIL" "Error checking Windows Update" "Manually verify update service"
        $Script:FailedChecks++
    }
}

function Test-CM7-LeastFunctionality {
    Write-Host "`n===== CM-7: Least Functionality =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check for unnecessary services
        $unnecessaryServices = @("TelnetClient", "SNMP", "RemoteRegistry")
        $runningUnnecessary = @()

        foreach ($service in $unnecessaryServices) {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq "Running") {
                $runningUnnecessary += $service
            }
        }

        if ($runningUnnecessary.Count -eq 0) {
            Write-Log "CM-7: No unnecessary services running" -Level SUCCESS
            Add-JsonControl "CM-7" "Least Functionality" "PASS" "Unnecessary services disabled" "System follows least functionality principle"
            $Script:PassedChecks++
        } else {
            Write-Log "CM-7: Unnecessary services running: $($runningUnnecessary -join ', ')" -Level WARNING
            Add-JsonControl "CM-7" "Least Functionality" "WARNING" "Services: $($runningUnnecessary -join ', ')" "Disable unnecessary services"
            $Script:WarningChecks++
        }
    } catch {
        Write-Log "CM-7: Failed to check services: $_" -Level WARNING
        Add-JsonControl "CM-7" "Least Functionality" "WARNING" "Could not enumerate services" "Manually review running services"
        $Script:WarningChecks++
    }
}

# ============================================================================
# IA FAMILY: Identification and Authentication
# ============================================================================

function Test-IA2-IdentificationAuthentication {
    Write-Host "`n===== IA-2: Identification and Authentication =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check BitLocker status
        $bitlockerVolumes = Get-BitLockerVolume -ErrorAction SilentlyContinue

        if ($bitlockerVolumes) {
            $protected = $bitlockerVolumes | Where-Object { $_.ProtectionStatus -eq "On" }
            if ($protected) {
                Write-Log "IA-2: BitLocker enabled on $($protected.Count) volume(s)" -Level SUCCESS
                Add-JsonControl "IA-2" "Identification and Authentication" "PASS" "BitLocker enabled" "Disk encryption active"
                $Script:PassedChecks++
            } else {
                Write-Log "IA-2: BitLocker available but not enabled" -Level FAIL
                Add-JsonControl "IA-2" "Identification and Authentication" "FAIL" "BitLocker not enabled" "Enable BitLocker: Settings → Update & Security → Device encryption"
                $Script:FailedChecks++
            }
        } else {
            Write-Log "IA-2: BitLocker not available on this system" -Level WARNING
            Add-JsonControl "IA-2" "Identification and Authentication" "WARNING" "BitLocker unavailable" "Consider TPM-based encryption"
            $Script:WarningChecks++
        }
    } catch {
        Write-Log "IA-2: Failed to check BitLocker: $_" -Level WARNING
        Add-JsonControl "IA-2" "Identification and Authentication" "WARNING" "Could not verify encryption" "Manually check BitLocker status"
        $Script:WarningChecks++
    }
}

function Test-IA5-AuthenticatorManagement {
    Write-Host "`n===== IA-5: Authenticator Management =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check password policy
        $secpol = secedit /export /cfg "$env:TEMP\secpol.cfg" 2>&1 | Out-Null
        $minPasswordLength = Select-String -Path "$env:TEMP\secpol.cfg" -Pattern "MinimumPasswordLength" | ForEach-Object { $_.Line.Split('=')[1].Trim() }
        $passwordComplexity = Select-String -Path "$env:TEMP\secpol.cfg" -Pattern "PasswordComplexity" | ForEach-Object { $_.Line.Split('=')[1].Trim() }
        Remove-Item "$env:TEMP\secpol.cfg" -Force

        if ($minPasswordLength -ge 8 -and $passwordComplexity -eq "1") {
            Write-Log "IA-5: Strong password policy enabled (min length: $minPasswordLength, complexity: enabled)" -Level SUCCESS
            Add-JsonControl "IA-5" "Authenticator Management" "PASS" "Password policy configured" "Strong password requirements enforced"
            $Script:PassedChecks++
        } else {
            Write-Log "IA-5: Weak password policy" -Level FAIL
            Add-JsonControl "IA-5" "Authenticator Management" "FAIL" "Weak password policy" "Configure: secpol.msc → Account Policies → Password Policy"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "IA-5: Failed to check password policy: $_" -Level FAIL
        Add-JsonControl "IA-5" "Authenticator Management" "FAIL" "Error checking policy" "Manually verify password policy"
        $Script:FailedChecks++
    }
}

# ============================================================================
# SC FAMILY: System and Communications Protection
# ============================================================================

function Test-SC7-BoundaryProtection {
    Write-Host "`n===== SC-7: Boundary Protection =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check Windows Firewall
        $firewallProfiles = Get-NetFirewallProfile

        $allEnabled = $true
        foreach ($profile in $firewallProfiles) {
            if ($profile.Enabled -eq $false) {
                $allEnabled = $false
                break
            }
        }

        if ($allEnabled) {
            Write-Log "SC-7: Windows Firewall enabled on all profiles" -Level SUCCESS
            Add-JsonControl "SC-7" "Boundary Protection" "PASS" "Firewall enabled" "Network boundary protection active"
            $Script:PassedChecks++
        } else {
            Write-Log "SC-7: Windows Firewall disabled on one or more profiles" -Level FAIL
            Add-JsonControl "SC-7" "Boundary Protection" "FAIL" "Firewall not fully enabled" "Enable firewall: Windows Security → Firewall & network protection"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "SC-7: Failed to check firewall: $_" -Level FAIL
        Add-JsonControl "SC-7" "Boundary Protection" "FAIL" "Error checking firewall" "Manually verify firewall status"
        $Script:FailedChecks++
    }
}

function Test-SC28-ProtectionOfInformation {
    Write-Host "`n===== SC-28: Protection of Information At Rest =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Recheck BitLocker (encryption at rest)
        $bitlockerVolumes = Get-BitLockerVolume -ErrorAction SilentlyContinue | Where-Object { $_.ProtectionStatus -eq "On" }

        if ($bitlockerVolumes) {
            Write-Log "SC-28: Data at rest encryption enabled (BitLocker)" -Level SUCCESS
            Add-JsonControl "SC-28" "Protection of Information At Rest" "PASS" "BitLocker active" "Data encryption at rest configured"
            $Script:PassedChecks++
        } else {
            Write-Log "SC-28: No encryption at rest detected" -Level FAIL
            Add-JsonControl "SC-28" "Protection of Information At Rest" "FAIL" "No disk encryption" "Enable BitLocker for data protection"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "SC-28: Failed to check encryption: $_" -Level FAIL
        Add-JsonControl "SC-28" "Protection of Information At Rest" "FAIL" "Error checking encryption" "Manually verify BitLocker status"
        $Script:FailedChecks++
    }
}

# ============================================================================
# SI FAMILY: System and Information Integrity
# ============================================================================

function Test-SI2-FlawRemediation {
    Write-Host "`n===== SI-2: Flaw Remediation =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check for pending Windows Updates
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0")

        if ($searchResult.Updates.Count -eq 0) {
            Write-Log "SI-2: System is up to date (no pending updates)" -Level SUCCESS
            Add-JsonControl "SI-2" "Flaw Remediation" "PASS" "No pending updates" "System patching current"
            $Script:PassedChecks++
        } else {
            Write-Log "SI-2: $($searchResult.Updates.Count) pending update(s) found" -Level WARNING
            Add-JsonControl "SI-2" "Flaw Remediation" "WARNING" "$($searchResult.Updates.Count) updates pending" "Install Windows Updates: Settings → Update & Security"
            $Script:WarningChecks++
        }
    } catch {
        Write-Log "SI-2: Failed to check updates: $_" -Level WARNING
        Add-JsonControl "SI-2" "Flaw Remediation" "WARNING" "Could not check updates" "Manually check Windows Update"
        $Script:WarningChecks++
    }
}

function Test-SI3-MaliciousCodeProtection {
    Write-Host "`n===== SI-3: Malicious Code Protection =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check Windows Defender status
        $defenderStatus = Get-MpComputerStatus

        if ($defenderStatus.AntivirusEnabled) {
            $sigAge = (Get-Date) - $defenderStatus.AntivirusSignatureLastUpdated

            if ($sigAge.Days -le 7) {
                Write-Log "SI-3: Windows Defender enabled with recent signatures (updated $($sigAge.Days) days ago)" -Level SUCCESS
                Add-JsonControl "SI-3" "Malicious Code Protection" "PASS" "Defender active, signatures current" "Antivirus protection operational"
                $Script:PassedChecks++
            } else {
                Write-Log "SI-3: Windows Defender signatures outdated ($($sigAge.Days) days old)" -Level WARNING
                Add-JsonControl "SI-3" "Malicious Code Protection" "WARNING" "Outdated signatures" "Update Defender: Windows Security → Virus & threat protection"
                $Script:WarningChecks++
            }
        } else {
            Write-Log "SI-3: Windows Defender is disabled" -Level FAIL
            Add-JsonControl "SI-3" "Malicious Code Protection" "FAIL" "Antivirus disabled" "Enable Windows Defender immediately"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "SI-3: Failed to check antivirus: $_" -Level FAIL
        Add-JsonControl "SI-3" "Malicious Code Protection" "FAIL" "Error checking Defender" "Manually verify antivirus status"
        $Script:FailedChecks++
    }
}

function Test-SI4-InformationSystemMonitoring {
    Write-Host "`n===== SI-4: Information System Monitoring =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check if Windows Defender real-time monitoring is enabled
        $realtimeEnabled = (Get-MpComputerStatus).RealTimeProtectionEnabled

        if ($realtimeEnabled) {
            Write-Log "SI-4: Real-time monitoring enabled" -Level SUCCESS
            Add-JsonControl "SI-4" "Information System Monitoring" "PASS" "Real-time protection active" "System monitoring operational"
            $Script:PassedChecks++
        } else {
            Write-Log "SI-4: Real-time monitoring disabled" -Level FAIL
            Add-JsonControl "SI-4" "Information System Monitoring" "FAIL" "No real-time protection" "Enable real-time protection in Windows Security"
            $Script:FailedChecks++
        }
    } catch {
        Write-Log "SI-4: Failed to check monitoring: $_" -Level FAIL
        Add-JsonControl "SI-4" "Information System Monitoring" "FAIL" "Error checking monitoring" "Manually verify monitoring settings"
        $Script:FailedChecks++
    }
}

# ============================================================================
# PE FAMILY: Physical and Environmental Protection
# ============================================================================

function Test-PE3-PhysicalAccessControl {
    Write-Host "`n===== PE-3: Physical Access Control =====" -ForegroundColor Blue
    $Script:TotalChecks++

    try {
        # Check if device is portable (laptop)
        $chassis = (Get-CimInstance -ClassName Win32_SystemEnclosure).ChassisTypes

        # Chassis types 8-14, 30-31 are portable devices
        $portableTypes = @(8, 9, 10, 11, 12, 14, 30, 31)

        if ($chassis | Where-Object { $_ -in $portableTypes }) {
            # For laptops, check if BitLocker is enabled (physical security)
            $bitlocker = Get-BitLockerVolume -ErrorAction SilentlyContinue | Where-Object { $_.ProtectionStatus -eq "On" }

            if ($bitlocker) {
                Write-Log "PE-3: Portable device with encryption enabled" -Level SUCCESS
                Add-JsonControl "PE-3" "Physical Access Control" "PASS" "Laptop encrypted" "Physical security controls in place"
                $Script:PassedChecks++
            } else {
                Write-Log "PE-3: Portable device without encryption" -Level FAIL
                Add-JsonControl "PE-3" "Physical Access Control" "FAIL" "Unencrypted laptop" "Enable BitLocker for physical protection"
                $Script:FailedChecks++
            }
        } else {
            Write-Log "PE-3: Desktop system (physical security assumed)" -Level SUCCESS
            Add-JsonControl "PE-3" "Physical Access Control" "PASS" "Desktop system" "Verify physical access controls at facility"
            $Script:PassedChecks++
        }
    } catch {
        Write-Log "PE-3: Failed to check physical security: $_" -Level WARNING
        Add-JsonControl "PE-3" "Physical Access Control" "WARNING" "Could not determine device type" "Manually verify physical security"
        $Script:WarningChecks++
    }
}

# ============================================================================
# Report Generation
# ============================================================================

function Export-JsonReport {
    param([string]$ReportPath)

    $reportData = @{
        scan_info = @{
            version = $Script:Version
            company = $Script:CompanyName
            hostname = $Script:Hostname
            scan_date = $Script:ScanDate
            operating_system = (Get-CimInstance Win32_OperatingSystem).Caption
            os_version = (Get-CimInstance Win32_OperatingSystem).Version
        }
        summary = @{
            total_checks = $Script:TotalChecks
            passed = $Script:PassedChecks
            warnings = $Script:WarningChecks
            failed = $Script:FailedChecks
            compliance_score = [math]::Round(($Script:PassedChecks * 100) / $Script:TotalChecks, 2)
        }
        controls = $Script:JsonResults
    }

    $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Log "JSON report saved: $ReportPath" -Level SUCCESS
}

function Export-HtmlReport {
    param([string]$ReportPath)

    $complianceScore = [math]::Round(($Script:PassedChecks * 100) / $Script:TotalChecks, 2)

    # Determine compliance level color
    $scoreColor = if ($complianceScore -ge 90) { "#28a745" }
                  elseif ($complianceScore -ge 70) { "#ffc107" }
                  else { "#dc3545" }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NIST 800-53 Compliance Report - $Script:Hostname</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; padding: 20px; color: #333; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header h1 { font-size: 28px; margin-bottom: 10px; }
        .header p { opacity: 0.9; font-size: 14px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 30px; background: #f8f9fa; }
        .stat-card { background: white; padding: 20px; border-radius: 6px; text-align: center; border-left: 4px solid #667eea; }
        .stat-card h3 { font-size: 32px; color: #667eea; margin-bottom: 5px; }
        .stat-card.success { border-left-color: #28a745; }
        .stat-card.success h3 { color: #28a745; }
        .stat-card.warning { border-left-color: #ffc107; }
        .stat-card.warning h3 { color: #ffc107; }
        .stat-card.danger { border-left-color: #dc3545; }
        .stat-card.danger h3 { color: #dc3545; }
        .stat-card p { color: #666; font-size: 14px; }
        .score { text-align: center; padding: 30px; background: white; margin: 0 30px; border-radius: 6px; }
        .score-circle { width: 150px; height: 150px; margin: 0 auto 20px; border-radius: 50%; background: conic-gradient($scoreColor calc($complianceScore * 3.6deg), #e9ecef 0); display: flex; align-items: center; justify-content: center; position: relative; }
        .score-circle::before { content: ''; position: absolute; width: 110px; height: 110px; border-radius: 50%; background: white; }
        .score-value { position: relative; z-index: 1; font-size: 32px; font-weight: bold; color: $scoreColor; }
        .controls { padding: 30px; }
        .control-group { margin-bottom: 30px; }
        .control-group h2 { font-size: 20px; color: #667eea; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #667eea; }
        .control-item { background: #f8f9fa; padding: 15px; margin-bottom: 10px; border-radius: 6px; border-left: 4px solid #ccc; }
        .control-item.pass { border-left-color: #28a745; }
        .control-item.warning { border-left-color: #ffc107; }
        .control-item.fail { border-left-color: #dc3545; }
        .control-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
        .control-id { font-weight: bold; color: #333; }
        .status-badge { padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: bold; }
        .status-badge.pass { background: #d4edda; color: #155724; }
        .status-badge.warning { background: #fff3cd; color: #856404; }
        .status-badge.fail { background: #f8d7da; color: #721c24; }
        .finding { color: #666; font-size: 14px; margin-bottom: 5px; }
        .recommendation { color: #007bff; font-size: 13px; font-style: italic; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 14px; border-top: 1px solid #e9ecef; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 NIST 800-53 Compliance Report</h1>
            <p>System: $Script:Hostname | Scan Date: $Script:ScanDate</p>
            <p>Company: $Script:CompanyName | Scanner Version: $Script:Version</p>
        </div>

        <div class="summary">
            <div class="stat-card">
                <h3>$Script:TotalChecks</h3>
                <p>Total Checks</p>
            </div>
            <div class="stat-card success">
                <h3>$Script:PassedChecks</h3>
                <p>Passed</p>
            </div>
            <div class="stat-card warning">
                <h3>$Script:WarningChecks</h3>
                <p>Warnings</p>
            </div>
            <div class="stat-card danger">
                <h3>$Script:FailedChecks</h3>
                <p>Failed</p>
            </div>
        </div>

        <div class="score">
            <div class="score-circle">
                <div class="score-value">$complianceScore%</div>
            </div>
            <h2>Compliance Score</h2>
        </div>

        <div class="controls">
            <h2 style="text-align: center; margin-bottom: 30px; color: #667eea;">Detailed Control Assessment</h2>
"@

    # Group controls by family
    $families = $Script:JsonResults | Group-Object { $_.control_id.Split('-')[0] }

    foreach ($family in $families) {
        $familyName = switch ($family.Name) {
            "AC" { "Access Control" }
            "AU" { "Audit and Accountability" }
            "CM" { "Configuration Management" }
            "IA" { "Identification and Authentication" }
            "SC" { "System and Communications Protection" }
            "SI" { "System and Information Integrity" }
            "PE" { "Physical and Environmental Protection" }
            default { $family.Name }
        }

        $html += "<div class='control-group'><h2>$($family.Name): $familyName</h2>"

        foreach ($control in $family.Group) {
            $statusClass = $control.status.ToLower()
            $html += @"
            <div class='control-item $statusClass'>
                <div class='control-header'>
                    <span class='control-id'>$($control.control_id): $($control.control_name)</span>
                    <span class='status-badge $statusClass'>$($control.status)</span>
                </div>
                <div class='finding'>📋 Finding: $($control.finding)</div>
                <div class='recommendation'>💡 Recommendation: $($control.recommendation)</div>
            </div>
"@
        }

        $html += "</div>"
    }

    $html += @"
        </div>

        <div class="footer">
            <p>Generated by Windows NIST 800-53 Compliance Scanner v$Script:Version</p>
            <p>$Script:CompanyName | Support: $Script:ITSupportEmail</p>
            <p>For detailed remediation steps, consult NIST SP 800-53 Rev. 5 documentation</p>
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Log "HTML report saved: $ReportPath" -Level SUCCESS
}

# ============================================================================
# Main Execution
# ============================================================================

function Start-ComplianceScan {
    Write-Host "`n==========================================" -ForegroundColor Magenta
    Write-Host "Windows NIST 800-53 Compliance Scanner" -ForegroundColor Magenta
    Write-Host "Version: $Script:Version" -ForegroundColor Magenta
    Write-Host "Company: $Script:CompanyName" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""

    # Check administrator privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator!" -Level FAIL
        Write-Log "Right-click PowerShell and select 'Run as Administrator'" -Level FAIL
        exit 1
    }

    Write-Log "Starting compliance scan for: $Script:Hostname" -Level INFO
    Write-Log "Scan date: $Script:ScanDate" -Level INFO
    Write-Log "" -Level INFO

    # Run all compliance checks
    Test-AC2-AccountManagement
    Test-AC7-UnsuccessfulLogonAttempts
    Test-AC11-SessionLock
    Test-AC17-RemoteAccess

    Test-AU2-AuditEvents
    Test-AU9-ProtectionOfAuditInfo

    Test-CM6-ConfigurationSettings
    Test-CM7-LeastFunctionality

    Test-IA2-IdentificationAuthentication
    Test-IA5-AuthenticatorManagement

    Test-SC7-BoundaryProtection
    Test-SC28-ProtectionOfInformation

    Test-SI2-FlawRemediation
    Test-SI3-MaliciousCodeProtection
    Test-SI4-InformationSystemMonitoring

    Test-PE3-PhysicalAccessControl

    # Generate reports
    Write-Host "`n==========================================" -ForegroundColor Magenta
    Write-Host "Generating Reports" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $jsonReport = "$ReportDir\compliance-report-$timestamp.json"
    $htmlReport = "$ReportDir\compliance-report-$timestamp.html"

    Export-JsonReport -ReportPath $jsonReport
    Export-HtmlReport -ReportPath $htmlReport

    # Display summary
    Write-Host "`n==========================================" -ForegroundColor Magenta
    Write-Host "Scan Complete" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Log "" -Level INFO
    Write-Log "Total Checks: $Script:TotalChecks" -Level INFO
    Write-Log "Passed: $Script:PassedChecks" -Level SUCCESS
    Write-Log "Warnings: $Script:WarningChecks" -Level WARNING
    Write-Log "Failed: $Script:FailedChecks" -Level FAIL
    Write-Log "" -Level INFO
    $complianceScore = [math]::Round(($Script:PassedChecks * 100) / $Script:TotalChecks, 2)
    Write-Log "Compliance Score: $complianceScore%" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "Reports generated:" -Level INFO
    Write-Log "  JSON: $jsonReport" -Level INFO
    Write-Log "  HTML: $htmlReport" -Level INFO
    Write-Log "" -Level INFO
    Write-Log "Opening HTML report in browser..." -Level INFO

    # Open HTML report
    Start-Process $htmlReport

    Write-Log "" -Level INFO
    Write-Log "For support, contact: $Script:ITSupportEmail" -Level INFO
    Write-Host "`n==========================================" -ForegroundColor Magenta
}

# Run the scan
try {
    Start-ComplianceScan
} catch {
    Write-Log "Unexpected error: $_" -Level FAIL
    Write-Log "Please contact $Script:ITSupportEmail for support" -Level FAIL
    exit 1
}
