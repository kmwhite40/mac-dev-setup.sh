# iPad Intune Deployment - Complete Runbook

## Enterprise Deployment Runbook

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Quick Reference

| Item | Value |
|------|-------|
| Target Apps | Company Portal, Google Chrome |
| Enrollment Method | ABM + ADE (preferred) |
| Device Mode | Supervised |
| App Licensing | VPP Device Licensing |
| Minimum iPadOS | 16.0 |

---

## Table of Contents

1. [Pre-Checks](#pre-checks)
2. [New Device Enrollment](#new-device-enrollment)
3. [Existing Device Enrollment](#existing-device-enrollment)
4. [App Deployment Steps](#app-deployment-steps)
5. [Verification Steps](#verification-steps)
6. [Troubleshooting Decision Tree](#troubleshooting-decision-tree)

---

## Pre-Checks

### Pre-Check 1: ABM Verification

**Console:** https://business.apple.com

```
┌─────────────────────────────────────────────────────────────────┐
│ ABM PRE-CHECK                                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] 1.1 Sign in to Apple Business Manager                       │
│                                                                  │
│ [ ] 1.2 Verify MDM Server exists                                │
│         Settings > Device Management Settings                    │
│         MDM Server Name: Microsoft Intune                        │
│         Status: Active                                           │
│                                                                  │
│ [ ] 1.3 Verify Apps and Books                                   │
│         Apps and Books > Search "Intune Company Portal"         │
│         Licenses owned: _____ Available: _____                  │
│                                                                  │
│         Apps and Books > Search "Google Chrome"                 │
│         Licenses owned: _____ Available: _____                  │
│                                                                  │
│ [ ] 1.4 Verify token not expired                                │
│         Settings > Apps and Books                                │
│         Token expiration: _______________                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pre-Check 2: Intune Token Verification

**Console:** https://intune.microsoft.com

```
┌─────────────────────────────────────────────────────────────────┐
│ INTUNE TOKEN PRE-CHECK                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] 2.1 APNs Certificate                                        │
│         Tenant admin > Connectors > Apple MDM Push              │
│         Status: Active ✓                                        │
│         Expiration: _______________                              │
│         Days until expiry: _____                                │
│                                                                  │
│ [ ] 2.2 ADE Token                                               │
│         Devices > iOS enrollment > Enrollment program tokens    │
│         Token name: _______________                              │
│         Status: Active ✓                                        │
│         Last sync: _______________                               │
│         Expiration: _______________                              │
│                                                                  │
│ [ ] 2.3 VPP Token                                               │
│         Tenant admin > Connectors > Apple VPP tokens            │
│         Token name: _______________                              │
│         Status: Active ✓                                        │
│         Last sync: _______________                               │
│         Expiration: _______________                              │
│                                                                  │
│ [ ] 2.4 Sync all tokens                                         │
│         Click "Sync" on each token                              │
│         Wait for completion                                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pre-Check 3: Enrollment Profile Verification

**Console:** https://intune.microsoft.com

```
┌─────────────────────────────────────────────────────────────────┐
│ ENROLLMENT PROFILE PRE-CHECK                                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] 3.1 Navigate to enrollment profiles                         │
│         Devices > iOS enrollment > Enrollment program tokens    │
│         Select your token > Profiles                            │
│                                                                  │
│ [ ] 3.2 Verify profile settings                                 │
│         Profile name: _______________                            │
│         Supervised: YES ✓                                       │
│         Locked enrollment: YES ✓                                │
│         User affinity: _______________                           │
│         Await final configuration: YES ✓                        │
│                                                                  │
│ [ ] 3.3 If no profile exists, create one now                    │
│         (See Section: New Device Enrollment)                    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pre-Check 4: App Configuration Verification

**Console:** https://intune.microsoft.com

```
┌─────────────────────────────────────────────────────────────────┐
│ APP CONFIGURATION PRE-CHECK                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] 4.1 Verify Company Portal                                   │
│         Apps > iOS/iPadOS > Search "Company Portal"             │
│         App type: iOS store app (VPP) ✓                         │
│         License type: Device ✓                                  │
│         Assignment: Required ✓                                  │
│         Assigned group: _______________                          │
│                                                                  │
│ [ ] 4.2 Verify Chrome                                           │
│         Apps > iOS/iPadOS > Search "Chrome"                     │
│         App type: iOS store app (VPP) ✓                         │
│         License type: Device ✓                                  │
│         Assignment: Required ✓                                  │
│         Assigned group: _______________                          │
│                                                                  │
│ [ ] 4.3 Verify device group exists                              │
│         Groups > Search for iPad group                          │
│         Group name: _______________                              │
│         Members: Dynamic device                                  │
│                                                                  │
│ [ ] 4.4 If apps not configured, configure now                   │
│         (See Section: App Deployment Steps)                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pre-Check 5: No Blocking Profiles

**Console:** https://intune.microsoft.com

```
┌─────────────────────────────────────────────────────────────────┐
│ BLOCKING PROFILE PRE-CHECK                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] 5.1 Check for App Store restrictions                        │
│         Devices > Configuration profiles                        │
│         Filter: iOS/iPadOS                                      │
│                                                                  │
│ [ ] 5.2 For each Device Restrictions profile:                   │
│         Profile: _______________                                 │
│         Block App Store: NOT SET or NO ✓                        │
│                                                                  │
│         Profile: _______________                                 │
│         Block App Store: NOT SET or NO ✓                        │
│                                                                  │
│ [ ] 5.3 No profile blocks App Store                             │
│         If blocking found: MODIFY PROFILE FIRST                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## New Device Enrollment

### Procedure: Enroll New Device (ABM/ADE)

**Prerequisites:**
- Device in Apple Business Manager
- Device assigned to Intune MDM server in ABM
- Enrollment profile created with Supervised = Yes
- VPP apps configured with device licensing

**Steps:**

```
┌─────────────────────────────────────────────────────────────────┐
│ NEW DEVICE ENROLLMENT - ABM/ADE                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ STEP 1: VERIFY DEVICE IN ABM                                    │
│ ─────────────────────────────────────────────────────────────── │
│ [ ] 1.1 Get device serial number (on box or Settings > About)   │
│         Serial: _______________                                  │
│                                                                  │
│ [ ] 1.2 Search in ABM > Devices                                 │
│         Device found: YES / NO                                  │
│                                                                  │
│ [ ] 1.3 If NO: Device must be added via Configurator            │
│         (See Existing Device section)                           │
│                                                                  │
│ [ ] 1.4 If YES: Verify MDM server assignment                    │
│         MDM Server: Microsoft Intune ✓                          │
│                                                                  │
│                                                                  │
│ STEP 2: ASSIGN ENROLLMENT PROFILE (IF NOT ASSIGNED)             │
│ ─────────────────────────────────────────────────────────────── │
│ [ ] 2.1 In Intune:                                              │
│         Devices > iOS enrollment > Enrollment program tokens    │
│                                                                  │
│ [ ] 2.2 Select your token > Devices                             │
│                                                                  │
│ [ ] 2.3 Find device by serial > Check box                       │
│                                                                  │
│ [ ] 2.4 Click "Assign profile" > Select supervised profile      │
│                                                                  │
│ [ ] 2.5 Click "Assign"                                          │
│                                                                  │
│                                                                  │
│ STEP 3: UNBOX AND POWER ON DEVICE                               │
│ ─────────────────────────────────────────────────────────────── │
│ [ ] 3.1 Unbox new iPad                                          │
│                                                                  │
│ [ ] 3.2 Power on (hold top button)                              │
│                                                                  │
│ [ ] 3.3 Wait for Hello screen                                   │
│                                                                  │
│                                                                  │
│ STEP 4: COMPLETE SETUP ASSISTANT                                │
│ ─────────────────────────────────────────────────────────────── │
│ [ ] 4.1 Select Language > Continue                              │
│                                                                  │
│ [ ] 4.2 Select Country/Region > Continue                        │
│                                                                  │
│ [ ] 4.3 Connect to Wi-Fi                                        │
│         Network: _______________                                 │
│         Password: _______________                                │
│                                                                  │
│ [ ] 4.4 Wait for "Remote Management" screen                     │
│         Shows: "Your organization will automatically            │
│         configure your iPad"                                    │
│                                                                  │
│ [ ] 4.5 Tap "Continue" to accept management                     │
│         DO NOT tap "Don't use this configuration"               │
│                                                                  │
│ [ ] 4.6 Wait for enrollment to complete                         │
│         Progress indicator shows                                 │
│         May take 2-5 minutes                                    │
│                                                                  │
│ [ ] 4.7 Complete any remaining Setup screens                    │
│         (Most should be skipped by profile)                     │
│                                                                  │
│                                                                  │
│ STEP 5: VERIFY ENROLLMENT SUCCESS                               │
│ ─────────────────────────────────────────────────────────────── │
│ [ ] 5.1 Settings > General > About                              │
│         Shows "This iPad is supervised..." ✓                    │
│                                                                  │
│ [ ] 5.2 Settings > General > VPN & Device Management            │
│         MDM Profile from your org ✓                             │
│                                                                  │
│ [ ] 5.3 Wait for apps to install (5-15 minutes)                 │
│         Company Portal appears ✓                                │
│         Chrome appears ✓                                        │
│                                                                  │
│ [ ] 5.4 Open Company Portal - verify it works                   │
│                                                                  │
│ [ ] 5.5 Open Chrome - verify it works                           │
│                                                                  │
│                                                                  │
│ ENROLLMENT COMPLETE                                              │
│ Sign-off: _______________ Date: _______________                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Existing Device Enrollment

### Decision: Existing Device Path

```
┌─────────────────────────────────────────────────────────────────┐
│            EXISTING DEVICE DECISION                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Is device currently supervised?                                │
│  (Check: Settings > General > About)                            │
│                                                                  │
│         YES                              NO                      │
│          │                                │                      │
│          ▼                                ▼                      │
│  ┌─────────────────┐            ┌────────────────────┐          │
│  │ Is device       │            │ Is device in ABM?  │          │
│  │ enrolled in     │            │ (Check ABM portal) │          │
│  │ Intune?         │            └────────────────────┘          │
│  └─────────────────┘                   │         │              │
│     YES │    │ NO                     YES        NO             │
│         │    │                         │          │              │
│         ▼    ▼                         ▼          ▼              │
│  ┌──────┐ ┌──────┐             ┌─────────┐ ┌────────────┐       │
│  │PATH A│ │PATH B│             │ PATH C  │ │  PATH D    │       │
│  │Fix   │ │Re-   │             │ Wipe &  │ │  Add to    │       │
│  │Config│ │enroll│             │ Enroll  │ │  ABM via   │       │
│  │      │ │      │             │ via ADE │ │ Configurator│       │
│  └──────┘ └──────┘             └─────────┘ └────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### PATH A: Device Supervised & In Intune (Fix Configuration)

**Use when:** Device is properly enrolled but apps not installing

```
┌─────────────────────────────────────────────────────────────────┐
│ PATH A: FIX CONFIGURATION (No Wipe)                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] A.1 Diagnose the issue                                      │
│         (See 01-DIAGNOSIS-GUIDE.md)                             │
│         Issue identified: _______________                        │
│                                                                  │
│ [ ] A.2 Fix restriction profiles (if applicable)                │
│         Intune > Configuration profiles                         │
│         Remove/modify blocking profile                          │
│                                                                  │
│ [ ] A.3 Verify VPP app configuration                            │
│         Apps > [App] > Assignments                              │
│         License type: Device ✓                                  │
│         Assignment: Required ✓                                  │
│         Group includes device ✓                                 │
│                                                                  │
│ [ ] A.4 Force sync                                              │
│         Intune > Devices > [Device] > Sync                      │
│         Wait 5-15 minutes                                       │
│                                                                  │
│ [ ] A.5 Verify apps installed                                   │
│         Company Portal visible ✓                                │
│         Chrome visible ✓                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### PATH B: Device Supervised, Not in Intune (Re-enroll)

**Use when:** Device shows supervised but not in Intune console

```
┌─────────────────────────────────────────────────────────────────┐
│ PATH B: RE-ENROLL SUPERVISED DEVICE                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] B.1 Check for existing MDM profile                          │
│         Settings > General > VPN & Device Management            │
│                                                                  │
│ [ ] B.2 If MDM profile from another org:                        │
│         Tap profile > Remove Management (if available)          │
│         If not removable: Factory reset required (PATH C)       │
│                                                                  │
│ [ ] B.3 If no MDM or MDM removed:                               │
│         Open Safari on device                                    │
│         Go to: https://portal.manage.microsoft.com/enrollment   │
│         Follow enrollment prompts                               │
│                                                                  │
│ [ ] B.4 Complete Intune enrollment                              │
│         Sign in with corporate account                          │
│         Accept management                                        │
│                                                                  │
│ [ ] B.5 Verify enrollment                                       │
│         Device appears in Intune ✓                              │
│         Apps push automatically ✓                               │
│                                                                  │
│ NOTE: Re-enrollment via portal may NOT preserve supervision     │
│ For full supervision: Use PATH C (wipe and ADE)                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### PATH C: Device in ABM, Not Supervised (Wipe & Re-enroll via ADE)

**Use when:** Device is in ABM but not currently supervised

```
┌─────────────────────────────────────────────────────────────────┐
│ PATH C: WIPE AND RE-ENROLL VIA ADE                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ WARNING: THIS ERASES ALL DATA ON DEVICE                         │
│                                                                  │
│ [ ] C.1 Backup user data (if applicable)                        │
│         User notified: YES                                      │
│         Data backed up to iCloud: YES / N/A                     │
│                                                                  │
│ [ ] C.2 Verify device is in ABM                                 │
│         ABM > Devices > Search [serial]                         │
│         Device found: YES ✓                                     │
│         MDM Server: Microsoft Intune ✓                          │
│                                                                  │
│ [ ] C.3 Verify enrollment profile in Intune                     │
│         Supervised: YES ✓                                       │
│         Profile assigned to device ✓                            │
│                                                                  │
│ [ ] C.4 Remove from Intune (if currently enrolled)              │
│         Intune > Devices > [Device] > Delete                    │
│         (This removes from inventory, doesn't wipe)             │
│                                                                  │
│ [ ] C.5 Factory reset device                                    │
│                                                                  │
│     Option A: From device (if accessible)                       │
│         Settings > General > Transfer or Reset iPad             │
│         > Erase All Content and Settings                        │
│         Enter passcode, confirm                                 │
│                                                                  │
│     Option B: From Intune (remote wipe)                         │
│         Intune > Devices > [Device] > Wipe                      │
│         Confirm wipe                                            │
│         Wait for device to receive command                      │
│                                                                  │
│     Option C: Recovery Mode (if locked out)                     │
│         Connect to Mac with Finder                              │
│         Enter recovery mode                                     │
│         Click Restore                                           │
│                                                                  │
│ [ ] C.6 Wait for wipe to complete                               │
│         Device shows "Hello" screen                             │
│                                                                  │
│ [ ] C.7 Complete Setup Assistant                                │
│         (Follow New Device steps 4.1 - 4.7)                     │
│                                                                  │
│ [ ] C.8 Verify supervised enrollment                            │
│         Settings > About shows "Supervised" ✓                   │
│         Apps installed ✓                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### PATH D: Device Not in ABM (Add via Apple Configurator)

**Use when:** Device is not in Apple Business Manager

```
┌─────────────────────────────────────────────────────────────────┐
│ PATH D: ADD TO ABM VIA APPLE CONFIGURATOR                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ WARNING: THIS ERASES ALL DATA ON DEVICE                         │
│ REQUIRES: Mac with Apple Configurator 2                         │
│                                                                  │
│ [ ] D.1 Backup user data (if applicable)                        │
│         User notified: YES                                      │
│         Data backed up: YES / N/A                               │
│                                                                  │
│ [ ] D.2 Prepare Mac                                             │
│         Apple Configurator 2 installed ✓                        │
│         USB cable ready ✓                                       │
│         Signed into ABM in Configurator ✓                       │
│                                                                  │
│ [ ] D.3 Check for Activation Lock                               │
│         If locked: Remove first (see 05-FIELD-REMEDIATION.md)   │
│         Activation Lock clear: YES ✓                            │
│                                                                  │
│ [ ] D.4 Connect iPad to Mac                                     │
│         USB cable connected ✓                                   │
│         Device appears in Configurator ✓                        │
│         Trust computer if prompted ✓                            │
│                                                                  │
│ [ ] D.5 Prepare device                                          │
│         Select device > Prepare                                 │
│         Configuration: Manual                                   │
│         Add to Apple Business Manager: YES ✓                    │
│         Supervise: YES ✓                                        │
│         MDM Server: Microsoft Intune                            │
│         Click Prepare                                           │
│                                                                  │
│ [ ] D.6 Wait for process (10-15 minutes)                        │
│         Device is wiped                                         │
│         Device is added to ABM                                  │
│         Device is assigned to Intune                            │
│                                                                  │
│ [ ] D.7 Verify in ABM                                           │
│         ABM > Devices > Search [serial]                         │
│         Device appears ✓                                        │
│         MDM: Microsoft Intune ✓                                 │
│                                                                  │
│ [ ] D.8 Sync Intune ADE token                                   │
│         Intune > iOS enrollment > Enrollment program tokens     │
│         Select token > Sync                                     │
│                                                                  │
│ [ ] D.9 Assign enrollment profile in Intune                     │
│         Select token > Devices > Find device                    │
│         Assign profile                                          │
│                                                                  │
│ [ ] D.10 Complete Setup Assistant on device                     │
│          Disconnect from Mac                                    │
│          Power on device                                        │
│          Follow Setup Assistant                                 │
│          "Remote Management" screen appears ✓                   │
│          Tap Continue to enroll                                 │
│                                                                  │
│ [ ] D.11 Verify enrollment                                      │
│          Supervised ✓                                           │
│          Apps installed ✓                                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## App Deployment Steps

### Deploy Company Portal

```
┌─────────────────────────────────────────────────────────────────┐
│ DEPLOY COMPANY PORTAL                                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] 1. Navigate to Apps                                         │
│        Intune > Apps > iOS/iPadOS > + Add                       │
│                                                                  │
│ [ ] 2. Select app type                                          │
│        iOS store app (VPP) > Select                             │
│                                                                  │
│ [ ] 3. Search for app                                           │
│        Search: "Intune Company Portal"                          │
│        Select Microsoft Corporation version                     │
│        Click Select                                             │
│                                                                  │
│ [ ] 4. Configure app information                                │
│        Name: Intune Company Portal                              │
│        Category: Business                                       │
│        Click Next                                               │
│                                                                  │
│ [ ] 5. Configure assignments                                    │
│        Required > + Add group                                   │
│        Select: [Your iPad device group]                         │
│        VPP license type: Device licensing                       │
│        Click Select                                             │
│                                                                  │
│ [ ] 6. Review + Create                                          │
│        Verify license type shows "Device"                       │
│        Click Create                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Deploy Google Chrome

```
┌─────────────────────────────────────────────────────────────────┐
│ DEPLOY GOOGLE CHROME                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ [ ] 1. Navigate to Apps                                         │
│        Intune > Apps > iOS/iPadOS > + Add                       │
│                                                                  │
│ [ ] 2. Select app type                                          │
│        iOS store app (VPP) > Select                             │
│                                                                  │
│ [ ] 3. Search for app                                           │
│        Search: "Google Chrome"                                  │
│        Select Google LLC version                                │
│        Click Select                                             │
│                                                                  │
│ [ ] 4. Configure app information                                │
│        Name: Google Chrome                                      │
│        Category: Productivity                                   │
│        Click Next                                               │
│                                                                  │
│ [ ] 5. Configure assignments                                    │
│        Required > + Add group                                   │
│        Select: [Your iPad device group]                         │
│        VPP license type: Device licensing                       │
│        Click Select                                             │
│                                                                  │
│ [ ] 6. Review + Create                                          │
│        Verify license type shows "Device"                       │
│        Click Create                                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Verification Steps

### Device Verification Checklist

```
┌─────────────────────────────────────────────────────────────────┐
│ DEVICE VERIFICATION CHECKLIST                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Device Serial: _______________                                  │
│ Date: _______________                                           │
│ Verified by: _______________                                    │
│                                                                  │
│ ON DEVICE                                                       │
│ ───────────────────────────────────────────────────────────────│
│ [ ] Settings > General > About                                  │
│     "This iPad is supervised and managed by [org]" ✓           │
│                                                                  │
│ [ ] Settings > General > VPN & Device Management                │
│     MDM profile from your organization ✓                       │
│     No other MDM profiles ✓                                    │
│                                                                  │
│ [ ] Home screen - App Store                                     │
│     App Store icon is NOT greyed out ✓                         │
│     (Note: App Store access may still be policy-controlled)    │
│                                                                  │
│ [ ] Home screen - Company Portal                                │
│     App is installed ✓                                         │
│     App opens successfully ✓                                   │
│     App shows correct organization ✓                           │
│                                                                  │
│ [ ] Home screen - Chrome                                        │
│     App is installed ✓                                         │
│     App opens successfully ✓                                   │
│     Can browse to websites ✓                                   │
│                                                                  │
│ IN INTUNE CONSOLE                                               │
│ ───────────────────────────────────────────────────────────────│
│ [ ] Devices > iOS/iPadOS > [Device]                             │
│     Device appears ✓                                           │
│     Supervised: Yes ✓                                          │
│     Compliance: Compliant ✓                                    │
│     Last check-in: Within last hour ✓                          │
│                                                                  │
│ [ ] Device > Managed apps                                       │
│     Company Portal: Installed ✓                                │
│     Chrome: Installed ✓                                        │
│                                                                  │
│ [ ] Device > Device configuration                               │
│     Expected profiles assigned ✓                               │
│     No profile errors ✓                                        │
│                                                                  │
│ VERIFICATION RESULT                                             │
│ ───────────────────────────────────────────────────────────────│
│ [ ] ALL CHECKS PASSED - Device ready for use                    │
│                                                                  │
│ [ ] SOME CHECKS FAILED - See troubleshooting                    │
│     Failed items: _______________                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting Decision Tree

```
┌─────────────────────────────────────────────────────────────────┐
│              TROUBLESHOOTING DECISION TREE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ISSUE: Apps not installing after enrollment                    │
│  ═══════════════════════════════════════════════════════════════│
│                                                                  │
│  ┌─────────────────────────────────────────────┐                │
│  │ Q1: Is device showing in Intune console?    │                │
│  └─────────────────────────────────────────────┘                │
│                │                    │                            │
│               YES                   NO                           │
│                │                    │                            │
│                ▼                    ▼                            │
│  ┌─────────────────────┐  ┌─────────────────────────┐           │
│  │ Q2: Is device       │  │ Device not enrolled.    │           │
│  │ supervised?         │  │ Check enrollment and    │           │
│  └─────────────────────┘  │ re-enroll if needed.   │           │
│       │           │       │ (See Existing Device)  │           │
│      YES          NO      └─────────────────────────┘           │
│       │           │                                              │
│       │           ▼                                              │
│       │   ┌─────────────────────────┐                           │
│       │   │ Device needs re-enroll  │                           │
│       │   │ with supervision.       │                           │
│       │   │ (See PATH C or D)       │                           │
│       │   └─────────────────────────┘                           │
│       ▼                                                          │
│  ┌─────────────────────────────────────────────┐                │
│  │ Q3: Are apps assigned with device licensing?│                │
│  └─────────────────────────────────────────────┘                │
│           │                    │                                 │
│          YES                   NO                                │
│           │                    │                                 │
│           │                    ▼                                 │
│           │          ┌─────────────────────────┐                │
│           │          │ Change to device        │                │
│           │          │ licensing in app        │                │
│           │          │ assignment, then sync.  │                │
│           │          └─────────────────────────┘                │
│           ▼                                                      │
│  ┌─────────────────────────────────────────────┐                │
│  │ Q4: Is VPP token active and synced?         │                │
│  └─────────────────────────────────────────────┘                │
│           │                    │                                 │
│          YES                   NO                                │
│           │                    │                                 │
│           │                    ▼                                 │
│           │          ┌─────────────────────────┐                │
│           │          │ Renew/sync VPP token.   │                │
│           │          │ Check token expiration. │                │
│           │          └─────────────────────────┘                │
│           ▼                                                      │
│  ┌─────────────────────────────────────────────┐                │
│  │ Q5: Is there a profile blocking App Store?  │                │
│  └─────────────────────────────────────────────┘                │
│           │                    │                                 │
│          YES                   NO                                │
│           │                    │                                 │
│           ▼                    ▼                                 │
│  ┌─────────────┐    ┌─────────────────────────┐                 │
│  │ Remove or   │    │ Q6: Is device in        │                 │
│  │ modify      │    │ correct device group?   │                 │
│  │ blocking    │    └─────────────────────────┘                 │
│  │ profile.    │          │           │                         │
│  └─────────────┘         YES          NO                        │
│                           │           │                          │
│                           │           ▼                          │
│                           │  ┌─────────────────┐                │
│                           │  │ Add device to   │                │
│                           │  │ assignment group│                │
│                           │  └─────────────────┘                │
│                           ▼                                      │
│                  ┌─────────────────────────────────┐            │
│                  │ Q7: Has device checked in       │            │
│                  │ recently? (within 1 hour)       │            │
│                  └─────────────────────────────────┘            │
│                          │                │                      │
│                         YES               NO                     │
│                          │                │                      │
│                          │                ▼                      │
│                          │    ┌─────────────────────┐           │
│                          │    │ Force sync device.  │           │
│                          │    │ Wait 15 minutes.    │           │
│                          │    │ Check again.        │           │
│                          │    └─────────────────────┘           │
│                          ▼                                       │
│                 ┌─────────────────────────────────┐             │
│                 │ Check app install status for    │             │
│                 │ specific error codes.           │             │
│                 │ (See 03-INTUNE-CONFIGURATION)   │             │
│                 │                                 │             │
│                 │ If no resolution:               │             │
│                 │ ESCALATE to Tier 2              │             │
│                 └─────────────────────────────────┘             │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  ISSUE: App Store greyed out                                    │
│  ═══════════════════════════════════════════════════════════════│
│                                                                  │
│  ┌─────────────────────────────────────────────┐                │
│  │ Q1: Is there a restriction profile?         │                │
│  │ (Settings > VPN & Device Management)        │                │
│  └─────────────────────────────────────────────┘                │
│                │                    │                            │
│               YES                   NO                           │
│                │                    │                            │
│                ▼                    ▼                            │
│  ┌─────────────────────┐  ┌─────────────────────────┐           │
│  │ Check if profile    │  │ Q2: Is Screen Time      │           │
│  │ has App Store       │  │ enabled with            │           │
│  │ restriction.        │  │ restrictions?           │           │
│  │                     │  └─────────────────────────┘           │
│  │ If yes: Modify      │       │           │                    │
│  │ profile in Intune.  │      YES          NO                   │
│  └─────────────────────┘       │           │                    │
│                                ▼           ▼                    │
│                  ┌─────────────────┐  ┌─────────────┐           │
│                  │ Disable Screen  │  │ Escalate    │           │
│                  │ Time via Intune │  │ to Tier 2   │           │
│                  │ profile.        │  │ for review. │           │
│                  └─────────────────┘  └─────────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Support Escalation

| Level | Contact | When to Escalate |
|-------|---------|------------------|
| Tier 1 | Help Desk | First contact, basic troubleshooting |
| Tier 2 | Intune Admin | Token issues, profile problems, ABM issues |
| Tier 3 | it@sbsfederal.com | Complex issues, policy decisions |
| Apple Support | apple.com/support | Activation Lock, hardware issues |
| Microsoft Support | Portal | Intune service issues |

---

## Document References

| Document | Purpose |
|----------|---------|
| [01-DIAGNOSIS-GUIDE.md](01-DIAGNOSIS-GUIDE.md) | Diagnose greyed out apps |
| [02-ABM-ADE-DEPLOYMENT.md](02-ABM-ADE-DEPLOYMENT.md) | ABM/ADE gold standard setup |
| [03-INTUNE-CONFIGURATION.md](03-INTUNE-CONFIGURATION.md) | Intune click-path steps |
| [04-APPLE-CONFIGURATOR-FALLBACK.md](04-APPLE-CONFIGURATOR-FALLBACK.md) | When ABM not available |
| [05-FIELD-REMEDIATION.md](05-FIELD-REMEDIATION.md) | Fix devices in the field |

---

*SBS Federal IT Department*
