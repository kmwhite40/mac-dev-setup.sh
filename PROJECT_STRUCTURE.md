# Project Structure

Visual guide to all files and their purposes.

## Directory Structure

```
mac-dev-setup.sh/
│
├── mac-dev-setup.sh          [8.6K]  ⭐ Main executable script
│
├── INDEX.md                  [7.1K]  📋 Documentation index & quick reference
├── QUICK_START.md            [2.6K]  🚀 5-minute quick start guide
├── README.md                 [11K]   📖 Complete documentation
├── OPERATIONS.md             [17K]   📊 Technical execution flow
├── TROUBLESHOOTING.md        [13K]   🔧 Problem solving guide
└── PROJECT_STRUCTURE.md      [this]  🗂️  Project overview

Total: ~59K (6 files)
```

---

## File Relationships

```
┌─────────────────────────────────────────────────────────┐
│                    INDEX.md                             │
│            (Start here - Navigation hub)                │
└─────────────────┬───────────────────────────────────────┘
                  │
     ┌────────────┼────────────┬────────────┐
     │            │            │            │
     ▼            ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│ QUICK_  │  │ README  │  │ OPERA-  │  │ TROUBLE │
│ START   │  │   .md   │  │ TIONS   │  │ SHOOTING│
│  .md    │  │         │  │  .md    │  │   .md   │
└────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
     │            │            │            │
     │            │            │            │
     └────────────┴────────────┴────────────┘
                  │
                  ▼
        ┌──────────────────┐
        │  mac-dev-setup   │
        │      .sh         │
        │  (The Script)    │
        └──────────────────┘
```

---

## File Purposes

### 🎯 [mac-dev-setup.sh](mac-dev-setup.sh) - THE SCRIPT
**Size:** 8.6K | **Type:** Executable Bash Script

**What it does:**
- Installs Homebrew
- Updates macOS and packages every 4 days
- Installs 14 GUI apps + 21 CLI tools
- Creates desktop shortcuts
- Logs all operations

**When to edit:**
- Add/remove applications
- Change update frequency
- Customize desktop shortcuts
- Modify installation logic

**When to run:**
- First time setup
- Regular maintenance
- After adding new apps to script
- When forced update is needed

---

### 📋 [INDEX.md](INDEX.md) - NAVIGATION HUB
**Size:** 7.1K | **Type:** Markdown Documentation

**What it does:**
- Central navigation point
- Quick command reference
- File overview
- Typical workflow guide

**When to read:**
- When you need to find information
- As a quick reference
- To understand project structure

**Cross-references:**
- Links to all other documentation
- Quick start guide
- Troubleshooting guide

---

### 🚀 [QUICK_START.md](QUICK_START.md) - 5 MINUTE GUIDE
**Size:** 2.6K | **Type:** Markdown Documentation

**What it does:**
- Minimal setup instructions
- Essential commands only
- Post-installation steps
- Quick troubleshooting

**When to read:**
- First time users (START HERE)
- Need quick reminder
- Just want to get running

**Target audience:**
- Beginners
- Users who want minimal reading
- Quick reference needs

---

### 📖 [README.md](README.md) - COMPLETE GUIDE
**Size:** 11K | **Type:** Markdown Documentation

**What it does:**
- Full feature documentation
- Complete installation list
- Configuration options
- Advanced usage
- FAQ section
- Automation setup

**When to read:**
- Want to understand all features
- Need to customize script
- Setting up automation
- Looking for specific feature

**Covers:**
- Prerequisites
- Installation
- Configuration
- Post-installation
- Advanced usage
- Automation
- Security
- Maintenance

---

### 📊 [OPERATIONS.md](OPERATIONS.md) - TECHNICAL FLOW
**Size:** 17K | **Type:** Markdown Documentation

**What it does:**
- Detailed execution flowchart
- Phase-by-phase breakdown
- Performance metrics
- File system changes
- Monitoring procedures
- Debug information

**When to read:**
- Want to understand internals
- Troubleshooting complex issues
- Performance optimization
- System administration
- Contributing to project

**Includes:**
- ASCII flowchart
- 10 execution phases
- Error handling details
- Performance characteristics
- Exit codes

---

### 🔧 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - PROBLEM SOLVER
**Size:** 13K | **Type:** Markdown Documentation

**What it does:**
- Common problems & solutions
- Step-by-step fixes
- Recovery procedures
- Log analysis
- Diagnostic commands

**When to read:**
- Encountering errors
- Script not working as expected
- Need to recover from failure
- Performance issues

**Organized by:**
- Installation issues
- Permission problems
- Homebrew issues
- Package failures
- System updates
- Desktop shortcuts
- Network problems
- Performance issues
- Recovery procedures

---

## Reading Paths

### Path 1: Quick Start (Recommended for First-Time Users)
```
1. INDEX.md           (2 min)  - Overview
2. QUICK_START.md     (5 min)  - Setup
3. Run script         (varies) - Installation
4. TROUBLESHOOTING.md (if needed)
```

### Path 2: Comprehensive Understanding
```
1. INDEX.md           (2 min)  - Overview
2. README.md          (20 min) - Full docs
3. OPERATIONS.md      (15 min) - Technical details
4. Run script         (varies) - Installation
5. TROUBLESHOOTING.md (reference)
```

### Path 3: Technical Deep Dive
```
1. README.md          (20 min) - Features
2. OPERATIONS.md      (15 min) - Flow
3. mac-dev-setup.sh   (10 min) - Code review
4. TROUBLESHOOTING.md (30 min) - Edge cases
5. Customize and run
```

### Path 4: Problem Solving
```
1. INDEX.md                    - Quick commands
2. Check ~/.mac-dev-setup.log  - Error logs
3. TROUBLESHOOTING.md          - Find solution
4. OPERATIONS.md               - Understand flow
5. Fix and re-run
```

---

## File Dependencies

```
mac-dev-setup.sh
    ↓ creates
    ├── ~/.mac-dev-setup.log         (installation log)
    ├── ~/.mac-dev-setup-last-update (timestamp)
    └── ~/Desktop/*                   (shortcuts)
    ↓ installs
    ├── /Applications/*.app           (GUI apps)
    └── /opt/homebrew/bin/*           (CLI tools)
```

---

## Documentation Map by Use Case

### "I just want to install everything"
→ [QUICK_START.md](QUICK_START.md)

### "I want to customize what gets installed"
→ [README.md](README.md) - Configuration section
→ [mac-dev-setup.sh](mac-dev-setup.sh) - Edit lines 172-206

### "Something went wrong"
→ [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
→ Check `~/.mac-dev-setup.log`

### "How does this work internally?"
→ [OPERATIONS.md](OPERATIONS.md)

### "I want to automate this"
→ [README.md](README.md) - Automation section

### "What commands do I need?"
→ [INDEX.md](INDEX.md) - Quick Reference section

### "How do I modify the update schedule?"
→ [README.md](README.md) - Configuration
→ [mac-dev-setup.sh](mac-dev-setup.sh) - Line 14

---

## File Sizes & Load Times

| File | Size | Read Time | Purpose |
|------|------|-----------|---------|
| INDEX.md | 7.1K | 2-3 min | Navigation |
| QUICK_START.md | 2.6K | 5 min | Quick setup |
| README.md | 11K | 20 min | Full docs |
| OPERATIONS.md | 17K | 15 min | Technical |
| TROUBLESHOOTING.md | 13K | 30 min* | Reference |
| mac-dev-setup.sh | 8.6K | 10 min | Script code |

*Read as needed, not cover-to-cover

---

## Runtime Files (Created by Script)

### Log File
```
~/.mac-dev-setup.log
- Size: Grows over time (1-10 MB typical)
- Contains: Timestamped installation logs
- Rotation: Manual cleanup needed
- Format: Color-coded with emojis
```

### Timestamp File
```
~/.mac-dev-setup-last-update
- Size: < 1 KB
- Contains: Unix timestamp
- Purpose: Track 4-day update cycle
- Format: Single line, epoch seconds
```

### Desktop Shortcuts
```
~/Desktop/[App Name]
- Size: 0 bytes (symlinks)
- Points to: /Applications/[App Name].app
- Count: 8 shortcuts created
- Removable: Yes, safely deleted
```

---

## Quick Access Commands

### View Documentation
```bash
# Index
cat INDEX.md | less

# Quick start
cat QUICK_START.md

# Full README
cat README.md | less

# Operations guide
cat OPERATIONS.md | less

# Troubleshooting
cat TROUBLESHOOTING.md | less
```

### Search Documentation
```bash
# Find topic across all docs
grep -i "topic" *.md

# Find specific error
grep -i "permission denied" TROUBLESHOOTING.md

# Find command examples
grep -E "^\`\`\`bash" README.md -A 5
```

---

## Maintenance

### Keep Documentation Updated

When you modify [mac-dev-setup.sh](mac-dev-setup.sh):

1. Update [README.md](README.md) if features change
2. Update [OPERATIONS.md](OPERATIONS.md) if flow changes
3. Update [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if you find new issues
4. Update [QUICK_START.md](QUICK_START.md) if setup changes
5. Update [INDEX.md](INDEX.md) if structure changes

---

## Version Control

All files should be versioned together:

```bash
git add .
git commit -m "Update script and documentation"
git push
```

---

**Last Updated:** 2025-12-17
**Project Version:** 2.0
**Documentation Version:** 1.0
