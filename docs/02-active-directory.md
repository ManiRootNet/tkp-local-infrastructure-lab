# 02 — Active Directory

## Overview

This document covers the Active Directory Domain Services (AD DS) design for `TKP.local`, including Domain Controller placement, the Read-Only Domain Controller (RODC) at the Branch site, bulk user provisioning, and file share layout.

---

## Domain Controllers

| Host | Role | Location |
|---|---|---|
| **SRV-1** | Writable Domain Controller, Primary DNS, Enterprise Root CA | Headquarters (LAN A) |
| **SRV-01** | Read-Only Domain Controller (RODC), Secondary DNS | Branch (LAN F) |

### Why a Writable DC at Headquarters and an RODC at the Branch

`SRV-1` holds the only writable copy of the domain. Placing it at Headquarters keeps directory-write authority (schema, password changes, group membership, etc.) inside the more controlled, centrally-managed site.

`SRV-01`, at the Branch, is deployed as an RODC rather than a second writable DC. This is a deliberate security decision, not a limitation: the Branch is a remote, less physically and administratively controlled location connected back to Headquarters over a WAN link and a site-to-site VPN. An RODC:

- Holds a read-only copy of the AD database, so it cannot be used to push unauthorized directory changes even if the host itself is compromised.
- Does not cache all domain credentials by default — only those of users who authenticate through it (per the Password Replication Policy), limiting the blast radius of a Branch-site compromise.
- Still provides local authentication and DNS resolution for Branch users/hosts, avoiding a full round-trip to Headquarters for every logon.

This mirrors a standard real-world branch-office AD pattern: centralize write authority, localize read/authentication capability.

---

## Domain Structure

- **Domain:** `TKP.local`
- **Forest/Domain functional level:** single-domain forest (no additional child domains)

---

## User Provisioning

### Requirement

100 user accounts, each with distinct names and complete attributes, provisioned consistently rather than created one-by-one through the GUI.

### Approach

User accounts are provisioned from a CSV file via a PowerShell script (`scripts/bulk-user-import.ps1`, `scripts/sample-users.csv`) that:

1. Reads one row per user from the CSV (name fields, organizational attributes, and an initial password).
2. Creates the AD user object with the full attribute set from that row.
3. Sets the initial password from the CSV value.
4. Enables the account.

### Why CSV + PowerShell Instead of Manual Creation

- **Consistency:** every account is created with the same attribute structure — no accounts missing fields due to manual entry mistakes.
- **Repeatability:** the same script can be re-run against a new CSV to provision another batch (e.g., a future department or branch) without redesigning the process.
- **Scale:** 100 accounts created one-by-one through Active Directory Users and Computers would be impractical and error-prone; scripting turns a multi-hour manual task into a single repeatable run.
- **Documentation value:** the script itself is a piece of reusable automation, not just a one-off setup step.

### Sample Data Note

`scripts/sample-users.csv` in this repository contains fake/anonymized sample data only. No real passwords or personally identifiable data are included — see [Security & Privacy](../README.md#security--privacy) in the main README.

---

## Shared Folders

Five shared folders are created on each of the following servers as part of the file-services layer:

| Host | Shared Folders |
|---|---|
| SRV-1 | 5 shares |
| SRV-3 | 5 shares |
| SRV-2 | 5 shares |

The shares on SRV-1 and SRV-3 are later consolidated into a single DFS Namespace hosted on SRV-2 — see [05-file-services.md](05-file-services.md) for the namespace design and cross-site access validation.

---

## Verification

- Confirmed all 100 accounts were created and enabled with `Get-ADUser -Filter *` (attribute spot-checks against the source CSV).
- Confirmed RODC replication and authentication behavior at the Branch, including Password Replication Policy scope.
- Confirmed logon and resource access from a Branch-site test host (SRV-02) using domain credentials.

---

## Related Documents

- [03-dns-architecture.md](03-dns-architecture.md) — AD-integrated DNS and RODC DNS role
- [04-pki-design.md](04-pki-design.md) — Enterprise Root CA integration with `TKP.local`
- [05-file-services.md](05-file-services.md) — Shared folders and DFS Namespace
- [09-troubleshooting.md](09-troubleshooting.md) — Related troubleshooting scenarios
