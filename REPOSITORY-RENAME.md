# Repository Rename Instructions

The repository has been restructured and is now ready to be renamed from **mac-dev-setup.sh** to **DevHelpDeskTools**.

## Manual Steps Required on GitHub

### 1. Rename Repository on GitHub

1. Go to: https://github.com/kmwhite40/mac-dev-setup.sh
2. Click **Settings** (top right)
3. Scroll down to "Repository name" section
4. Change name from `mac-dev-setup.sh` to `DevHelpDeskTools`
5. Click **Rename**

### 2. Update Local Git Remote

After renaming on GitHub, update your local repository:

```bash
# Update remote URL to new repository name
git remote set-url origin git@github.com:kmwhite40/DevHelpDeskTools.git

# Verify the change
git remote -v
```

Expected output:
```
origin  git@github.com:kmwhite40/DevHelpDeskTools.git (fetch)
origin  git@github.com:kmwhite40/DevHelpDeskTools.git (push)
```

### 3. Update Documentation References (Optional)

If needed, update any hardcoded references to the old repository name in:
- README.md (already updated)
- docs/INDEX.md
- Other documentation files

### 4. Verify Repository Access

```bash
# Test that you can still pull/push
git pull
git push
```

## Why This Name?

**DevHelpDeskTools** better reflects the repository's purpose:
- **Dev** - Development environment setup
- **HelpDesk** - IT help desk automation
- **Tools** - Collection of utilities

The new name also reflects that this is now a **cross-platform** repository supporting both macOS and Windows.

## Repository Structure After Rename

```
DevHelpDeskTools/
├── packages/
│   ├── macos/          # macOS packages
│   │   ├── mac-dev-setup/
│   │   ├── compliance-scanner/
│   │   └── m365-installer/
│   └── windows/        # Windows packages
│       ├── windows-dev-setup/
│       ├── windows-compliance-scanner/
│       └── windows-m365-installer/
└── docs/               # General documentation
```

## Packages Included

**macOS (3 packages):**
1. Mac Dev Setup - Development environment automation
2. NIST 800-53 Compliance Scanner - Security compliance checking
3. Microsoft 365 Installer - M365 suite deployment

**Windows (3 packages):**
1. Windows Dev Setup - Development environment automation
2. Windows Compliance Scanner - Security compliance checking
3. Windows M365 Installer - M365 suite deployment

---

**Total:** 6 packages supporting 2 platforms with 70+ applications managed

**Company:** SBS Federal
**Contact:** it@sbsfederal.com
**Last Updated:** 2025-12-17
