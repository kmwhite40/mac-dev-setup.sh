# iPad Intune Deployment - Field Remediation Checklist

## Remediation Guide for Devices Already in the Field

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [Assessment Framework](#assessment-framework)
2. [Remediation Scenarios](#remediation-scenarios)
3. [Removing Conflicting Profiles](#removing-conflicting-profiles)
4. [When Wipe is Required](#when-wipe-is-required)
5. [Re-Enrollment Procedures](#re-enrollment-procedures)
6. [Verification Checklist](#verification-checklist)
7. [Remediation Decision Tree](#remediation-decision-tree)

---

## Assessment Framework

### Initial Assessment Questions

Before attempting remediation, answer these questions:

```
FIELD DEVICE ASSESSMENT
=======================

1. CURRENT STATE
   [ ] Device serial number: _______________
   [ ] Current iOS/iPadOS version: _______________
   [ ] Is device supervised? YES / NO / UNKNOWN
   [ ] Is device enrolled in Intune? YES / NO / UNKNOWN
   [ ] Is device in Apple Business Manager? YES / NO / UNKNOWN

2. SYMPTOMS
   [ ] App Store greyed out? YES / NO
   [ ] Company Portal greyed out? YES / NO
   [ ] Company Portal not installed? YES / NO
   [ ] Cannot install any apps? YES / NO
   [ ] Receives error messages? YES / NO
   [ ] Error message: _______________

3. USER IMPACT
   [ ] User has important data on device? YES / NO
   [ ] Data backed up to iCloud? YES / NO
   [ ] Can user wait for remediation? YES / NO
   [ ] Device needed for work today? YES / NO

4. MANAGEMENT STATE
   [ ] MDM profile(s) visible in Settings? YES / NO
   [ ] Multiple MDM profiles? YES / NO
   [ ] Profile from your organization? YES / NO
   [ ] Profile from unknown source? YES / NO

5. APPLE ID STATE
   [ ] Apple ID signed in? YES / NO
   [ ] Is it personal or managed Apple ID? _______________
   [ ] Find My iPad enabled? YES / NO
```

### Risk Assessment

| Scenario | Risk Level | Data Loss? | Recommended Action |
|----------|------------|------------|-------------------|
| Restriction profile issue | Low | No | Remove/modify profile |
| Screen Time restrictions | Low | No | Disable via MDM |
| Not supervised, in ABM | Medium | Wipe required | Re-enroll supervised |
| Not supervised, not in ABM | Medium | Wipe required | Configurator + wipe |
| Conflicting MDM | High | Wipe required | Full unenroll + re-enroll |
| Activation Lock | High | Wipe required | Remove lock first |

---

## Remediation Scenarios

### Scenario 1: Restriction Profile Blocking App Store

**Symptoms:**
- App Store icon greyed out
- VPP apps won't install
- Profile visible in Settings with restrictions

**Root Cause:**
- Configuration profile has "Block App Store" enabled

**Remediation (No Wipe Required):**

1. **Identify the Profile:**
   ```
   Intune > Devices > Configuration profiles > Filter: iOS/iPadOS
   ```
   - Find profiles assigned to the device/group
   - Check for "Device restrictions" profiles
   - Look for "Block App Store" setting

2. **Option A: Modify Existing Profile:**
   - Edit the restriction profile
   - Change "Block App Store" to **Not configured** or **No**
   - Save and sync

3. **Option B: Remove Profile from Device:**
   ```
   Intune > Devices > iOS/iPadOS > [Device] > Device configuration
   ```
   - Identify offending profile
   - Remove device/user from assignment group
   - OR delete profile if no longer needed

4. **Force Sync:**
   ```
   Intune > Devices > [Device] > Sync
   ```

5. **Verify on Device:**
   - Wait 5-15 minutes
   - Check if App Store is accessible
   - Check if VPP apps are installing

---

### Scenario 2: Screen Time Restrictions

**Symptoms:**
- App Store greyed out
- Settings > Screen Time shows restrictions enabled
- No MDM profile with App Store restrictions

**Root Cause:**
- Local Screen Time restrictions (user or parent set)
- OR Screen Time configured via previous management

**Remediation (No Wipe Required):**

**Option A: Disable via Intune Profile:**

1. Create new restriction profile:
   ```
   Intune > Devices > Configuration profiles > + Create > iOS/iPadOS > Device restrictions
   ```

2. Configure:
   - **Name:** Block Screen Time
   - **Built-in Apps > Block Screen Time:** Yes

3. Assign to device group

4. Sync device

**Option B: Manual on Device (if accessible):**

1. Go to: `Settings > Screen Time`
2. If passcode protected, need passcode or wipe
3. Navigate to: `Content & Privacy Restrictions`
4. Tap `iTunes & App Store Purchases`
5. Change `Installing Apps` to **Allow**

**Option C: If Screen Time Passcode Unknown:**
- Factory reset required (Scenario 6)

---

### Scenario 3: Device Not Supervised (In ABM)

**Symptoms:**
- Device enrolled but Settings > About doesn't show "Supervised"
- Limited management capabilities
- Some VPP features don't work

**Root Cause:**
- Device was enrolled without supervision
- Enrollment profile didn't have "Supervised = Yes"

**Remediation (Wipe Required):**

1. **Verify Device in ABM:**
   ```
   Apple Business Manager > Devices > Search [Serial]
   ```
   - Confirm device is present
   - Confirm assigned to Intune MDM server

2. **Verify Enrollment Profile:**
   ```
   Intune > Devices > iOS enrollment > Enrollment program tokens > [Token] > Profiles
   ```
   - Confirm profile has **Supervised = Yes**
   - Confirm profile assigned to device

3. **Unenroll Device:**

   **From Intune:**
   ```
   Intune > Devices > [Device] > Wipe
   ```

   **From Device:**
   ```
   Settings > General > Transfer or Reset iPad > Erase All Content and Settings
   ```

4. **Wait for Wipe to Complete**

5. **Re-Setup Device:**
   - Device will auto-enroll via ADE
   - Complete Setup Assistant
   - Verify "Supervised" text appears

---

### Scenario 4: Device Not Supervised (Not in ABM)

**Symptoms:**
- Device not supervised
- Device NOT in Apple Business Manager

**Root Cause:**
- Device purchased outside ABM channels
- Device not added to ABM

**Remediation (Wipe Required + Physical Access):**

1. **Backup Important Data:**
   - Ensure user backs up to iCloud or computer
   - Document any critical apps/data

2. **Prepare Mac with Apple Configurator:**
   - Install Apple Configurator 2
   - Connect iPad via USB

3. **Add to ABM (Recommended):**

   See [04-APPLE-CONFIGURATOR-FALLBACK.md](04-APPLE-CONFIGURATOR-FALLBACK.md) Method 1

   - Prepare device with "Add to ABM" option
   - Device is wiped and added to ABM
   - Assign to Intune in ABM
   - Set up device normally

4. **OR Direct Enrollment (Alternative):**

   See [04-APPLE-CONFIGURATOR-FALLBACK.md](04-APPLE-CONFIGURATOR-FALLBACK.md) Method 2

   - Prepare with Intune enrollment profile
   - Device is wiped and enrolled supervised
   - Set up device

---

### Scenario 5: Conflicting MDM Enrollment

**Symptoms:**
- Multiple MDM profiles visible
- Device shows in another MDM console
- Enrollment errors in Intune
- Strange restriction behavior

**Root Cause:**
- Device previously enrolled in different MDM
- Incomplete unenrollment
- Dual enrollment attempt

**Remediation (Wipe Usually Required):**

1. **Identify All MDM Profiles:**
   ```
   Settings > General > VPN & Device Management
   ```
   - List all profiles
   - Note organization names

2. **Attempt Profile Removal:**

   **For each non-Intune profile:**
   - Tap profile
   - Tap "Remove Management" (if available)
   - Enter passcode if required

3. **If Removal Not Possible:**
   - Profile is locked
   - Factory reset required

4. **In Previous MDM Console (if accessible):**
   - Find device
   - Remove/delete device
   - Remove remote wipe hold if any

5. **Factory Reset:**
   ```
   Settings > General > Transfer or Reset iPad > Erase All Content and Settings
   ```

   OR

   Use Recovery Mode if device is locked

6. **Re-Enroll in Intune:**
   - Follow ADE enrollment if device in ABM
   - Use Configurator if not in ABM

---

### Scenario 6: Activation Lock Present

**Symptoms:**
- Device asks for Apple ID during setup
- Cannot proceed past Activation Lock screen
- "This iPad is linked to an Apple ID"

**Root Cause:**
- Find My iPad was enabled
- Previous owner's Apple ID still linked
- Device not properly unenrolled

**Remediation:**

1. **If You Have Apple ID Credentials:**
   - Enter the Apple ID and password
   - Activation Lock is removed
   - Continue setup

2. **If Organization Owns Device (via ABM):**
   ```
   Apple Business Manager > Devices > [Search device] > Activation Lock
   ```
   - Click "Remove Activation Lock"
   - Enter your ABM admin credentials
   - Activation Lock bypassed

3. **If Previous Employee's Apple ID:**
   - Contact former employee
   - Ask them to sign in to icloud.com/find
   - Remove device from their account

4. **If Cannot Contact Previous Owner:**
   - Proof of purchase required
   - Contact Apple Support with proof
   - They may be able to remove lock

5. **After Activation Lock Removed:**
   - Factory reset device
   - Re-enroll normally

---

## Removing Conflicting Profiles

### Safe Profile Removal

**Check Profile Type First:**
```
Settings > General > VPN & Device Management > [Profile]
```

| Profile Type | Can Remove? | How |
|--------------|-------------|-----|
| MDM Profile | Sometimes | Tap "Remove Management" |
| Configuration Profile | Usually | Tap profile > Remove |
| Supervised MDM | Rarely | Usually requires wipe |
| ABM/ADE MDM | No | Must wipe device |

### Steps to Remove MDM Profile

1. **Go to:**
   ```
   Settings > General > VPN & Device Management
   ```

2. **Tap on the MDM Profile**

3. **Look for "Remove Management":**
   - If present: Tap it
   - Enter device passcode
   - Confirm removal

4. **If "Remove Management" not present:**
   - Profile is locked by MDM
   - Factory reset required

### Profile Removal via Intune (Remote)

```
Intune Admin Center > Devices > iOS/iPadOS > [Device]
```

**Options:**
- **Retire:** Removes corporate data/profiles, keeps personal
- **Wipe:** Factory reset, removes everything
- **Delete:** Removes from Intune inventory (device keeps current state)

**For Re-enrollment:**
1. Use **Wipe** to factory reset
2. Device will re-enroll via ADE if in ABM
3. OR use Configurator for devices not in ABM

---

## When Wipe is Required

### Wipe IS Required

| Situation | Why Wipe Required |
|-----------|------------------|
| Need to add supervision | Supervision only set during setup |
| Conflicting MDM locked | Cannot remove locked profile |
| Screen Time passcode unknown | No way to disable restrictions |
| Activation Lock (no credentials) | Prevents any setup |
| Adding device to ABM | Configurator wipes during add |
| Unknown device state | Clean slate is safest |

### Wipe is NOT Required

| Situation | Alternative Action |
|-----------|-------------------|
| App Store blocked by profile | Modify/remove profile |
| Screen Time (passcode known) | Disable manually or via profile |
| VPP app not installing | Fix VPP token/licensing |
| MDM profile removable | Remove profile, re-enroll |
| Minor configuration issues | Push correct profiles |

### How to Perform Factory Reset

**Method 1: From Device Settings (Preferred)**
```
Settings > General > Transfer or Reset iPad > Erase All Content and Settings
```
- Enter passcode
- Confirm erase
- Wait for completion

**Method 2: From Intune (Remote)**
```
Intune > Devices > [Device] > Wipe
```
- Confirm wipe
- Device receives command on next check-in
- Wait for completion

**Method 3: Recovery Mode (If Device Locked)**

1. Connect iPad to Mac with Finder (or PC with iTunes)
2. Force restart into Recovery Mode:

   **iPad with Face ID:**
   - Press and release Volume Up
   - Press and release Volume Down
   - Hold Top button until Recovery screen

   **iPad with Home Button:**
   - Hold Home + Top buttons until Recovery screen

3. In Finder/iTunes: Click "Restore"
4. Wait for restore to complete

---

## Re-Enrollment Procedures

### Re-Enrollment After Wipe (Device in ABM)

1. **Ensure ABM Configuration:**
   - Device assigned to Intune MDM server
   - Enrollment profile assigned
   - Profile has Supervised = Yes

2. **Turn on Device**

3. **Complete Setup Assistant:**
   - Select language, region
   - Connect to Wi-Fi
   - "Remote Management" screen appears
   - Tap "Continue" to enroll

4. **Enrollment Completes:**
   - Device enrolls into Intune
   - Profiles push automatically
   - VPP apps install automatically

5. **Verify:**
   - Settings > About shows "Supervised"
   - Company Portal and Chrome installed

### Re-Enrollment After Wipe (Device NOT in ABM)

**Option A: Add to ABM First (Recommended)**

1. Use Apple Configurator to add to ABM
2. Follow ABM enrollment process
3. See [04-APPLE-CONFIGURATOR-FALLBACK.md](04-APPLE-CONFIGURATOR-FALLBACK.md)

**Option B: Direct Configurator Enrollment**

1. Prepare with Apple Configurator
2. Include Intune enrollment profile
3. Device enrolls supervised
4. See [04-APPLE-CONFIGURATOR-FALLBACK.md](04-APPLE-CONFIGURATOR-FALLBACK.md)

**Option C: Manual Enrollment (Not Recommended)**

This results in **non-supervised** device:

1. Turn on device, complete setup
2. Install Company Portal from App Store
3. Open Company Portal, sign in
4. Enroll device

**Warning:** Manual enrollment is NOT supervised and many management features won't work.

---

## Verification Checklist

### Post-Remediation Verification

```
POST-REMEDIATION CHECKLIST
==========================
Date: _______________
Device Serial: _______________
Technician: _______________

DEVICE VERIFICATION
[ ] Device is powered on and functional
[ ] Settings accessible
[ ] WiFi connected

SUPERVISION CHECK
[ ] Settings > General > About
[ ] Text shows: "This iPad is supervised and managed by [org]"

MDM ENROLLMENT CHECK
[ ] Settings > General > VPN & Device Management
[ ] Only your organization's MDM profile present
[ ] Profile shows correct organization name
[ ] No other MDM profiles present

APP VERIFICATION
[ ] App Store icon is NOT greyed out
[ ] Company Portal is installed
[ ] Company Portal opens successfully
[ ] Chrome is installed
[ ] Chrome opens successfully
[ ] Apps are NOT greyed out

INTUNE CONSOLE CHECK
[ ] Device appears in Intune
[ ] Compliance state: Compliant
[ ] Supervised: Yes
[ ] Last check-in: Recent (within minutes)
[ ] Managed apps show: Installed

FINAL TEST
[ ] Can install a test app from Company Portal
[ ] Can access corporate resources (if applicable)
[ ] User can sign in (if user-assigned device)

SIGN-OFF
Verified by: _______________ Date: _______________
```

---

## Remediation Decision Tree

```
┌─────────────────────────────────────────────────────────────────┐
│            FIELD REMEDIATION DECISION TREE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  START: Device has App Store / Company Portal Issue              │
│                          │                                       │
│                          ▼                                       │
│  ┌────────────────────────────────────────┐                     │
│  │ Is device currently supervised?         │                     │
│  │ (Settings > General > About)           │                     │
│  └────────────────────────────────────────┘                     │
│           │                    │                                 │
│          YES                   NO                                │
│           │                    │                                 │
│           ▼                    ▼                                 │
│  ┌─────────────────┐   ┌─────────────────────────┐              │
│  │ Is App Store    │   │ Is device in ABM?       │              │
│  │ blocked by      │   │ (Check ABM > Devices)   │              │
│  │ Intune profile? │   └─────────────────────────┘              │
│  └─────────────────┘          │           │                     │
│      │          │            YES          NO                     │
│     YES         NO            │           │                      │
│      │          │             ▼           ▼                      │
│      ▼          ▼      ┌──────────┐ ┌──────────────┐            │
│  ┌────────┐  ┌────────┐│ WIPE &   │ │ WIPE + ADD   │            │
│  │ MODIFY │  │ CHECK  ││ RE-ENROLL│ │ TO ABM VIA   │            │
│  │ PROFILE│  │ SCREEN ││ VIA ADE  │ │ CONFIGURATOR │            │
│  └────────┘  │ TIME   │└──────────┘ └──────────────┘            │
│      │       └────────┘                                          │
│      │            │                                              │
│      │      ┌─────┴──────┐                                      │
│      │     YES           NO                                      │
│      │      │            │                                       │
│      │      ▼            ▼                                       │
│      │  ┌────────┐  ┌──────────┐                                │
│      │  │ DISABLE│  │ CHECK    │                                │
│      │  │ SCREEN │  │ VPP      │                                │
│      │  │ TIME   │  │ CONFIG   │                                │
│      │  └────────┘  └──────────┘                                │
│      │      │            │                                       │
│      │      │      ┌─────┴──────┐                               │
│      │      │     YES           NO                               │
│      │      │      │            │                                │
│      │      │      ▼            ▼                                │
│      │      │  ┌────────┐  ┌──────────┐                         │
│      │      │  │ FIX    │  │ ESCALATE │                         │
│      │      │  │ VPP    │  │ FOR      │                         │
│      │      │  │ TOKEN  │  │ REVIEW   │                         │
│      │      │  └────────┘  └──────────┘                         │
│      │      │      │                                             │
│      ▼      ▼      ▼                                             │
│  ┌─────────────────────────────────────────┐                    │
│  │           SYNC & VERIFY                  │                    │
│  │  • Force device sync                    │                    │
│  │  • Wait 5-15 minutes                    │                    │
│  │  • Verify App Store accessible          │                    │
│  │  • Verify apps installed                │                    │
│  └─────────────────────────────────────────┘                    │
│                          │                                       │
│                    ┌─────┴──────┐                               │
│                  SUCCESS      FAILURE                            │
│                    │            │                                │
│                    ▼            ▼                                │
│              ┌──────────┐  ┌──────────────┐                     │
│              │ COMPLETE │  │ ESCALATE TO  │                     │
│              │ CHECKLIST│  │ TIER 2 WITH  │                     │
│              │          │  │ DIAGNOSTICS  │                     │
│              └──────────┘  └──────────────┘                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Escalation Path

| Level | When to Escalate | Information to Include |
|-------|------------------|----------------------|
| Tier 1 | First contact | Device serial, symptoms |
| Tier 2 | Standard remediation fails | Diagnosis checklist, actions tried |
| Tier 3 | Wipe required / ABM issues | Full assessment, approval needed |
| Vendor Support | Activation Lock / hardware | Proof of purchase, serial |

---

## Next Steps

- For complete deployment runbook, see [06-DEPLOYMENT-RUNBOOK.md](06-DEPLOYMENT-RUNBOOK.md)
- For initial diagnosis, see [01-DIAGNOSIS-GUIDE.md](01-DIAGNOSIS-GUIDE.md)

---

*SBS Federal IT Department*
