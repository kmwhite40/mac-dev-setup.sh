# iPad Intune Deployment - Intune Configuration Steps

## Click-Path Configuration Guide

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [VPP App Configuration](#vpp-app-configuration)
2. [Device Group Setup](#device-group-setup)
3. [Configuration Profiles](#configuration-profiles)
4. [Compliance Policies](#compliance-policies)
5. [Common Settings That Break Deployment](#common-settings-that-break-deployment)
6. [Verification Procedures](#verification-procedures)

---

## VPP App Configuration

### Adding Company Portal as VPP App

**Navigation Path:**
```
Intune Admin Center > Apps > iOS/iPadOS > + Add
```

**Step 1: Select App Type**
1. Click **+ Add**
2. Select **iOS store app (VPP)** from the dropdown
3. Click **Select**

**Step 2: Search for App**
1. In the search box, type: `Intune Company Portal`
2. Click **Search the App Store**
3. Select **Intune Company Portal** by Microsoft Corporation
4. Click **Select**

**Step 3: Configure App Information**

| Field | Value |
|-------|-------|
| Name | Intune Company Portal |
| Description | Microsoft Intune Company Portal for device management |
| Publisher | Microsoft Corporation |
| Minimum OS | iOS 15.0 (or your minimum supported) |
| Category | Business |
| Show as featured | No |
| Information URL | (optional) |
| Privacy URL | (optional) |
| Owner | IT Department |

Click **Next**

**Step 4: Scope Tags**
- Select appropriate scope tags if using RBAC
- Click **Next**

**Step 5: Assignments (CRITICAL)**

**Required Section:**
1. Click **+ Add group**
2. Select your iPad device group (e.g., "All iPads" or "Corporate iPads")
3. **VPP license type:** Select **Device licensing** (CRITICAL!)
4. Click **Select**

| Assignment Setting | Value |
|-------------------|-------|
| Group | [Your iPad device group] |
| License type | Device licensing |
| Uninstall on removal | Yes |

**DO NOT use user licensing for this scenario.**

Click **Next**

**Step 6: Review + Create**
1. Review all settings
2. Ensure "Device licensing" is shown
3. Click **Create**

---

### Adding Google Chrome as VPP App

**Navigation Path:**
```
Intune Admin Center > Apps > iOS/iPadOS > + Add
```

**Step 1: Select App Type**
1. Click **+ Add**
2. Select **iOS store app (VPP)**
3. Click **Select**

**Step 2: Search for App**
1. Search: `Google Chrome`
2. Select **Chrome** by Google LLC
3. Click **Select**

**Step 3: Configure App Information**

| Field | Value |
|-------|-------|
| Name | Google Chrome |
| Description | Google Chrome web browser |
| Publisher | Google LLC |
| Minimum OS | iOS 15.0 |
| Category | Productivity |
| Show as featured | No |

Click **Next**

**Step 4: Scope Tags**
- Configure as needed
- Click **Next**

**Step 5: Assignments**

**Required Section:**
1. Click **+ Add group**
2. Select your iPad device group
3. **VPP license type:** Select **Device licensing**
4. Click **Select**

Click **Next**

**Step 6: Review + Create**
1. Verify device licensing
2. Click **Create**

---

### Verifying VPP App Configuration

**Check App Assignments:**
```
Apps > iOS/iPadOS > [App Name] > Properties
```

1. Scroll to **Assignments**
2. Click **Edit**
3. Verify:
   - Group is correct
   - License type shows **Device**

**Check VPP Token Sync:**
```
Tenant administration > Connectors and tokens > Apple VPP tokens
```

1. Select your token
2. Check **Last sync**: Should be recent
3. Check **Status**: Should be "Active"
4. Check **Total licenses** vs **Used licenses**

**Check App in Apps List:**
```
Apps > iOS/iPadOS
```

1. Find Company Portal and Chrome
2. Verify they show "(VPP)" in the type
3. Click each app > **Device install status**
4. Check for any failures

---

## Device Group Setup

### Create Dynamic Device Group for iPads

**Navigation Path:**
```
Azure AD Admin Center > Groups > + New group
```

OR

```
Intune Admin Center > Groups > + New group
```

**Configuration:**

| Field | Value |
|-------|-------|
| Group type | Security |
| Group name | iPads - Corporate Devices |
| Group description | All corporate-managed iPads |
| Membership type | Dynamic Device |

**Dynamic Membership Rule:**
```
(device.deviceOSType -eq "iPad") and (device.managementType -eq "MDM")
```

**Alternative rules:**

For supervised iPads only:
```
(device.deviceOSType -eq "iPad") and (device.deviceManagementAppId -eq "0000000a-0000-0000-c000-000000000000")
```

For specific model:
```
(device.deviceOSType -eq "iPad") and (device.deviceModel -startsWith "iPad")
```

For devices in a naming convention:
```
(device.displayName -startsWith "IPAD-") and (device.deviceOSType -eq "iPad")
```

Click **Create**

### Verify Group Membership

1. Wait 5-10 minutes for dynamic membership to process
2. Click on the group
3. Select **Members**
4. Verify iPads appear in the list

---

## Configuration Profiles

### Profile 1: Allow App Installation (Remove Restrictions)

**Purpose:** Ensure App Store is NOT restricted so VPP apps can install.

**Navigation:**
```
Intune Admin Center > Devices > Configuration profiles > + Create profile
```

**Configuration:**

| Field | Value |
|-------|-------|
| Platform | iOS/iPadOS |
| Profile type | Templates |
| Template name | Device restrictions |

Click **Create**

**Basics:**
| Field | Value |
|-------|-------|
| Name | iPad - Allow App Installation |
| Description | Allows VPP app installation, managed App Store access |

**Configuration Settings:**

**App Store, Doc Viewing, Gaming:**
| Setting | Value | Notes |
|---------|-------|-------|
| Block App Store | No | Required for VPP |
| Block using iTunes Store | Not configured | Optional |
| Block automatically downloading apps | Not configured | Optional |
| Block playback of explicit music, podcast, and iTunes U content | Not configured | Optional |
| Block adding Game Center friends | Not configured | Optional |
| Block Game Center | Not configured | Optional |
| Block multiplayer gaming | Not configured | Optional |

**Built-in Apps:**
| Setting | Value |
|---------|-------|
| Block use of AirDrop | Not configured |
| Block Siri | Not configured |

**Assignments:**
- Assign to your iPad device group
- Click **Next** > **Create**

---

### Profile 2: Disable Screen Time (If Needed)

**Purpose:** Prevent Screen Time from blocking app installation.

**Navigation:**
```
Intune Admin Center > Devices > Configuration profiles > + Create profile
```

**Configuration:**

| Field | Value |
|-------|-------|
| Platform | iOS/iPadOS |
| Profile type | Templates |
| Template name | Device restrictions |

**Basics:**
| Field | Value |
|-------|-------|
| Name | iPad - Disable Screen Time Restrictions |
| Description | Prevents Screen Time from blocking managed apps |

**Configuration Settings:**

**Built-in Apps:**
| Setting | Value |
|---------|-------|
| Block Screen Time | Yes |

**Assignments:**
- Assign to iPad device group
- Click **Create**

---

### Profile 3: Security Settings (Recommended)

**Navigation:**
```
Intune Admin Center > Devices > Configuration profiles > + Create profile
```

**Configuration:**

| Field | Value |
|-------|-------|
| Platform | iOS/iPadOS |
| Profile type | Templates |
| Template name | Device restrictions |

**Basics:**
| Field | Value |
|-------|-------|
| Name | iPad - Security Settings |
| Description | Corporate security policy for iPads |

**Password:**
| Setting | Value |
|---------|-------|
| Require a password | Yes |
| Required password type | Alphanumeric |
| Minimum password length | 6 |
| Maximum grace period (minutes) | 0 |
| Maximum allowed sign-in failures | 10 |
| Seconds of inactivity before screen locks | 5 |

**Cloud and Storage:**
| Setting | Value |
|---------|-------|
| Block backup to iCloud | Yes (recommended) |
| Block iCloud document and data sync | Not configured |
| Block managed apps from storing data in iCloud | Yes |

**Assignments:**
- Assign to iPad device group
- Click **Create**

---

## Compliance Policies

### Create iPad Compliance Policy

**Navigation:**
```
Intune Admin Center > Devices > Compliance policies > + Create Policy
```

**Configuration:**

| Field | Value |
|-------|-------|
| Platform | iOS/iPadOS |

Click **Create**

**Basics:**
| Field | Value |
|-------|-------|
| Name | iPad - Compliance Policy |
| Description | Compliance requirements for corporate iPads |

**Compliance Settings:**

**Device Health:**
| Setting | Value |
|---------|-------|
| Jailbroken devices | Block |

**Device Properties:**
| Setting | Value |
|---------|-------|
| Minimum OS version | 16.0 (or your requirement) |

**System Security:**
| Setting | Value |
|---------|-------|
| Require a password | Yes |
| Required password type | Device default |
| Minimum password length | 6 |

**Actions for noncompliance:**
| Action | Schedule |
|--------|----------|
| Mark device noncompliant | Immediately |
| Send email notification | After 1 day |
| Retire device | After 30 days |

**Assignments:**
- Assign to iPad device group
- Click **Create**

---

## Common Settings That Break Deployment

### Settings That WILL Break VPP App Installation

```
┌─────────────────────────────────────────────────────────────────┐
│              SETTINGS THAT BREAK VPP DEPLOYMENT                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. BLOCK APP STORE = YES                                       │
│     ─────────────────────────────────────────────────────────   │
│     Location: Device restrictions > App Store, Doc Viewing      │
│     Effect: VPP apps cannot download (even device-licensed)     │
│     Fix: Set to "No" or "Not configured"                        │
│                                                                  │
│  2. USER LICENSING (instead of Device Licensing)                │
│     ─────────────────────────────────────────────────────────   │
│     Location: App > Assignments > License type                  │
│     Effect: Requires Apple ID, fails without one                │
│     Fix: Change to "Device licensing"                           │
│                                                                  │
│  3. ASSIGN TO USER GROUP (not Device Group)                     │
│     ─────────────────────────────────────────────────────────   │
│     Location: App > Assignments                                 │
│     Effect: Won't install on userless devices                   │
│     Fix: Assign to device group instead                         │
│                                                                  │
│  4. MANAGED APPLE ID WITHOUT APP STORE ACCESS                   │
│     ─────────────────────────────────────────────────────────   │
│     Location: ABM > Managed Apple ID settings                   │
│     Effect: Managed Apple ID can't access App Store             │
│     Fix: Use device licensing (no Apple ID required)            │
│                                                                  │
│  5. VPP TOKEN EXPIRED/NOT SYNCED                                │
│     ─────────────────────────────────────────────────────────   │
│     Location: Tenant admin > Connectors > VPP tokens            │
│     Effect: Apps show but won't download                        │
│     Fix: Renew token, sync token                                │
│                                                                  │
│  6. SCREEN TIME CONTENT RESTRICTIONS                            │
│     ─────────────────────────────────────────────────────────   │
│     Location: Device's Screen Time settings                     │
│     Effect: App Store greyed out locally                        │
│     Fix: Block Screen Time via Intune profile                   │
│                                                                  │
│  7. ENROLLMENT WITHOUT SUPERVISION                              │
│     ─────────────────────────────────────────────────────────   │
│     Location: Enrollment profile settings                       │
│     Effect: Many VPP features don't work                        │
│     Fix: Re-enroll with supervised enrollment profile           │
│                                                                  │
│  8. AVAILABLE (instead of Required)                             │
│     ─────────────────────────────────────────────────────────   │
│     Location: App > Assignments > Assignment type               │
│     Effect: App not pushed, user must request                   │
│     Fix: Change to "Required"                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Verification Checklist for App Deployment

```
VPP APP DEPLOYMENT CHECKLIST
============================

VPP TOKEN
[ ] Token status: Active
[ ] Token not expired
[ ] Last sync: Within 24 hours
[ ] Licenses available (Total > Used)

APP CONFIGURATION
[ ] App type: iOS store app (VPP)
[ ] License type: Device (not User)
[ ] Assignment type: Required (not Available)
[ ] Assigned to: Device group (not User group)

DEVICE CONFIGURATION
[ ] Device is supervised
[ ] No "Block App Store" restriction
[ ] No Screen Time restrictions
[ ] Device in correct device group
[ ] Device has checked in recently

ENROLLMENT
[ ] Enrolled via ADE/ABM (preferred)
[ ] OR: Enrolled via Apple Configurator (supervised)
[ ] Enrollment profile has supervision enabled
```

---

## Verification Procedures

### Check VPP Token Status

**Path:**
```
Tenant administration > Connectors and tokens > Apple VPP tokens
```

**Verify:**
- Status: Active (green checkmark)
- Last sync: Recent date/time
- Expiration: Not expired (renew 30 days before)

**If issues:**
1. Click the token
2. Click **Sync**
3. Wait and refresh
4. If still failing, download new token from ABM

### Check App Assignment

**Path:**
```
Apps > iOS/iPadOS > [App name] > Device install status
```

**Statuses explained:**
| Status | Meaning | Action |
|--------|---------|--------|
| Installed | App successfully installed | None needed |
| Pending | Waiting for device check-in | Wait or force sync |
| Failed | Installation failed | Check error, see below |
| Not Applicable | Device not in assignment group | Verify group membership |
| Not Installed | Available but not installed | Check if Required |

### Check Individual Device

**Path:**
```
Devices > iOS/iPadOS > [Device name]
```

**Verify:**
- Compliance state: Compliant
- Supervised: Yes
- OS version: Current
- Last check-in: Recent

**Path:**
```
Devices > iOS/iPadOS > [Device name] > Managed apps
```

**Verify:**
- Company Portal: Installed
- Chrome: Installed

### Force Device Sync

**From Intune:**
```
Devices > iOS/iPadOS > [Device name] > Sync
```

**From Device:**
```
Settings > General > VPN & Device Management > [MDM Profile] > Sync
```

**From Company Portal:**
```
Open Company Portal > Settings > Sync
```

### Check App Install Logs

**In Intune:**
```
Apps > iOS/iPadOS > [App name] > Device install status > [Failed device]
```

Click on failed device to see error details.

**Common error codes:**
| Error | Meaning | Solution |
|-------|---------|----------|
| 0x87D1041C | VPP license not available | Purchase more licenses |
| 0x87D10435 | VPP token invalid | Renew/sync token |
| 0x87D10437 | App not assigned | Check assignments |
| 0x87D10442 | User canceled | N/A for device licensing |
| 0x87D10438 | Device not supervised | Re-enroll supervised |

---

## Quick Reference: Intune Navigation Paths

| Task | Navigation Path |
|------|----------------|
| Add VPP app | Apps > iOS/iPadOS > + Add > iOS store app (VPP) |
| Check VPP token | Tenant admin > Connectors > Apple VPP tokens |
| Create device group | Groups > + New group |
| Create config profile | Devices > Configuration profiles > + Create |
| Create compliance policy | Devices > Compliance policies > + Create |
| Check device status | Devices > iOS/iPadOS > [Device name] |
| Check app install status | Apps > iOS/iPadOS > [App] > Device install status |
| Sync device | Devices > iOS/iPadOS > [Device] > Sync |
| Check enrollment profile | Devices > iOS enrollment > Enrollment program tokens > Profiles |

---

## Next Steps

- For Apple Configurator fallback, see [04-APPLE-CONFIGURATOR-FALLBACK.md](04-APPLE-CONFIGURATOR-FALLBACK.md)
- For field remediation, see [05-FIELD-REMEDIATION.md](05-FIELD-REMEDIATION.md)
- For complete runbook, see [06-DEPLOYMENT-RUNBOOK.md](06-DEPLOYMENT-RUNBOOK.md)

---

*SBS Federal IT Department*
