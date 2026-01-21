# iPad Intune Deployment Guide

## SBS Federal - Enterprise iPad Management

**Version:** 1.0.0
**Last Updated:** 2025-01-21
**Contact:** it@sbsfederal.com

---

## Overview

This package provides comprehensive documentation for deploying iPads with Microsoft Intune, specifically addressing the common issue of **Company Portal and App Store being greyed out**.

### Target Configuration
| Component | Value |
|-----------|-------|
| MDM | Microsoft Intune |
| Enrollment | Apple Business Manager (ABM) + Automated Device Enrollment (ADE) |
| Device Mode | Supervised |
| App Licensing | VPP Device Licensing |
| Required Apps | Company Portal, Google Chrome |

---

## Quick Start

### For New Deployments
1. Complete pre-checks: [06-DEPLOYMENT-RUNBOOK.md](docs/06-DEPLOYMENT-RUNBOOK.md#pre-checks)
2. Configure ABM/ADE: [02-ABM-ADE-DEPLOYMENT.md](docs/02-ABM-ADE-DEPLOYMENT.md)
3. Configure Intune apps: [03-INTUNE-CONFIGURATION.md](docs/03-INTUNE-CONFIGURATION.md)
4. Enroll devices: [06-DEPLOYMENT-RUNBOOK.md](docs/06-DEPLOYMENT-RUNBOOK.md#new-device-enrollment)

### For Problem Devices
1. Diagnose issue: [01-DIAGNOSIS-GUIDE.md](docs/01-DIAGNOSIS-GUIDE.md)
2. Apply remediation: [05-FIELD-REMEDIATION.md](docs/05-FIELD-REMEDIATION.md)
3. Verify fix: [06-DEPLOYMENT-RUNBOOK.md](docs/06-DEPLOYMENT-RUNBOOK.md#verification-steps)

---

## Documentation Index

| Document | Description |
|----------|-------------|
| [01-DIAGNOSIS-GUIDE.md](docs/01-DIAGNOSIS-GUIDE.md) | Diagnose why App Store/Company Portal is greyed out |
| [02-ABM-ADE-DEPLOYMENT.md](docs/02-ABM-ADE-DEPLOYMENT.md) | Gold standard deployment with ABM + ADE |
| [03-INTUNE-CONFIGURATION.md](docs/03-INTUNE-CONFIGURATION.md) | Step-by-step Intune configuration |
| [04-APPLE-CONFIGURATOR-FALLBACK.md](docs/04-APPLE-CONFIGURATOR-FALLBACK.md) | Fallback when ABM/ADE unavailable |
| [05-FIELD-REMEDIATION.md](docs/05-FIELD-REMEDIATION.md) | Fix devices already in the field |
| [06-DEPLOYMENT-RUNBOOK.md](docs/06-DEPLOYMENT-RUNBOOK.md) | Complete deployment runbook |

---

## Common Causes: Greyed Out Apps

| Cause | Likelihood | Solution |
|-------|------------|----------|
| Configuration profile blocking App Store | HIGH | Modify profile in Intune |
| Screen Time restrictions | MEDIUM-HIGH | Disable via Intune profile |
| Device not supervised | MEDIUM | Re-enroll via ADE |
| VPP user licensing (no Apple ID) | MEDIUM | Switch to device licensing |
| Conflicting MDM enrollment | MEDIUM | Remove old MDM, re-enroll |
| VPP token expired | LOW-MEDIUM | Renew token in ABM + Intune |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐                    ┌──────────────┐           │
│  │    Apple     │  ──── Token ────▶  │   Microsoft  │           │
│  │   Business   │                    │    Intune    │           │
│  │   Manager    │  ◀─── Sync ─────   │              │           │
│  └──────────────┘                    └──────────────┘           │
│         │                                   │                    │
│         │ Device                            │ Profiles           │
│         │ Assignment                        │ & Apps             │
│         │                                   │                    │
│         ▼                                   ▼                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                         iPad                             │    │
│  │  ┌─────────────────┐    ┌─────────────────┐             │    │
│  │  │  Supervised     │    │  VPP Apps       │             │    │
│  │  │  Enrollment     │    │  (Device Lic.)  │             │    │
│  │  └─────────────────┘    └─────────────────┘             │    │
│  │         │                       │                        │    │
│  │         ▼                       ▼                        │    │
│  │  ┌─────────────────────────────────────────────────┐    │    │
│  │  │  Company Portal  │  Chrome  │  Other Apps       │    │    │
│  │  └─────────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required Accounts
- Apple Business Manager admin access
- Microsoft Intune admin access

### Required Tokens (Intune)
- APNs Certificate (renew annually)
- ADE/DEP Token (renew annually)
- VPP Token (renew annually)

### Required Licenses (ABM)
- VPP licenses for Company Portal
- VPP licenses for Google Chrome

---

## Key Configuration Summary

### VPP App Assignment (CRITICAL)
```
License type: DEVICE (not User)
Assignment: REQUIRED (not Available)
Assigned to: DEVICE GROUP (not User group)
```

### Enrollment Profile Settings
```
Supervised: YES
Locked enrollment: YES
User affinity: Based on use case
Await final configuration: YES
```

### Avoid These Settings
```
❌ Block App Store = Yes (in restriction profiles)
❌ User licensing for VPP apps
❌ Assign apps to user groups for userless devices
❌ Non-supervised enrollment
```

---

## Folder Structure

```
Ipad_Setup/
├── README.md                    # This file
├── docs/
│   ├── 01-DIAGNOSIS-GUIDE.md
│   ├── 02-ABM-ADE-DEPLOYMENT.md
│   ├── 03-INTUNE-CONFIGURATION.md
│   ├── 04-APPLE-CONFIGURATOR-FALLBACK.md
│   ├── 05-FIELD-REMEDIATION.md
│   └── 06-DEPLOYMENT-RUNBOOK.md
├── checklists/                  # Printable checklists
├── profiles/                    # Sample configuration profiles
└── scripts/                     # Automation scripts (future)
```

---

## Support

| Level | Contact | Response |
|-------|---------|----------|
| Tier 1 | Help Desk | Same day |
| Tier 2 | Intune Admin | 4 hours |
| Tier 3 | it@sbsfederal.com | 24 hours |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-01-21 | Initial release |

---

*SBS Federal IT Department - Confidential*
