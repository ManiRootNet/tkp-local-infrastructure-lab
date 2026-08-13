# 08 — Security Controls

## Overview

This document covers the directional network isolation enforced around the simulated ISP segment: internal hosts can reach and validate services on the ISP network, but the ISP host is prevented from initiating connections toward the internal networks.

---

## Design Intent

Rather than treating the ISP segment as part of the trusted internal LAN, it is modeled as an **untrusted external boundary** — the same way a real organization would treat its actual upstream provider or the open internet. Internal systems are permitted to reach out to it (for DNS resolution, HTTPS access, etc.), but nothing on that segment is trusted to reach back in on its own initiative.

```
Internal Network  ───────►  ISP
       ALLOWED

ISP  ───────X──────►  Internal Network
             BLOCKED
```

This reflects a standard defense-in-depth principle: an upstream/external network boundary should be able to be *validated and used* by internal systems without being able to *act on* internal systems.

---

## Implementation

The one-way rule is enforced through routing/firewall configuration at the boundary between the internal networks and the ISP segment (LAN D), rather than relying on the ISP host's own local firewall — since a compromised or misconfigured ISP host should not be able to remove its own restriction. Specifically:

- Internal hosts are permitted to initiate outbound connections toward `40.40.40.1` (ISP) — e.g., DNS queries via the conditional forwarder, HTTPS to the simulated external site.
- Inbound connection attempts *originating from* the ISP host toward any internal segment (LAN A, B, C, E, F) are blocked at the boundary.
- Return traffic for internal-initiated sessions (e.g., the response to an internal host's HTTPS request) is permitted, since it is part of an already-allowed, internally-initiated flow — not a new inbound connection.

---

## Verification

- From an internal host: `ping 40.40.40.1` succeeds.
- From the ISP host: `ping` toward any internal address (e.g., `10.10.10.1`, `30.30.30.1`) fails.
- Confirmed HTTPS access from internal hosts to the simulated `www.google.com` service on ISP succeeds (return traffic for internally-initiated sessions correctly permitted).
- Reviewed firewall/ACL rule order and scope at the LAN D boundary to confirm the block applies specifically to ISP-*initiated* traffic and not to legitimate return traffic.

---

## Related Documents

- [01-network-design.md](01-network-design.md) — LAN D segment and its role in the topology
- [03-dns-architecture.md](03-dns-architecture.md) — conditional forwarding traffic that must be permitted outbound
- [09-troubleshooting.md](09-troubleshooting.md) — ISP isolation troubleshooting scenario
