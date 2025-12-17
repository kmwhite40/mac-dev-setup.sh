# Step-by-Step Guide: Upload to Intune Company Portal

This guide walks you through uploading your Mac Dev Setup package to Microsoft Intune and making it available in Company Portal.

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Intune Administrator Access**
  - Sign in at: https://intune.microsoft.com
  - Required role: Intune Administrator or Global Administrator

- [ ] **Package Built**
  - MacDevSetup-2.0.0.pkg file ready
  - Converted to .intunemac format (instructions below)

- [ ] **Microsoft Tools**
  - Download IntuneAppUtil from: https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac

---

## Part 1: Build and Prepare Package (15 minutes)

### Step 1: Customize Company Settings

```bash
cd intune/

# Edit company configuration
vim install.sh

# Update these lines (around line 168-171):
COMPANY_NAME="Your Company Name"
IT_SUPPORT_EMAIL="itsupport@yourcompany.com"
UPDATE_INTERVAL_DAYS=4
```

**What to change:**
- `COMPANY_NAME`: Your organization name (appears in notifications)
- `IT_SUPPORT_EMAIL`: Your IT help desk email
- `UPDATE_INTERVAL_DAYS`: How often to force updates (4 = every 4 days)

### Step 2: Build the Package

```bash
# Make sure you're in the intune/ directory
cd /path/to/mac-dev-setup.sh/intune/

# Run the build script
./build-package.sh
```

**Expected output:**
```
=========================================
Mac Dev Setup - Package Builder
=========================================
Cleaning previous builds...
Creating build structure...
Copying files to package...
  ✓ Copied README.md
  ✓ Copied QUICK_START.md
  ...
Building component package...
  ✓ Component package created
Building distribution package...
  ✓ Distribution package created
=========================================
Package Build Complete!
=========================================
Package Name: MacDevSetup-2.0.0.pkg
Package Size: 59K
```

**Result:** You now have `MacDevSetup-2.0.0.pkg`

### Step 3: Download IntuneAppUtil (One-time setup)

```bash
# Download the tool
curl -L -o IntuneAppUtil.zip https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac/releases/latest/download/IntuneAppUtil.zip

# Extract
unzip IntuneAppUtil.zip

# Make executable
chmod +x IntuneAppUtil
```

### Step 4: Convert to .intunemac Format

```bash
# Convert the package
./IntuneAppUtil \
  -c MacDevSetup-2.0.0.pkg \
  -o . \
  -i com.company.macdevsetup \
  -n 2.0.0

# Verify the file was created
ls -lh MacDevSetup-2.0.0.intunemac
```

**Result:** You now have `MacDevSetup-2.0.0.intunemac` (ready for Intune)

---

## Part 2: Upload to Intune (30 minutes)

### Step 5: Sign In to Intune Admin Center

1. **Open browser** and go to: https://intune.microsoft.com
2. **Sign in** with your admin credentials
3. **Verify access** - You should see the Intune dashboard

### Step 6: Navigate to Apps Section

1. In the left sidebar, click **Apps**
2. Click **macOS**
3. Click **+ Add** button at the top

![Intune Apps Menu](https://via.placeholder.com/800x400?text=Intune+%3E+Apps+%3E+macOS+%3E+Add)

### Step 7: Select App Type

1. In the "Select app type" panel:
   - Choose **Line-of-business app**
   - Click **Select** button at the bottom

### Step 8: Upload App Package File

1. Click **Select app package file**
2. Click the folder icon to browse
3. Navigate to your `MacDevSetup-2.0.0.intunemac` file
4. Select the file and click **Open**
5. Wait for upload to complete (shows green checkmark)
6. Click **OK**

**Upload time:** 1-2 minutes depending on connection

### Step 9: Configure App Information

Fill in these fields:

**Required fields:**

| Field | Value |
|-------|-------|
| **Name** | `Mac Dev Setup` |
| **Description** | `Automated development environment setup with Docker, VS Code, Cursor, IntelliJ IDEA, database tools, and cloud CLIs. Installs 14 GUI applications and 21 command-line tools. Automatically updates macOS and packages every 4 days.` |
| **Publisher** | `Your Company IT Department` |

**Optional but recommended:**

| Field | Value |
|-------|-------|
| **Category** | Select: `Productivity` |
| **Show this as a featured app** | `No` |
| **Information URL** | Your internal documentation URL (optional) |
| **Privacy URL** | Your privacy policy URL (optional) |
| **Developer** | `Your Company` |
| **Owner** | `IT Department` |
| **Notes** | `Requires ~30GB disk space and internet connection. User must run 'mac-dev-setup' command after installation.` |

**App icon (optional):**
- Click **Select image**
- Upload a 512x512 PNG icon
- Recommended: Create icon with terminal/development tools imagery

Click **Next** when done.

### Step 10: Configure Program Settings

On the "Program" page, configure:

**Install command:**
```
/bin/bash /tmp/macdevsetup/install.sh
```

**Uninstall command:**
```
/bin/bash /Library/Application\ Support/MacDevSetup/uninstall.sh
```

**Additional settings:**

| Setting | Value |
|---------|-------|
| **Ignore app version** | `No` |
| **Install behavior** | `System` (not User) |
| **Device restart behavior** | `App install may force a device restart` |

**Return codes:**

| Return code | Code type |
|-------------|-----------|
| 0 | Success |
| 1 | Failed |

Click **Next**.

### Step 11: Configure Requirements

Set minimum system requirements:

| Requirement | Value |
|-------------|-------|
| **Operating system** | `macOS 10.15 (Catalina) or later` |
| **Architecture** | Select both: `x64` and `ARM64` |
| **Disk space required (MB)** | `30000` (30GB) |
| **Physical memory required (MB)** | `4096` (4GB recommended) |
| **Number of processors required** | `2` (recommended) |
| **CPU speed required (MHz)** | Leave blank |

Click **Next**.

### Step 12: Configure Detection Rules

**Choose detection method:** Custom script (Recommended)

1. Click **Add** under Detection rules
2. Select **Rule type:** `Use custom detection script`
3. Click **Select file**
4. Upload your `detection.sh` file from the intune/ folder
5. **Script output:** `String`
6. Click **OK**

**Alternative method:** File-based detection
- **Rule type:** File
- **Path:** `/Library/Application Support/MacDevSetup`
- **File or folder:** `version.txt`
- **Detection method:** `File or folder exists`

Click **Next**.

### Step 13: Configure Dependencies (Optional)

If you have dependency requirements, add them here.

For this app: **No dependencies required**

Click **Next**.

### Step 14: Configure Supersedence (Optional)

If replacing an older version, configure here.

For new installation: **No supersedence**

Click **Next**.

### Step 15: Configure Assignments

Now decide how to deploy the app:

#### Option A: Make Available in Company Portal (Recommended for initial deployment)

1. Under **Available for enrolled devices**, click **+ Add group**
2. **Select groups:**
   - Search for your target group (e.g., "All macOS Users")
   - Or create a pilot group first: "Mac Dev Setup - Pilot"
3. Click **Select**
4. **End user notifications:** Select `Show all toast notifications`
5. Click **OK**

#### Option B: Required Installation (Force install)

1. Under **Required**, click **+ Add group**
2. Select your target group
3. **Installation deadline:** Set date/time (optional)
4. **End user notifications:** Select `Show all toast notifications`
5. Click **OK**

**Recommendation:** Start with "Available" for a pilot group, then expand.

Click **Next**.

### Step 16: Review and Create

1. **Review** all settings on the summary page
2. Verify:
   - Name: Mac Dev Setup
   - Install command is correct
   - Detection rule uploaded
   - Groups assigned
3. Click **Create**

**Creation time:** 1-2 minutes

---

## Part 3: Verify Deployment (10 minutes)

### Step 17: Check App Status

1. Go to **Apps → macOS → Mac Dev Setup**
2. Click on the app name
3. You should see:
   - **Overview** tab with app details
   - **Properties** tab with settings
   - **Device install status** (will populate as users install)
   - **User install status**

### Step 18: Monitor Initial Deployment

1. Click **Device install status**
2. View columns:
   - **Device name**
   - **User name**
   - **Status** (Installed, Failed, In Progress, Not Applicable)
   - **Status details**
   - **Last check-in**

### Step 19: Test on Pilot Device

**On a test Mac:**

1. Open **Company Portal** app
2. Click **Apps** tab
3. Search for "Mac Dev Setup"
4. Click on the app
5. Click **Install**
6. Wait for installation (1-2 minutes)
7. Should see "Installed" status
8. Open **Terminal**
9. Run: `mac-dev-setup`
10. Verify script runs successfully

---

## Part 4: User Communication (5 minutes)

### Step 20: Notify Users

Send this communication to users:

---

**Email Template:**

```
Subject: New Tool Available: Mac Dev Setup

Hello,

A new tool is now available in Company Portal to help you set up your Mac for development work.

WHAT IT DOES:
Mac Dev Setup automatically installs and configures development tools including:
- Docker, VS Code, Cursor, IntelliJ IDEA
- Git, GitHub CLI, GitLab CLI
- Kubernetes tools (kubectl, helm)
- Cloud CLIs (AWS, Azure, Google Cloud)
- And many more...

HOW TO INSTALL:
1. Open Company Portal on your Mac
2. Search for "Mac Dev Setup"
3. Click Install (takes 1-2 minutes)
4. Open Terminal
5. Run: mac-dev-setup
6. Follow the on-screen instructions (45-90 minutes first time)

WHAT TO EXPECT:
- Desktop shortcuts will be created for your apps
- All tools will auto-update every 4 days
- Everything is logged for troubleshooting

NEED HELP?
- Documentation: /Library/Application Support/MacDevSetup/
- IT Support: itsupport@yourcompany.com
- Quick Guide: Run 'cat /Library/Application\ Support/MacDevSetup/QUICK_START.md'

Questions? Contact the IT Help Desk.

Thanks,
IT Department
```

---

## Monitoring and Management

### View Installation Reports

**In Intune Console:**

1. **Apps → Mac Dev Setup → Device install status**
   - See all installations
   - Filter by status (Installed, Failed, Pending)
   - Export to Excel

2. **Apps → Mac Dev Setup → Overview**
   - Installation summary chart
   - Success/failure rates
   - Trend over time

### Check Individual Device

1. **Devices → macOS → All macOS devices**
2. Select a device
3. Click **Managed apps**
4. Find "Mac Dev Setup"
5. View:
   - Installation status
   - Installation date
   - App version
   - Errors (if any)

### Review Error Logs

**For failed installations:**

1. In Intune, click on failed device
2. View error message
3. Common errors:
   - Not enough disk space → User needs to free space
   - Network timeout → Retry installation
   - Permission denied → Contact IT

**On the device:**
```bash
# View installation logs
cat /Library/Logs/MacDevSetup/intune-install.log

# View pre-install checks
cat /Library/Logs/MacDevSetup/preinstall.log

# View user execution logs
cat ~/.mac-dev-setup.log
```

---

## Troubleshooting Common Issues

### Issue 1: Upload Fails

**Problem:** .intunemac file won't upload

**Solutions:**
- Check file size (should be ~59KB)
- Verify .intunemac extension
- Try different browser (Chrome recommended)
- Check internet connection
- Re-run IntuneAppUtil conversion

### Issue 2: Detection Not Working

**Problem:** Intune shows "Not detected" even though installed

**Solutions:**
```bash
# On device, test detection manually
cd /Library/Application\ Support/MacDevSetup/
bash -x detection.sh
echo $?  # Should output 0

# Check version file exists
cat version.txt

# If missing, reinstall
sudo rm -rf /Library/Application\ Support/MacDevSetup/
# Reinstall from Company Portal
```

### Issue 3: Installation Fails

**Problem:** Installation fails on devices

**Solutions:**
1. Check preinstall log:
   ```bash
   cat /Library/Logs/MacDevSetup/preinstall.log
   ```

2. Common causes:
   - **Insufficient disk space:** User needs 30GB free
   - **macOS too old:** Requires 10.15+
   - **No internet:** Installation requires internet

3. Force retry:
   - In Intune, find the device
   - Click "Sync" to retry installation

### Issue 4: Users Can't Find App in Company Portal

**Solutions:**
- Verify group assignment in Intune
- Check user is in assigned group
- Have user sync Company Portal:
  - Open Company Portal
  - Click account icon (top right)
  - Click "Sync"
- Wait 8 hours for policy refresh (or force sync)

### Issue 5: Command Not Found After Install

**Problem:** User runs `mac-dev-setup` but gets "command not found"

**Solutions:**
```bash
# Check if wrapper exists
ls -la /usr/local/bin/mac-dev-setup

# If missing, reinstall or create manually
sudo ln -s "/Library/Application Support/MacDevSetup/mac-dev-setup.sh" /usr/local/bin/mac-dev-setup
sudo chmod +x /usr/local/bin/mac-dev-setup

# Add to PATH if needed
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## Updating the Package

### When to Update

- Adding/removing applications
- Changing update frequency
- Bug fixes
- Feature enhancements

### How to Update

1. **Modify scripts** in your local repository
2. **Update version** in `package-info.json`:
   ```json
   "version": "2.1.0"
   ```
3. **Update MIN_VERSION** in `detection.sh`:
   ```bash
   MIN_VERSION="2.1"
   ```
4. **Rebuild package:**
   ```bash
   cd intune/
   ./build-package.sh
   ```
5. **Convert to .intunemac:**
   ```bash
   ./IntuneAppUtil -c MacDevSetup-2.1.0.pkg -o . -i com.company.macdevsetup -n 2.1.0
   ```
6. **Upload to Intune:**
   - Apps → Mac Dev Setup → Properties
   - Under "App information", click Edit
   - Upload new .intunemac file
   - Save

### Version Update Detection

Intune will automatically detect the version change and:
- Mark existing installations as "Update available"
- Offer update to users
- Or force update (if required assignment)

---

## Best Practices

### 1. Pilot Before Production
- ✅ Create "Mac Dev Setup - Pilot" group (5-10 users)
- ✅ Assign app as "Available"
- ✅ Monitor for 1 week
- ✅ Collect feedback
- ✅ Fix any issues
- ✅ Then expand to production

### 2. Monitor Regularly
- ✅ Check Device install status weekly
- ✅ Review failed installations
- ✅ Track success rate (target >95%)
- ✅ Monitor help desk tickets

### 3. Keep Documentation Updated
- ✅ Update internal wiki/knowledge base
- ✅ Create screenshots for help desk
- ✅ Document common issues
- ✅ Share tips with users

### 4. User Training
- ✅ Send email announcements
- ✅ Create quick video demo (2-3 minutes)
- ✅ Host training sessions (optional)
- ✅ Update onboarding docs

### 5. Maintenance Schedule
- ✅ Monthly: Review installation reports
- ✅ Quarterly: Update application list
- ✅ Annually: Review and optimize

---

## Quick Reference Card

### For IT Admins

```bash
# Build package
cd intune/ && ./build-package.sh

# Convert for Intune
./IntuneAppUtil -c MacDevSetup-2.0.0.pkg -o . -i com.company.macdevsetup -n 2.0.0

# Intune upload
https://intune.microsoft.com → Apps → macOS → Add → LOB app

# Monitor
https://intune.microsoft.com → Apps → Mac Dev Setup → Device install status

# Check logs on device
cat /Library/Logs/MacDevSetup/intune-install.log
```

### For End Users

```bash
# Install
Company Portal → Apps → Mac Dev Setup → Install

# Run setup
mac-dev-setup

# View logs
tail -f ~/.mac-dev-setup.log

# View docs
open "/Library/Application Support/MacDevSetup/README.md"
```

---

## Success Checklist

Before marking deployment as complete:

- [ ] Package built successfully
- [ ] Uploaded to Intune
- [ ] Detection rule configured
- [ ] Assigned to pilot group
- [ ] Tested on at least 3 devices
- [ ] Success rate >90% in pilot
- [ ] Documentation distributed
- [ ] Help desk trained
- [ ] Monitoring dashboard set up
- [ ] User communication sent
- [ ] Expanded to production groups

---

## Support Resources

### Internal
- **Intune Admin Center:** https://intune.microsoft.com
- **Help Desk:** itsupport@yourcompany.com
- **Documentation:** /Library/Application Support/MacDevSetup/

### External
- **Microsoft Intune Docs:** https://docs.microsoft.com/mem/intune/
- **IntuneAppUtil:** https://github.com/msintuneappsdk/intune-app-wrapping-tool-mac
- **Homebrew:** https://docs.brew.sh

### Project Documentation
- **Intune Quick Start:** [INTUNE-QUICK-START.md](INTUNE-QUICK-START.md)
- **Deployment Checklist:** [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)
- **Full Intune Guide:** [README-INTUNE.md](README-INTUNE.md)

---

**Congratulations!** Your Mac Dev Setup is now deployed to Intune Company Portal! 🎉

Users can now install and configure their development environment with just a few clicks.

**Last Updated:** 2025-12-17
