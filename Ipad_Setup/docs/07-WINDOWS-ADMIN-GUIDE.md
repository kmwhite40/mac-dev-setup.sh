# iPad Intune Deployment - Windows Admin Guide

## Step-by-Step Guide for Windows Administrators

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Overview

This guide provides Windows-based administrators with step-by-step instructions to configure Microsoft Intune for iPad deployment, including VPP app setup for Company Portal and Google Chrome.

**Note:** Unlike macOS deployments, iOS/iPadOS VPP apps are configured directly in Intune without needing to create packages. The apps are pulled from Apple's App Store via your VPP token.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Configure Apple Business Manager](#step-1-configure-apple-business-manager)
3. [Step 2: Set Up Intune Tokens](#step-2-set-up-intune-tokens)
4. [Step 3: Create Enrollment Profile](#step-3-create-enrollment-profile)
5. [Step 4: Add VPP Apps](#step-4-add-vpp-apps)
6. [Step 5: Create Device Groups](#step-5-create-device-groups)
7. [Step 6: Configure Profiles](#step-6-configure-profiles)
8. [Step 7: Verify Configuration](#step-7-verify-configuration)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Access

| Requirement | URL | Role Needed |
|-------------|-----|-------------|
| Microsoft Intune | https://intune.microsoft.com | Intune Administrator |
| Apple Business Manager | https://business.apple.com | Administrator or Device Manager |
| Azure AD | https://portal.azure.com | User Administrator (for groups) |

### Browser Requirements

- Microsoft Edge (recommended)
- Google Chrome
- Firefox

**Note:** Safari on Windows is not supported.

### Required Information

Before starting, gather:
- [ ] Apple Business Manager admin credentials
- [ ] Intune admin credentials
- [ ] List of iPad serial numbers (for ADE assignment)
- [ ] Corporate Wi-Fi SSID and password (for enrollment)

---

## Step 1: Configure Apple Business Manager

### 1.1 Sign In to ABM

1. Open browser and navigate to: **https://business.apple.com**
2. Sign in with your ABM administrator Apple ID
3. Complete two-factor authentication if prompted

### 1.2 Verify MDM Server Exists

**Navigation:** Settings (gear icon) > Device Management Settings

1. Look for existing MDM server named "Microsoft Intune" or similar
2. If exists, note the server name and skip to Step 1.4
3. If not exists, continue to Step 1.3

### 1.3 Create MDM Server (If Needed)

**Navigation:** Settings > Device Management Settings > Add MDM Server

1. Click **Add MDM Server**

2. Enter MDM Server details:
   | Field | Value |
   |-------|-------|
   | MDM Server Name | `Microsoft Intune` |

3. **You'll need to upload a public key from Intune:**
   - Keep this browser tab open
   - Open a new tab for Intune (Step 2)
   - Return here after downloading the public key

### 1.4 Purchase VPP App Licenses

**Navigation:** Apps and Books (sidebar)

**For Company Portal:**
1. Click search box, type: `Intune Company Portal`
2. Select **Intune Company Portal** by Microsoft Corporation
3. Click **Get**
4. Select your **Location** (VPP location)
5. Enter **Quantity**: At least the number of iPads + 20% buffer
6. Click **Get**
7. Confirm the purchase

**For Google Chrome:**
1. Click search box, type: `Google Chrome`
2. Select **Chrome** by Google LLC
3. Click **Get**
4. Select your **Location**
5. Enter **Quantity**: Same as Company Portal
6. Click **Get**
7. Confirm the purchase

### 1.5 Download VPP Token

**Navigation:** Settings > Apps and Books

1. Find your location in the list
2. Click **Download** next to "Content Token" (or "Server Token")
3. Save the `.vpptoken` file to a known location (e.g., `C:\Intune\Tokens\`)
4. **Important:** This token expires annually - note the date

---

## Step 2: Set Up Intune Tokens

### 2.1 Sign In to Intune

1. Open browser and navigate to: **https://intune.microsoft.com**
2. Sign in with your Intune administrator credentials
3. Complete MFA if prompted

### 2.2 Configure APNs Certificate (If Not Done)

**Navigation:** Tenant administration > Connectors and tokens > Apple MDM Push certificate

**Check if already configured:**
- If status shows "Active" with a future expiration date, skip to Step 2.3
- If not configured or expired, continue below

**To configure:**

1. Check the box: "I grant Microsoft permission to send..."
2. Click **Download your CSR**
3. Save the `.csr` file to `C:\Intune\Tokens\`

4. Click **Create your MDM push certificate** (opens Apple Push Certificates Portal)
5. Sign in with an Apple ID (use a service account, not personal)
6. Click **Create a Certificate**
7. Upload the CSR file you downloaded
8. Click **Download** to get the `.pem` certificate
9. Save to `C:\Intune\Tokens\`

10. Return to Intune:
    - **Apple ID:** Enter the Apple ID used above
    - Click **Browse** and select the `.pem` file
    - Click **Upload**

11. Verify status shows **Active**

### 2.3 Configure ADE/DEP Token

**Navigation:** Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens

1. Click **+ Add**

2. Check the agreement box

3. Click **Download public key**
   - Save to `C:\Intune\Tokens\`
   - This is the file needed for ABM MDM server setup

4. **Now go to Apple Business Manager** (if MDM server not yet created):
   - Upload this public key when creating/editing MDM server
   - Download the server token (`.p7m` file) from ABM
   - Save to `C:\Intune\Tokens\`

5. Return to Intune and continue:
   - **Apple ID:** Enter your ABM admin Apple ID
   - **Apple enrollment program token:** Click Browse, select the `.p7m` file
   - Click **Next**

6. **Scope tags:** (Optional) Select if using RBAC, otherwise click **Next**

7. Click **Create**

8. Wait for token to sync (may take a few minutes)

9. Verify status shows **Active**

### 2.4 Configure VPP Token

**Navigation:** Tenant administration > Connectors and tokens > Apple VPP tokens

1. Click **+ Add**

2. Configure token:
   | Field | Value |
   |-------|-------|
   | VPP token name | `ABM VPP Production` |
   | Apple ID | Your ABM admin Apple ID |
   | VPP token file | Browse and select the `.vpptoken` file |
   | Country/Region | Select your country |
   | Automatic app updates | Yes |
   | Grant VPP license to device | Yes (Important!) |

3. Click **Create**

4. Wait for sync to complete

5. Click **Sync** to pull apps from ABM

6. Verify status shows **Active**

---

## Step 3: Create Enrollment Profile

### 3.1 Navigate to Enrollment Profiles

**Navigation:** Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens

1. Click on your ADE token name
2. Click **Profiles** tab
3. Click **+ Create profile** > **iOS/iPadOS**

### 3.2 Configure Profile Basics

| Field | Value |
|-------|-------|
| Name | `iPad Supervised - Standard` |
| Description | `Supervised enrollment for corporate iPads` |

Click **Next**

### 3.3 Configure Management Settings

| Setting | Value | Notes |
|---------|-------|-------|
| User Affinity | Enroll without User Affinity | For shared devices |
| | OR Enroll with User Affinity | For assigned devices |
| Supervised | **Yes** | CRITICAL - enables full management |
| Locked enrollment | **Yes** | Prevents user from removing MDM |
| Sync with computers | Deny All | Security best practice |
| Await final configuration | **Yes** | Ensures profiles apply first |

**If User Affinity = Yes, also configure:**
| Setting | Value |
|---------|-------|
| Authentication method | Setup Assistant with modern authentication |
| Install Company Portal with VPP | Select your VPP token |

Click **Next**

### 3.4 Configure Setup Assistant

**Screens to SHOW:**
- [x] Language
- [x] Region
- [x] Wi-Fi

**Screens to HIDE (uncheck):**
- [ ] Passcode
- [ ] Location Services
- [ ] Restore
- [ ] Apple ID
- [ ] Terms and Conditions (optional - show if required)
- [ ] Touch ID / Face ID
- [ ] Apple Pay
- [ ] Siri
- [ ] Diagnostics
- [ ] Display Tone
- [ ] Privacy
- [ ] Screen Time
- [ ] Software Update
- [ ] iMessage & FaceTime
- [ ] Get Started

Click **Next**

### 3.5 Review and Create

1. Review all settings
2. Verify **Supervised: Yes**
3. Click **Create**

### 3.6 Assign Profile to Devices

1. In your ADE token, click **Devices** tab
2. Select devices by checking boxes (or use filters)
3. Click **Assign profile**
4. Select your new profile
5. Click **Assign**

---

## Step 4: Add VPP Apps

### 4.1 Add Company Portal

**Navigation:** Apps > iOS/iPadOS > + Add

1. **Select app type:** iOS store app (VPP)
2. Click **Select**

3. **Search for app:**
   - Type: `Intune Company Portal`
   - Click **Search the App Store**
   - Select **Intune Company Portal** by Microsoft Corporation
   - Click **Select**

4. **App information:**
   | Field | Value |
   |-------|-------|
   | Name | Intune Company Portal |
   | Description | Microsoft Intune Company Portal |
   | Publisher | Microsoft Corporation |
   | Category | Business |

   Click **Next**

5. **Scope tags:** Configure if needed, click **Next**

6. **Assignments - CRITICAL STEP:**

   Under **Required**, click **+ Add group**

   | Setting | Value |
   |---------|-------|
   | Select groups | Choose your iPad device group |
   | **VPP license type** | **Device licensing** ← CRITICAL! |

   Click **Select**

   Click **Next**

7. **Review + create:**
   - Verify "Device licensing" is shown
   - Click **Create**

### 4.2 Add Google Chrome

**Navigation:** Apps > iOS/iPadOS > + Add

1. **Select app type:** iOS store app (VPP)
2. Click **Select**

3. **Search for app:**
   - Type: `Google Chrome`
   - Select **Chrome** by Google LLC
   - Click **Select**

4. **App information:**
   | Field | Value |
   |-------|-------|
   | Name | Google Chrome |
   | Description | Google Chrome web browser |
   | Publisher | Google LLC |
   | Category | Productivity |

   Click **Next**

5. **Scope tags:** Configure if needed, click **Next**

6. **Assignments:**

   Under **Required**, click **+ Add group**

   | Setting | Value |
   |---------|-------|
   | Select groups | Choose your iPad device group |
   | **VPP license type** | **Device licensing** |

   Click **Select**

   Click **Next**

7. **Review + create:**
   - Verify "Device licensing" is shown
   - Click **Create**

---

## Step 5: Create Device Groups

### 5.1 Navigate to Groups

**Navigation:** Groups (left sidebar) > + New group

OR

**Azure Portal:** https://portal.azure.com > Azure Active Directory > Groups > + New group

### 5.2 Create iPad Device Group

| Field | Value |
|-------|-------|
| Group type | Security |
| Group name | `iPads - Corporate Devices` |
| Group description | `All corporate managed iPads` |
| Membership type | Dynamic Device |

### 5.3 Configure Dynamic Membership Rule

Click **Add dynamic query**

**Simple rule:**
```
Property: deviceOSType
Operator: Equals
Value: iPad
```

**Advanced rule syntax (click "Edit" to switch to text mode):**
```
(device.deviceOSType -eq "iPad") and (device.managementType -eq "MDM")
```

Click **Save**

### 5.4 Create the Group

1. Click **Create**
2. Wait for group to be created
3. Check **Members** after a few minutes to verify iPads appear

---

## Step 6: Configure Profiles

### 6.1 Create Profile to Allow App Installation

**Navigation:** Devices > Configuration profiles > + Create profile

| Field | Value |
|-------|-------|
| Platform | iOS/iPadOS |
| Profile type | Templates |
| Template name | Device restrictions |

Click **Create**

**Basics:**
| Field | Value |
|-------|-------|
| Name | `iPad - Allow App Installation` |
| Description | `Ensures VPP apps can install` |

Click **Next**

**Configuration settings:**

Navigate to **App Store, Doc Viewing, Gaming**:

| Setting | Value |
|---------|-------|
| Block App Store | **No** or **Not configured** |
| Block using iTunes Store | Not configured |
| Block automatically downloading apps | Not configured |

Click **Next**

**Scope tags:** Configure if needed, click **Next**

**Assignments:**
- Click **+ Add groups**
- Select your iPad device group
- Click **Select**

Click **Next**

**Review + create:** Click **Create**

### 6.2 Create Profile to Block Screen Time (Recommended)

**Navigation:** Devices > Configuration profiles > + Create profile

| Field | Value |
|-------|-------|
| Platform | iOS/iPadOS |
| Profile type | Templates |
| Template name | Device restrictions |

Click **Create**

**Basics:**
| Field | Value |
|-------|-------|
| Name | `iPad - Block Screen Time` |
| Description | `Prevents Screen Time from blocking apps` |

Click **Next**

**Configuration settings:**

Navigate to **Built-in Apps**:

| Setting | Value |
|---------|-------|
| Block Screen Time | **Yes** |

Click **Next** through remaining steps

**Assignments:** Add your iPad device group

Click **Create**

---

## Step 7: Verify Configuration

### 7.1 Verify Tokens

**Check APNs:**
```
Tenant administration > Connectors and tokens > Apple MDM Push certificate
```
- Status: Active ✓
- Expiration: Future date ✓

**Check ADE Token:**
```
Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens
```
- Status: Active ✓
- Last sync: Recent ✓

**Check VPP Token:**
```
Tenant administration > Connectors and tokens > Apple VPP tokens
```
- Status: Active ✓
- Last sync: Recent ✓

### 7.2 Verify Apps

**Navigation:** Apps > iOS/iPadOS

1. Find "Intune Company Portal"
   - Click on it
   - Go to **Properties** > **Assignments**
   - Verify: Device licensing ✓
   - Verify: Assigned to iPad group ✓

2. Find "Google Chrome"
   - Same verification steps

### 7.3 Verify Enrollment Profile

**Navigation:** Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens > [Your Token] > Profiles

- Profile exists ✓
- Supervised: Yes ✓
- Assigned to devices ✓

### 7.4 Test with a Device

1. Factory reset a test iPad (or use new iPad)
2. Go through Setup Assistant
3. Verify "Remote Management" screen appears
4. Complete enrollment
5. Verify:
   - Settings > About shows "Supervised" ✓
   - Company Portal installs automatically ✓
   - Chrome installs automatically ✓

---

## Troubleshooting

### Issue: VPP Apps Not Appearing in Intune

**Solution:**
1. Go to Tenant administration > Connectors > Apple VPP tokens
2. Select your token
3. Click **Sync**
4. Wait 5-10 minutes
5. Check Apps > iOS/iPadOS again

### Issue: Apps Show "License Unavailable"

**Solutions:**
1. Purchase more licenses in ABM
2. Change from User licensing to Device licensing
3. Sync VPP token

### Issue: Device Not Getting Apps

**Checklist:**
- [ ] Device is in the correct device group
- [ ] App assigned to that group as "Required"
- [ ] License type is "Device" not "User"
- [ ] VPP token is active and synced
- [ ] Device has checked in recently

**Force sync:**
1. Go to Devices > iOS/iPadOS > [Device]
2. Click **Sync**

### Issue: "Block App Store" Preventing Installation

**Solution:**
1. Go to Devices > Configuration profiles
2. Find any profile with "Device restrictions"
3. Check for "Block App Store = Yes"
4. Change to "No" or "Not configured"
5. Save and sync

### Issue: Token Expired

**APNs Certificate:**
- Must renew with SAME Apple ID
- Download new CSR from Intune
- Create new certificate at Apple
- Upload to Intune

**ADE/VPP Token:**
- Download new token from ABM
- Upload to Intune
- Sync

---

## Quick Reference: Navigation Paths

| Task | Navigation Path |
|------|-----------------|
| APNs Certificate | Tenant admin > Connectors > Apple MDM Push |
| ADE Token | Devices > iOS enrollment > Enrollment program tokens |
| VPP Token | Tenant admin > Connectors > Apple VPP tokens |
| Add iOS App | Apps > iOS/iPadOS > + Add |
| Create Group | Groups > + New group |
| Create Profile | Devices > Configuration profiles > + Create |
| Check Device | Devices > iOS/iPadOS > [Device name] |
| Sync Device | Devices > iOS/iPadOS > [Device] > Sync |
| Check App Status | Apps > iOS/iPadOS > [App] > Device install status |

---

## Summary Checklist

```
WINDOWS ADMIN SETUP CHECKLIST
=============================

APPLE BUSINESS MANAGER
[ ] MDM server configured for Intune
[ ] Company Portal licenses purchased
[ ] Chrome licenses purchased
[ ] VPP token downloaded

INTUNE TOKENS
[ ] APNs certificate: Active
[ ] ADE token: Active and synced
[ ] VPP token: Active and synced

ENROLLMENT PROFILE
[ ] Profile created with Supervised = Yes
[ ] Profile assigned to devices

VPP APPS
[ ] Company Portal added with Device licensing
[ ] Chrome added with Device licensing
[ ] Both assigned to iPad device group as Required

DEVICE GROUP
[ ] Dynamic device group created for iPads

CONFIGURATION PROFILES
[ ] App Store NOT blocked
[ ] Screen Time blocked (optional)

TESTING
[ ] Test device enrolls successfully
[ ] Test device shows Supervised
[ ] Apps install automatically

Completed by: _______________ Date: _______________
```

---

*SBS Federal IT Department*
