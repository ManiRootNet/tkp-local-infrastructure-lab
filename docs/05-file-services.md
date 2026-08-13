# 05 — File Services

## Overview

This document covers file share layout across the environment and the DFS Namespace that consolidates shares from multiple servers into a single logical access point.

---

## Shared Folders

Five shared folders are created on each of the following servers:

| Host | Site | Shares |
|---|---|---|
| SRV-1 | Headquarters | 5 shares |
| SRV-3 | Headquarters (LAN B) | 5 shares |
| SRV-2 | Headquarters | 5 shares |

The SRV-1 and SRV-3 shares are the sources consolidated into the DFS Namespace below. SRV-2's own 5 shares are separate, local shares.

---

## DFS Namespace

A DFS Namespace is hosted on `SRV-2`, presenting the 5 shares from `SRV-1` and the 5 shares from `SRV-3` under a single unified namespace path, rather than requiring users/administrators to know which physical server hosts which share.

```
\\TKP.local\dfsroot
        │
        ├── (5 folder targets) ──► SRV-1 shares
        └── (5 folder targets) ──► SRV-3 shares
```

### Why DFS Instead of Direct Shares

- **Location transparency:** users and scripts reference one namespace path instead of tracking which of two physical servers, on two different LAN segments (LAN A and LAN B), holds a given resource.
- **Simplified access for Branch clients:** a Branch-site host only needs to resolve and reach one namespace path, rather than separately knowing about and connecting to SRV-1 and SRV-3 individually.
- **Foundation for future resilience:** DFS Namespace is also the mechanism that would support DFS Replication for redundant folder targets in a future iteration (see [10-lessons-learned.md](10-lessons-learned.md)) — even though this lab uses a single target per folder today.

---

## Cross-Site Validation

Access to the DFS namespace was tested from `SRV-02`, a Branch-site host (LAN F), to confirm that:

- The namespace path resolves correctly via DNS from the Branch site.
- Folder targets on both SRV-1 (LAN A) and SRV-3 (LAN B) are reachable through the single namespace path, across the full routed path (`EDGE-2 → R-1 → EDGE-1`).
- Standard SMB access (read/write, per permissions) works end-to-end from the Branch to both underlying servers.

---

## Verification

- Confirmed namespace resolution and folder target listing from `SRV-02` via `dfsutil /pktinfo` and direct UNC path browsing.
- Confirmed SMB connectivity to both SRV-1- and SRV-3-hosted targets from the Branch site.
- Cross-checked DFS Management console on `SRV-2` to confirm both sets of folder targets are correctly registered under the namespace.

---

## Related Documents

- [01-network-design.md](01-network-design.md) — routed path between the Branch and the DFS-hosting segment
- [02-active-directory.md](02-active-directory.md) — underlying share creation on SRV-1 and SRV-3
- [09-troubleshooting.md](09-troubleshooting.md) — DFS namespace access troubleshooting scenario
