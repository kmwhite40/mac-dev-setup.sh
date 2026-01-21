# iPad Intune Deployment - Diagnosis Guide

## Why is Company Portal / App Store Greyed Out?

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [Overview](#overview)
2. [Most Likely Causes](#most-likely-causes)
3. [Diagnosis Procedures](#diagnosis-procedures)
4. [Evidence Collection](#evidence-collection)
5. [Decision Matrix](#decision-matrix)

---

## Overview

When Company Portal and/or the App Store appear greyed out on iPads, it typically indicates one of several restriction scenarios. This guide helps diagnose the root cause before attempting remediation.

### Symptoms
- App Store icon is greyed out and unresponsive
- Company Portal is greyed out (if previously installed)
- "Installing apps is not allowed" message
- VPP apps fail to install silently
- Device shows as enrolled but apps won't push

---

## Most Likely Causes

### Cause 1: App Store Disabled via Configuration Profile

**Likelihood:** HIGH (Most Common)

**What it is:**
A configuration profile (from Intune, another MDM, or Apple Configurator) has the "Allow App Store" restriction set to `false`.

**How to confirm on iPad:**
```
Settings > General > VPN & Device Management
```
- Look for installed profiles
- Tap each profile and check "Restrictions" payload
- Look for "App Installation" or "App Store" restrictions

**How to confirm in Intune:**
```
Intune Admin Center > Devices > Configuration profiles
```
1. Filter by Platform: iOS/iPadOS
2. Check each profile assigned to the device/group
3. Look for: Device Restrictions > App Store, Doc Viewing, Gaming
4. Check: "Block App Store" setting

**Evidence that confirms this cause:**
- Profile visible under VPN & Device Management
- Profile shows "Restrictions" payload
- Intune shows restriction profile assigned
- App Store icon is completely greyed (not just slow)

---

### Cause 2: Screen Time / Content & Privacy Restrictions

**Likelihood:** MEDIUM-HIGH

**What it is:**
iOS Screen Time (local device setting) has "iTunes & App Store Purchases" disabled under Content & Privacy Restrictions.

**How to confirm on iPad:**
```
Settings > Screen Time > Content & Privacy Restrictions
```
1. Check if Content & Privacy Restrictions is ON
2. Tap "iTunes & App Store Purchases"
3. Check "Installing Apps" - if set to "Don't Allow", this is the cause

**How to confirm in Intune:**
```
Intune Admin Center > Devices > Configuration profiles
```
- Check for "Device restrictions" profiles
- Look for "Built-in Apps" section
- Check "Block Screen Time" setting

**Evidence that confirms this cause:**
- Screen Time is enabled on device
- Content & Privacy Restrictions shows "Installing Apps: Don't Allow"
- No MDM profile visible, but App Store still greyed
- User may have set this manually or via Family Sharing

---

### Cause 3: Device Not Supervised

**Likelihood:** MEDIUM

**What it is:**
The device is enrolled in Intune but NOT in supervised mode. Many app deployment and restriction management features require supervision.

**How to confirm on iPad:**
```
Settings > General > About
```
- Scroll down and look for: "This iPad is supervised and managed by [Organization]"
- If this text is NOT present, device is not supervised

**How to confirm in Intune:**
```
Intune Admin Center > Devices > iOS/iPadOS > [Select Device]
```
1. Check "Supervised" field in device properties
2. Should show "Yes" for supervised devices
3. Check "Enrollment type" - should be "Device enrollment" or "Automated device enrollment"

**Evidence that confirms this cause:**
- "Supervised" text missing from Settings > General > About
- Intune shows Supervised: No
- Enrollment type shows "User enrollment" only
- VPP device-licensed apps fail to install

---

### Cause 4: Conflicting MDM Enrollment

**Likelihood:** MEDIUM

**What it is:**
Device is enrolled in another MDM solution (or was previously enrolled and not properly unenrolled), causing conflicts.

**How to confirm on iPad:**
```
Settings > General > VPN & Device Management
```
- Look for multiple MDM profiles
- Check for profiles from unknown sources
- Look for "Mobile Device Management" section

**How to confirm in Intune:**
```
Intune Admin Center > Devices > iOS/iPadOS > [Select Device]
```
- Check if device appears
- Check "Management state"
- Look for enrollment errors

**Evidence that confirms this cause:**
- Multiple MDM profiles visible
- Device appears in two MDM consoles
- Enrollment state shows errors
- Profile from different organization visible

---

### Cause 5: Apple ID / Managed Apple ID Issues

**Likelihood:** MEDIUM

**What it is:**
Device has Apple ID restrictions, no Apple ID signed in, or Managed Apple ID conflicts preventing App Store access.

**How to confirm on iPad:**
```
Settings > [User Name] (top of Settings)
```
- Check if signed into an Apple ID
- Check if it's a Managed Apple ID (@yourorg.appleid.com)
- Check "Media & Purchases" settings

```
Settings > General > VPN & Device Management > [MDM Profile]
```
- Check if "Account modifications" is restricted

**How to confirm in Intune/ABM:**
```
Apple Business Manager > Accounts
```
- Check if Managed Apple IDs are federated
- Check if user has a Managed Apple ID assigned

**Evidence that confirms this cause:**
- No Apple ID signed in
- Apple ID shown but "Media & Purchases" unavailable
- Managed Apple ID doesn't have App Store access
- Account modifications restricted by profile

---

### Cause 6: VPP Token / License Issues

**Likelihood:** MEDIUM-LOW

**What it is:**
VPP/Apps and Books token is expired, revoked, or apps are assigned with user-based licensing but no Apple ID is available.

**How to confirm in Intune:**
```
Intune Admin Center > Tenant administration > Connectors and tokens > Apple VPP tokens
```
1. Check token status (should be "Active")
2. Check expiration date
3. Check "Sync status"

**Evidence that confirms this cause:**
- VPP token shows "Expired" or "Error"
- Apps assigned but show "License unavailable"
- User-licensed apps assigned to userless devices
- Sync errors in token status

---

### Cause 7: Automated Device Enrollment (ADE) Not Configured

**Likelihood:** LOW-MEDIUM (for new devices)

**What it is:**
Device is not linked to ABM/ADE, so it cannot receive supervised enrollment or device-assigned apps properly.

**How to confirm in ABM:**
```
Apple Business Manager > Devices
```
1. Search for device serial number
2. Check if device appears
3. Check assigned MDM server

**How to confirm in Intune:**
```
Intune Admin Center > Devices > iOS/iPadOS > iOS/iPadOS enrollment > Enrollment program tokens
```
1. Select your token
2. Click "Devices"
3. Search for device serial

**Evidence that confirms this cause:**
- Device not found in ABM
- Device not assigned to Intune MDM server in ABM
- Device enrolled but not via ADE
- Setup Assistant didn't show MDM enrollment screens

---

## Diagnosis Procedures

### Quick Diagnosis Flowchart

```
START: App Store/Company Portal Greyed Out
           │
           ▼
┌─────────────────────────────────┐
│ Check Settings > General >      │
│ VPN & Device Management         │
└─────────────────────────────────┘
           │
     ┌─────┴─────┐
     │           │
  Profiles    No Profiles
  Present      Visible
     │           │
     ▼           ▼
┌──────────┐  ┌──────────────────┐
│ Check    │  │ Check Screen     │
│ Profile  │  │ Time >           │
│ Restrict │  │ Content & Privacy│
│ -ions    │  │ Restrictions     │
└──────────┘  └──────────────────┘
     │                  │
     ▼                  ▼
 Profile has        Screen Time
 App Store          has apps
 disabled?          blocked?
     │                  │
   YES ─────────────► CAUSE IDENTIFIED
     │                  │
    NO                 NO
     │                  │
     ▼                  ▼
┌──────────────────────────────────┐
│ Check Settings > General > About │
│ Is device "Supervised"?          │
└──────────────────────────────────┘
           │
     ┌─────┴─────┐
    YES          NO
     │            │
     ▼            ▼
Check Intune   CAUSE: Not
for profile    Supervised
conflicts      (Cause 3)
```

### Step-by-Step Diagnosis

#### Step 1: Physical Device Check (5 minutes)

1. **Check for MDM Profile:**
   ```
   Settings > General > VPN & Device Management
   ```
   - Note all profiles listed
   - Tap each profile, note organization name
   - Look for "Restrictions" in profile details

2. **Check Supervision Status:**
   ```
   Settings > General > About
   ```
   - Scroll to bottom
   - Look for "This iPad is supervised..."
   - Note the managing organization name

3. **Check Screen Time:**
   ```
   Settings > Screen Time
   ```
   - Is Screen Time enabled?
   - Check Content & Privacy Restrictions
   - Check iTunes & App Store Purchases

4. **Check Apple ID:**
   ```
   Settings > [Name at top]
   ```
   - Is an Apple ID signed in?
   - Is it a Managed Apple ID?
   - Can you access Media & Purchases?

#### Step 2: Intune Console Check (10 minutes)

1. **Find the Device:**
   ```
   Intune Admin Center > Devices > iOS/iPadOS > [Search by serial]
   ```

2. **Check Device Properties:**
   - Supervised: Yes/No
   - Enrollment type
   - Compliance state
   - Last check-in

3. **Check Assigned Profiles:**
   ```
   Device > Device configuration > [View assigned profiles]
   ```
   - List all assigned profiles
   - Check for restriction profiles
   - Note any with "App Store" restrictions

4. **Check Assigned Apps:**
   ```
   Device > Discovered apps / Managed apps
   ```
   - Is Company Portal assigned?
   - Is Chrome assigned?
   - What's the installation status?

5. **Check VPP Token:**
   ```
   Tenant administration > Connectors and tokens > Apple VPP tokens
   ```
   - Token status: Active?
   - Last sync: Recent?
   - Available licenses?

#### Step 3: ABM Console Check (5 minutes)

1. **Find Device in ABM:**
   ```
   Apple Business Manager > Devices > Search [serial number]
   ```

2. **Check Assignment:**
   - Is device assigned to your MDM server?
   - What's the enrollment status?

3. **Check Apps and Books:**
   ```
   Apple Business Manager > Apps and Books
   ```
   - Are Company Portal and Chrome purchased?
   - Are licenses available?

---

## Evidence Collection

### Evidence Collection Template

```
DEVICE DIAGNOSIS REPORT
=======================
Date: _______________
Technician: _______________
Device Serial: _______________

PHYSICAL DEVICE CHECKS
----------------------
[ ] Settings > General > VPN & Device Management
    Profiles Found: _______________
    Restrictions Payload: YES / NO
    App Store Restricted: YES / NO / UNKNOWN

[ ] Settings > General > About
    Supervised: YES / NO
    Managed By: _______________

[ ] Settings > Screen Time
    Screen Time Enabled: YES / NO
    Content & Privacy Restrictions: ON / OFF
    Installing Apps: ALLOW / DON'T ALLOW

[ ] Settings > [Apple ID]
    Apple ID Signed In: YES / NO
    Apple ID Type: Personal / Managed / None
    Media & Purchases: Available / Unavailable

INTUNE CONSOLE CHECKS
---------------------
[ ] Device found in Intune: YES / NO
[ ] Supervised in Intune: YES / NO
[ ] Enrollment Type: _______________
[ ] Compliance State: _______________
[ ] Last Check-in: _______________

[ ] Restriction Profiles Assigned:
    Profile 1: _______________
    Profile 2: _______________

[ ] VPP Token Status: Active / Expired / Error
[ ] Company Portal Assignment: _______________
[ ] Chrome Assignment: _______________

ABM CHECKS
----------
[ ] Device in ABM: YES / NO
[ ] Assigned to MDM: YES / NO
[ ] MDM Server Name: _______________

DIAGNOSIS
---------
Primary Cause: _______________
Secondary Factors: _______________

RECOMMENDED ACTION
------------------
[ ] Remove restriction profile
[ ] Disable Screen Time restrictions
[ ] Re-enroll device (supervised)
[ ] Factory reset required
[ ] Fix VPP token
[ ] Other: _______________
```

---

## Decision Matrix

| Symptom | Supervised? | Profile Restriction? | Screen Time? | Apple ID? | Likely Cause | Action |
|---------|-------------|---------------------|--------------|-----------|--------------|--------|
| App Store greyed | Yes | Yes | No | Any | Profile restriction | Remove/modify profile |
| App Store greyed | Yes | No | Yes | Any | Screen Time | Disable via profile |
| App Store greyed | No | N/A | Any | Any | Not supervised | Re-enroll supervised |
| App Store greyed | Yes | No | No | None | Apple ID required | Push VPP device-licensed |
| CP won't install | Yes | No | No | Any | VPP issue | Check token/licenses |
| CP won't install | No | N/A | N/A | Any | Not supervised | Re-enroll supervised |
| Both greyed | Yes | Yes | Maybe | Any | Multiple restrictions | Full remediation |

---

## Next Steps

After diagnosis, proceed to:
- **Cause 1-2 (Restrictions):** See [03-INTUNE-CONFIGURATION.md](03-INTUNE-CONFIGURATION.md)
- **Cause 3 (Not Supervised):** See [02-ABM-ADE-DEPLOYMENT.md](02-ABM-ADE-DEPLOYMENT.md)
- **Cause 4 (Conflicting MDM):** See [05-FIELD-REMEDIATION.md](05-FIELD-REMEDIATION.md)
- **Cause 5-6 (Apple ID/VPP):** See [03-INTUNE-CONFIGURATION.md](03-INTUNE-CONFIGURATION.md)
- **Cause 7 (ADE not configured):** See [02-ABM-ADE-DEPLOYMENT.md](02-ABM-ADE-DEPLOYMENT.md)

---

*SBS Federal IT Department*
