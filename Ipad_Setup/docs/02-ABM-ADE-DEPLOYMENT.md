# iPad Intune Deployment - ABM/ADE Gold Standard Guide

## Apple Business Manager + Automated Device Enrollment + Supervised Mode

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [ABM Configuration](#abm-configuration)
4. [Intune Token Setup](#intune-token-setup)
5. [Enrollment Profile Configuration](#enrollment-profile-configuration)
6. [VPP App Deployment](#vpp-app-deployment)
7. [Shared/Userless Device Configuration](#shareduserless-device-configuration)
8. [Verification Steps](#verification-steps)

---

## Overview

This is the **recommended "gold standard"** deployment path for iPads in enterprise environments. It provides:

- **Supervised mode** - Full device management capabilities
- **Zero-touch enrollment** - Devices auto-enroll on first boot
- **No Apple ID required** - Device-licensed VPP apps
- **Locked enrollment** - Users cannot remove MDM
- **Silent app installation** - Apps install without user interaction

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT FLOW                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  Apple   │───▶│   ABM    │───▶│  Intune  │───▶│   iPad   │  │
│  │ Reseller │    │  Portal  │    │  Admin   │    │  Device  │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       │               │               │               │         │
│       │               │               │               │         │
│  Purchase &      Device          Enrollment       Auto-enroll   │
│  Ship Device     Assignment      Profile &        on first      │
│                  to MDM          App Config       power-on      │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  VPP LICENSE FLOW:                                              │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │ABM Apps &│───▶│  Intune  │───▶│  Device  │───▶│   App    │  │
│  │  Books   │    │VPP Token │    │  Group   │    │Installed │  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│                                                                  │
│  Purchase        Sync            Assign as        Silent        │
│  Licenses        Token           "Required"       Install       │
│                                  Device License                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required Accounts & Access

| Requirement | Details | How to Verify |
|-------------|---------|---------------|
| Apple Business Manager | Organization account | https://business.apple.com |
| Microsoft Intune | Admin access | https://intune.microsoft.com |
| ABM Admin Role | Administrator or Device Manager | ABM > Settings > Accounts |
| Intune Admin Role | Intune Administrator or Global Admin | Azure AD roles |
| D-U-N-S Number | For ABM enrollment (if new) | ABM registration |

### Required Tokens/Certificates

| Token | Purpose | Validity | Location in Intune |
|-------|---------|----------|-------------------|
| **APNs Certificate** | Push notifications to devices | 1 year | Tenant admin > Connectors > Apple MDM Push |
| **ADE/DEP Token** | Automated enrollment | 1 year | Devices > iOS enrollment > Enrollment program tokens |
| **VPP Token** | App licensing | 1 year | Tenant admin > Connectors > Apple VPP tokens |

### ABM Prerequisites Checklist

```
[ ] ABM account created and verified
[ ] D-U-N-S number verified (for new accounts)
[ ] At least one admin user in ABM
[ ] MDM server created in ABM (for Intune)
[ ] Devices purchased through Apple/authorized reseller
    OR
[ ] Devices added via Apple Configurator
[ ] VPP/Apps and Books location created
[ ] Required apps purchased (Company Portal, Chrome)
```

---

## ABM Configuration

### Step 1: Verify ABM Account

1. **Sign in to Apple Business Manager:**
   ```
   https://business.apple.com
   ```

2. **Verify Organization:**
   - Click your name (top right) > Preferences
   - Confirm organization name and D-U-N-S

3. **Check Admin Access:**
   ```
   Settings > Accounts
   ```
   - Ensure you have Administrator role

### Step 2: Create MDM Server for Intune

**ABM Portal > Settings > Device Management Settings**

1. Click **Add MDM Server**

2. **MDM Server Name:** `Microsoft Intune - Production`

3. **Upload Public Key:**
   - You'll need this from Intune (see next section)
   - Download from: Intune > Devices > iOS/iPadOS enrollment > Enrollment program tokens > Add

4. **Save** the MDM server

5. **Download Server Token:**
   - Click on your MDM server
   - Click **Download Token**
   - Save the `.p7m` file securely

### Step 3: Assign Devices to MDM Server

**ABM Portal > Devices**

1. **Find Devices:**
   - Search by serial number, order number, or filter

2. **Select Devices:**
   - Check boxes for devices to assign

3. **Edit MDM Server:**
   - Click **Edit MDM Server**
   - Select your Intune MDM server
   - Click **Continue** > **Assign**

4. **Verify Assignment:**
   - Device should show Intune server in MDM column

### Step 4: Purchase VPP Apps

**ABM Portal > Apps and Books**

1. **Search for Company Portal:**
   - Search: "Intune Company Portal"
   - Publisher: Microsoft Corporation

2. **Purchase Licenses:**
   - Click on the app
   - Select **Location** (your VPP location)
   - Enter quantity (recommend: device count + 20% buffer)
   - Click **Get**

3. **Repeat for Google Chrome:**
   - Search: "Google Chrome"
   - Publisher: Google LLC
   - Purchase licenses

4. **Verify Purchases:**
   ```
   Apps and Books > [Select app] > Manage Licenses
   ```
   - Confirm licenses available

---

## Intune Token Setup

### Step 1: APNs Certificate (If Not Already Done)

**Intune Admin Center > Tenant administration > Connectors and tokens > Apple MDM Push certificate**

1. **Grant Permission:**
   - Check "I grant Microsoft permission..."
   - Click **Download your CSR**
   - Save the CSR file

2. **Create Certificate at Apple:**
   - Click **Create your MDM push certificate**
   - Sign in with your Apple ID (use a service account)
   - Upload the CSR file
   - Download the `.pem` certificate

3. **Upload to Intune:**
   - **Apple ID:** Enter the Apple ID used
   - **Apple MDM push certificate:** Upload the `.pem` file
   - Click **Upload**

4. **Note Expiration:**
   - Certificate expires in 1 year
   - Set calendar reminder for renewal

### Step 2: ADE/DEP Token

**Intune Admin Center > Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens**

1. **Click Add:**

2. **Configure Token:**
   - **I agree:** Check the box
   - **Download public key:** Click and save

3. **Upload Public Key to ABM:**
   - Go to ABM > Settings > Device Management Settings
   - Create/edit MDM server
   - Upload the public key from Intune
   - Download the server token (`.p7m`)

4. **Return to Intune:**
   - **Apple ID:** Enter Apple ID used for ABM
   - **Apple token:** Upload the `.p7m` file
   - Click **Next**

5. **Scope Tags:** (Optional)
   - Assign scope tags if using RBAC

6. **Review + Create:**
   - Review settings
   - Click **Create**

7. **Sync Devices:**
   - Select your token
   - Click **Sync**
   - Wait for sync to complete

### Step 3: VPP Token

**Intune Admin Center > Tenant administration > Connectors and tokens > Apple VPP tokens**

1. **Click Add:**

2. **Download Location Token from ABM:**
   - Go to ABM > Settings > Apps and Books
   - Select your location
   - Click **Download** next to "Server Token"
   - Save the `.vpptoken` file

3. **Configure in Intune:**
   - **VPP token name:** `ABM VPP - Production`
   - **Apple ID:** Enter Apple ID for ABM
   - **VPP token file:** Upload `.vpptoken`
   - **Country/Region:** Select your country
   - **Automatic app updates:** Yes
   - **Grant VPP license to device:** Eligible (important!)

4. **Click Create**

5. **Sync Token:**
   - Select the token
   - Click **Sync**

6. **Verify Apps:**
   - After sync, go to Apps > iOS/iPadOS
   - Search for Company Portal and Chrome
   - They should appear as VPP apps

---

## Enrollment Profile Configuration

### Step 1: Create Enrollment Profile

**Intune Admin Center > Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens > [Your Token] > Profiles**

1. **Click Create profile > iOS/iPadOS**

2. **Basics:**
   - **Name:** `iPad Supervised - Standard`
   - **Description:** `Supervised enrollment for corporate iPads with locked MDM`

3. **Management Settings:**

   | Setting | Value | Reason |
   |---------|-------|--------|
   | **User Affinity** | Enroll without User Affinity | For shared/kiosk devices |
   | **OR** | Enroll with User Affinity | For assigned user devices |
   | **Supervised** | Yes | Required for full management |
   | **Locked enrollment** | Yes | Users cannot remove MDM |
   | **Sync with computers** | Deny All | Security |
   | **Await final configuration** | Yes | Ensures profiles apply before use |

   **If User Affinity = Yes:**
   | Setting | Value |
   |---------|-------|
   | **Authentication method** | Setup Assistant with modern authentication |
   | **Company Portal VPP** | Select Company Portal from token |

4. **Setup Assistant:**

   **Show these screens:**
   | Screen | Show/Hide | Reason |
   |--------|-----------|--------|
   | Language | Show | User needs to select |
   | Region | Show | User needs to select |
   | Wi-Fi | Show | Required for enrollment |
   | Terms and Conditions | Show | Legal compliance |

   **Hide these screens:**
   | Screen | Show/Hide | Reason |
   |--------|-----------|--------|
   | Passcode | Hide | Configure via policy |
   | Location Services | Hide | Configure via policy |
   | Restore | Hide | No restore for corporate |
   | Apple ID | Hide | Not required for VPP |
   | iCloud Analytics | Hide | Skip data collection |
   | iMessage & FaceTime | Hide | Not needed |
   | Screen Time | Hide | Configure via policy |
   | Privacy | Hide | Handled by policy |
   | Siri | Hide | Configure via policy |
   | Diagnostics | Hide | Skip |
   | Display Tone | Hide | Minor preference |
   | Home Button | Hide | Minor preference |
   | Get Started | Hide | Skip welcome |
   | Software Update | Hide | Control via policy |

5. **Review + Create:**
   - Review all settings
   - Click **Create**

### Step 2: Assign Profile to Devices

**Intune Admin Center > Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens > [Your Token] > Devices**

1. **Select Devices:**
   - Check boxes for devices to assign

2. **Assign Profile:**
   - Click **Assign profile**
   - Select your enrollment profile
   - Click **Assign**

3. **Verify Assignment:**
   - Device should show profile name in Profile column

---

## VPP App Deployment

### Step 1: Add Company Portal as VPP App

**Intune Admin Center > Apps > iOS/iPadOS > Add**

1. **Select app type:** iOS store app (VPP)

2. **Search and Select:**
   - Search: "Intune Company Portal"
   - Select from results
   - Click **Select**

3. **App Information:**
   - **Name:** Intune Company Portal
   - **Description:** Company Portal for device management
   - **Publisher:** Microsoft Corporation
   - **Category:** Business

4. **Assignments:**

   **Required:**
   - Click **Add group**
   - Select: "All Devices" or your iPad device group
   - **License type:** Device licensing (CRITICAL!)
   - Click **Select**

5. **Review + Create:**
   - Click **Create**

### Step 2: Add Google Chrome as VPP App

**Intune Admin Center > Apps > iOS/iPadOS > Add**

1. **Select app type:** iOS store app (VPP)

2. **Search and Select:**
   - Search: "Google Chrome"
   - Publisher: Google LLC
   - Click **Select**

3. **App Information:**
   - **Name:** Google Chrome
   - **Description:** Web browser
   - **Publisher:** Google LLC
   - **Category:** Productivity

4. **Assignments:**

   **Required:**
   - Click **Add group**
   - Select: "All Devices" or your iPad device group
   - **License type:** Device licensing (CRITICAL!)
   - Click **Select**

5. **Review + Create:**
   - Click **Create**

### Critical: Device vs User Licensing

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPP LICENSING TYPES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  DEVICE LICENSING (Recommended for this scenario)               │
│  ─────────────────────────────────────────────────────────────  │
│  • License assigned to DEVICE, not user                         │
│  • NO Apple ID required on device                               │
│  • App installs silently without user interaction               │
│  • Works for shared/userless devices                            │
│  • App remains even if user signs out                           │
│                                                                  │
│  USER LICENSING (Not recommended)                                │
│  ─────────────────────────────────────────────────────────────  │
│  • License assigned to USER's Apple ID                          │
│  • Requires Apple ID signed in on device                        │
│  • User must accept in App Store                                │
│  • License follows user to other devices                        │
│  • WILL FAIL if no Apple ID or App Store restricted             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**To verify device licensing is set:**
```
Apps > iOS/iPadOS > [App name] > Properties > Assignments
```
- Check "License type" column shows "Device"

---

## Shared/Userless Device Configuration

For shared iPads or kiosk devices without assigned users:

### Option A: Shared iPad (Multiple Users)

**Prerequisites:**
- Supervised device
- iPadOS 13.4+
- Managed Apple IDs (federated with Azure AD)
- Minimum 32GB storage

**Enrollment Profile Settings:**
```
User Affinity: Enroll without User Affinity
Shared iPad: Yes (if using Shared iPad feature)
Maximum cached users: [Set based on storage]
```

**Intune Configuration Profile:**
```
Configuration profiles > Create > iOS/iPadOS > Settings catalog
Search: "Shared iPad"

Settings:
- Shared Device Configuration
  - Maximum Resident Users: 5-10 (based on storage)
  - Only Show Managed Users: Yes
```

### Option B: Dedicated Device (Kiosk/Single App)

**Enrollment Profile Settings:**
```
User Affinity: Enroll without User Affinity
Shared iPad: No
```

**Intune Kiosk Profile:**
```
Configuration profiles > Create > iOS/iPadOS > Templates > Device restrictions

Kiosk > Managed App (for single app mode)
OR
Kiosk > App (for multiple apps)
```

### App Assignment for Userless Devices

**Critical:** Use a device group, NOT a user group:

1. **Create Device Group:**
   ```
   Azure AD > Groups > New group
   - Type: Security
   - Name: "iPads - Shared Devices"
   - Membership: Dynamic device
   - Rule: (device.deviceOSType -eq "iPad") and (device.managementType -eq "MDM")
   ```

2. **Assign Apps to Device Group:**
   ```
   Apps > iOS/iPadOS > [App] > Assignments
   - Required > Add group > "iPads - Shared Devices"
   - License type: Device
   ```

---

## Verification Steps

### Pre-Deployment Verification

```
VERIFICATION CHECKLIST - PRE-DEPLOYMENT
========================================
Date: _______________
Admin: _______________

ABM VERIFICATION
[ ] ABM account active
[ ] MDM server created for Intune
[ ] Public key uploaded to ABM
[ ] Server token downloaded from ABM
[ ] Device(s) assigned to Intune MDM server

INTUNE TOKEN VERIFICATION
[ ] APNs certificate: Active, not expired
[ ] ADE token: Active, sync successful
[ ] VPP token: Active, sync successful

APP VERIFICATION
[ ] Company Portal: Purchased in ABM
[ ] Company Portal: Visible in Intune Apps
[ ] Company Portal: Device licensing enabled
[ ] Chrome: Purchased in ABM
[ ] Chrome: Visible in Intune Apps
[ ] Chrome: Device licensing enabled

ENROLLMENT PROFILE VERIFICATION
[ ] Profile created with correct settings
[ ] Supervised: Yes
[ ] Locked enrollment: Yes
[ ] Profile assigned to devices

DEVICE VERIFICATION (in ABM)
[ ] Device serial visible in ABM
[ ] Device assigned to Intune MDM server
[ ] Device assigned enrollment profile
```

### Post-Enrollment Verification

**On Device:**
```
1. Settings > General > About
   [ ] Shows "This iPad is supervised and managed by [org]"

2. Settings > General > VPN & Device Management
   [ ] Shows MDM profile from your organization
   [ ] Shows enrollment type

3. Home Screen
   [ ] Company Portal app is installed
   [ ] Chrome app is installed
   [ ] Apps are functional (not greyed out)
```

**In Intune:**
```
Devices > iOS/iPadOS > [Device]

[ ] Compliance state: Compliant
[ ] Supervised: Yes
[ ] Enrollment type: Device enrollment
[ ] Last check-in: Recent (within minutes)

Device > Managed apps
[ ] Company Portal: Installed
[ ] Chrome: Installed
```

---

## Token Renewal Calendar

Set reminders for these annual renewals:

| Token | Where to Renew | Lead Time |
|-------|---------------|-----------|
| APNs Certificate | Apple Push Certificates Portal + Intune | 30 days before expiry |
| ADE Token | ABM + Intune | 30 days before expiry |
| VPP Token | ABM + Intune | 30 days before expiry |

**Warning:** If APNs certificate expires, ALL iOS devices lose management capability and require re-enrollment.

---

## Next Steps

- For devices not eligible for ABM/ADE, see [04-APPLE-CONFIGURATOR-FALLBACK.md](04-APPLE-CONFIGURATOR-FALLBACK.md)
- For Intune configuration details, see [03-INTUNE-CONFIGURATION.md](03-INTUNE-CONFIGURATION.md)
- For field remediation, see [05-FIELD-REMEDIATION.md](05-FIELD-REMEDIATION.md)

---

*SBS Federal IT Department*
