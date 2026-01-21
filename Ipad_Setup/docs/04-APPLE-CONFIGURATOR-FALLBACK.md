# iPad Intune Deployment - Apple Configurator Fallback

## When ABM/ADE is NOT Available

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Table of Contents

1. [When to Use This Method](#when-to-use-this-method)
2. [Apple Configurator Overview](#apple-configurator-overview)
3. [Prerequisites](#prerequisites)
4. [Method 1: Add to ABM via Configurator](#method-1-add-to-abm-via-configurator)
5. [Method 2: Direct Enrollment via Configurator](#method-2-direct-enrollment-via-configurator)
6. [Constraints and Limitations](#constraints-and-limitations)
7. [Step-by-Step Procedures](#step-by-step-procedures)

---

## When to Use This Method

### Scenarios Requiring Apple Configurator

| Scenario | Recommended Method |
|----------|-------------------|
| Devices not purchased through Apple/reseller | Method 1: Add to ABM |
| Legacy devices not in ABM | Method 1: Add to ABM |
| ABM not available/configured | Method 2: Direct enrollment |
| Quick staging for deployment | Method 2: Direct enrollment |
| Devices from secondary market | Method 1: Add to ABM |
| Personal devices being converted | Method 1: Add to ABM |

### Decision Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    FALLBACK DECISION FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Is device in Apple Business Manager?                           │
│           │                                                      │
│     ┌─────┴─────┐                                               │
│    YES          NO                                              │
│     │            │                                               │
│     ▼            ▼                                               │
│  Use ABM/ADE   Is ABM available                                 │
│  (Standard)    for your org?                                    │
│                     │                                            │
│               ┌─────┴─────┐                                      │
│              YES          NO                                     │
│               │            │                                     │
│               ▼            ▼                                     │
│          Method 1:     Method 2:                                 │
│          Add to ABM    Direct Enrollment                         │
│          via Config    via Configurator                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Apple Configurator Overview

### What is Apple Configurator?

Apple Configurator 2 is a free Mac app that allows you to:
- Add devices to Apple Business Manager
- Supervise devices locally
- Install profiles and apps
- Prepare devices for deployment
- Enroll devices into MDM

### Capabilities Matrix

| Feature | ABM + ADE | Configurator → ABM | Configurator Direct |
|---------|-----------|-------------------|-------------------|
| Zero-touch enrollment | Yes | Yes (after add) | No |
| Supervised mode | Yes | Yes | Yes |
| Locked enrollment | Yes | Yes | Yes |
| Device-licensed VPP | Yes | Yes | Yes |
| No wipe required | Yes | No (wipe needed) | No (wipe needed) |
| Remote enrollment | Yes | Yes (after add) | No |
| Persistent supervision | Yes | Yes | Yes* |

*Supervision persists until factory reset

---

## Prerequisites

### Required Hardware

| Item | Details |
|------|---------|
| Mac computer | macOS 12.0 or later |
| USB cables | Lightning or USB-C (match iPad) |
| USB hub (optional) | For multiple devices |

### Required Software

| Software | Source |
|----------|--------|
| Apple Configurator 2 | Mac App Store (free) |
| Intune enrollment profile | Download from Intune |

### Required Access

| Access | Purpose |
|--------|---------|
| ABM Admin | To add devices to ABM (Method 1) |
| Intune Admin | For enrollment profiles |
| Local Mac admin | To run Configurator |

### Download Apple Configurator

1. Open **Mac App Store**
2. Search: "Apple Configurator 2"
3. Click **Get** / **Install**
4. Launch and sign in with Apple ID (can be personal)

---

## Method 1: Add to ABM via Configurator

### Overview

This method adds devices to Apple Business Manager, enabling full ADE capabilities. After adding, devices behave exactly like devices purchased through Apple.

### Advantages
- Full ADE functionality after adding
- Zero-touch enrollment for future setups
- Best long-term solution
- Devices remain in ABM permanently

### Disadvantages
- Requires device wipe during addition
- Requires physical access to device
- One-time setup per device

### Prerequisites for Method 1

1. **ABM must be configured** with MDM server for Intune
2. **ABM Admin account** with Device Manager or Admin role
3. **Devices not currently in ABM**
4. **Devices must be wiped** (will happen automatically)

### Step-by-Step: Add to ABM

**Step 1: Connect Device to Mac**

1. Connect iPad to Mac via USB cable
2. Open **Apple Configurator 2**
3. Device appears in the window
4. **Trust the computer** if prompted on iPad

**Step 2: Prepare Device for ABM**

1. Select the device in Configurator
2. Go to **Prepare** menu (or right-click > Prepare)
3. Configure as follows:

| Setting | Value |
|---------|-------|
| Configuration | Manual |
| Server | New server... |
| Enroll in organization's MDM | Yes |
| Supervise devices | Yes |
| Allow devices to pair | No (recommended) |
| Organization | Select or create |

**Step 3: Create MDM Server Entry**

When prompted to create server:

| Field | Value |
|-------|-------|
| Name | Microsoft Intune |
| Hostname | (leave blank - will use ABM assignment) |
| URL | (get from Intune enrollment profile) |

To get enrollment URL from Intune:
```
Intune > Devices > iOS enrollment > Enrollment program tokens > [Token] > Profiles > [Profile]
```
Copy the enrollment URL from profile.

**Step 4: Add to ABM**

1. In Prepare wizard, check **Add to Apple Business Manager**
2. Sign in with your **ABM Admin Apple ID**
3. Select your organization
4. Select the **MDM server** to assign
5. Click **Prepare**

**Step 5: Wait for Process**

- Device will be wiped
- Device will be added to ABM
- Device will be assigned to your MDM server
- This takes 5-15 minutes per device

**Step 6: Verify in ABM**

1. Go to **Apple Business Manager** (business.apple.com)
2. Navigate to **Devices**
3. Search for the device serial number
4. Verify:
   - Device appears
   - MDM Server shows "Microsoft Intune"

**Step 7: Complete Setup**

1. Disconnect device from Mac
2. Turn on device
3. Complete Setup Assistant
4. Device will auto-enroll into Intune
5. VPP apps will install automatically

---

## Method 2: Direct Enrollment via Configurator

### Overview

This method enrolls devices directly into Intune via Apple Configurator without adding to ABM. Use when ABM is not available or for temporary deployments.

### Advantages
- Works without ABM
- Faster initial setup
- Good for temporary/lab devices

### Disadvantages
- No zero-touch for future setups
- Must re-prepare if reset
- Requires physical access each time
- Cannot remotely re-supervise after wipe

### Prerequisites for Method 2

1. **Intune enrollment profile** downloaded
2. **Wi-Fi profile** (optional, for automatic network)
3. **Device must be wiped**

### Step-by-Step: Direct Enrollment

**Step 1: Create Intune Enrollment URL**

```
Intune Admin Center > Devices > iOS/iPadOS enrollment > Apple Configurator
```

1. Click **+ Create** under enrollment profile
2. Configure:

| Field | Value |
|-------|-------|
| Name | Configurator Enrollment - Supervised |
| Description | For devices enrolled via Apple Configurator |
| User affinity | Enroll without user affinity |
| Supervised | Yes |

3. Click **Create**
4. Note the **Enrollment URL**

**Step 2: Download Enrollment Profile**

1. Select the enrollment profile you created
2. Click **Export profile**
3. Save the `.mobileconfig` file

**Step 3: Prepare Device in Configurator**

1. Connect iPad to Mac
2. Open **Apple Configurator 2**
3. Select the device
4. Go to **Prepare** (or right-click > Prepare)

**Step 4: Configure Preparation Settings**

| Setting | Value |
|---------|-------|
| Configuration | Manual |
| Enroll in MDM server | Your downloaded profile |
| Supervise devices | Yes |
| Allow devices to pair | No |
| Organization | Create/select your org |

**Step 5: Add Wi-Fi Profile (Optional)**

To avoid manual Wi-Fi setup:

1. In Configurator, go to **File > New Profile**
2. Add **Wi-Fi** payload
3. Configure your corporate Wi-Fi
4. Save profile
5. Include in Prepare action

**Step 6: Run Prepare**

1. Click **Prepare**
2. Device will be wiped and configured
3. Wait for completion (5-10 minutes)

**Step 7: Complete Setup**

1. Disconnect from Mac
2. Turn on device
3. Connect to Wi-Fi (if not auto-configured)
4. Device enrolls into Intune
5. VPP apps push automatically

---

## Constraints and Limitations

### Apple Configurator Limitations

```
┌─────────────────────────────────────────────────────────────────┐
│                CONFIGURATOR CONSTRAINTS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PHYSICAL ACCESS REQUIRED                                       │
│  • Must connect device via USB cable                            │
│  • Cannot enroll remotely                                       │
│  • Each device requires hands-on preparation                    │
│                                                                  │
│  WIPE REQUIRED                                                  │
│  • Device data is erased during preparation                     │
│  • No way to supervise without wipe                             │
│  • User data must be backed up first                            │
│                                                                  │
│  MAC REQUIRED                                                   │
│  • Apple Configurator only runs on macOS                        │
│  • No Windows version available                                  │
│  • Need Mac for staging area                                    │
│                                                                  │
│  ONE DEVICE AT A TIME (USB)                                     │
│  • Practical limit ~30 devices per session                      │
│  • USB hub can help but has limits                              │
│  • Network-based preparation not available                      │
│                                                                  │
│  METHOD 2 SPECIFIC                                               │
│  • If device is factory reset, supervision is lost              │
│  • Must re-prepare device manually                              │
│  • Cannot remotely re-supervise                                 │
│                                                                  │
│  METHOD 1 SPECIFIC                                               │
│  • Device cannot already be in another org's ABM                │
│  • Requires ABM Admin access                                    │
│  • Device permanently added to your ABM                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### What CAN Be Automated

| Task | Can Automate? | How |
|------|---------------|-----|
| Wi-Fi configuration | Yes | Include Wi-Fi profile |
| MDM enrollment | Yes | Include enrollment profile |
| Skip Setup screens | Yes | Via enrollment profile |
| Install apps | Yes | Via VPP after enrollment |
| Apply restrictions | Yes | Via Intune config profiles |
| Create passcode | No | User must set or policy forces |

### What CANNOT Be Automated

| Task | Why Not |
|------|---------|
| USB connection | Physical action required |
| Initial power on | Physical action required |
| Apple ID sign-in | User action (unless VPP device licensed) |
| Wi-Fi password entry | Unless pre-configured via profile |

---

## Step-by-Step Procedures

### Procedure: Batch Prepare Multiple Devices

**For staging multiple devices efficiently:**

**Equipment:**
- Mac with Apple Configurator 2
- Powered USB hub (16+ ports recommended)
- Multiple USB cables

**Process:**

1. **Create Blueprints (Templates):**
   ```
   Apple Configurator > Blueprints > + New Blueprint
   ```
   - Configure all settings once
   - Save as reusable template

2. **Connect Multiple Devices:**
   - Use USB hub
   - Connect up to ~30 devices
   - All appear in Configurator

3. **Select All Devices:**
   - Cmd+A to select all
   - Or drag-select

4. **Apply Blueprint:**
   - Right-click > Apply Blueprint
   - Select your saved blueprint
   - Start preparation

5. **Monitor Progress:**
   - Watch status indicators
   - Failed devices show red
   - Complete devices show green

6. **Troubleshoot Failures:**
   - Individual devices may fail
   - Try again or check USB connection
   - Replace faulty cables

### Procedure: Create Wi-Fi Profile

**For automatic Wi-Fi connection after setup:**

1. **Open Apple Configurator 2**

2. **Create New Profile:**
   ```
   File > New Profile
   ```

3. **General Payload:**
   - Name: Corporate Wi-Fi
   - Identifier: com.company.wifi
   - Organization: Your Company

4. **Wi-Fi Payload:**
   - Click **Wi-Fi** in sidebar
   - Click **Configure**

   | Setting | Value |
   |---------|-------|
   | SSID | Your-Network-Name |
   | Hidden Network | Check if hidden |
   | Auto Join | Yes |
   | Security Type | WPA2/WPA3 Enterprise or Personal |
   | Password | [If WPA Personal] |
   | Username/Password | [If Enterprise] |

5. **Save Profile:**
   - File > Save
   - Save as `wifi-config.mobileconfig`

6. **Include in Preparation:**
   - When preparing devices, add this profile
   - Devices will auto-connect to Wi-Fi

### Procedure: Export Enrollment URL from Intune

**To get the enrollment URL for Configurator:**

1. **Navigate to:**
   ```
   Intune Admin Center > Devices > iOS/iPadOS > iOS/iPadOS enrollment > Apple Configurator
   ```

2. **Create Enrollment Profile (if needed):**
   - Click **+ Create**
   - Name: Configurator Supervised
   - User affinity: Without user affinity (for shared)
   - Supervised: Yes
   - Create

3. **Get Enrollment URL:**
   - Click on your profile
   - Copy the **Enrollment URL**
   - Looks like: `https://manage.microsoft.com/EnrollmentServer/...`

4. **Or Export Profile:**
   - Click **Export profile**
   - Downloads `.mobileconfig` file
   - Use this file in Configurator

---

## Troubleshooting Apple Configurator

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Device not detected | USB issue | Try different cable/port |
| Prepare fails | Activation lock | Remove from previous Apple ID |
| Prepare hangs | Network issue | Check Mac's internet |
| "Not eligible for ABM" | Already in another ABM | Contact previous owner |
| Wi-Fi won't connect | Wrong credentials | Verify Wi-Fi profile settings |
| Apps don't install | VPP not configured | Configure in Intune after enrollment |

### Device Shows "Activation Lock"

**Before preparation, activation lock must be removed:**

1. **If you have the Apple ID:**
   - On device: Settings > [Name] > Sign Out
   - Or on device: Settings > General > Reset > Erase All Content and Settings
   - Enter Apple ID password when prompted

2. **If previous owner:**
   - Contact them to remove from Find My
   - They can do this remotely at icloud.com/find

3. **If organizationally owned:**
   - Use ABM > Devices > Activation Lock
   - Bypass with organization credentials

---

## Summary: Method Comparison

| Factor | Method 1: Add to ABM | Method 2: Direct Enrollment |
|--------|---------------------|---------------------------|
| **ABM Required** | Yes | No |
| **Zero-touch after setup** | Yes | No |
| **Survives factory reset** | Yes (stays in ABM) | No (loses supervision) |
| **Best for** | Long-term corporate devices | Temp/lab devices |
| **Complexity** | Higher initial setup | Lower initial setup |
| **Scalability** | Excellent | Limited |
| **VPP Apps** | Full support | Full support |
| **Recommended** | Yes (when ABM available) | Fallback only |

---

## Next Steps

- For Intune configuration, see [03-INTUNE-CONFIGURATION.md](03-INTUNE-CONFIGURATION.md)
- For field remediation, see [05-FIELD-REMEDIATION.md](05-FIELD-REMEDIATION.md)
- For complete runbook, see [06-DEPLOYMENT-RUNBOOK.md](06-DEPLOYMENT-RUNBOOK.md)

---

*SBS Federal IT Department*
