# 03 — DNS Architecture

## Overview

This document covers the DNS design across the TKP environment: primary/secondary zone placement, RODC-integrated DNS, forward and reverse lookup zones, DNSSEC, and conditional forwarding to the simulated ISP for external resolution.

DNS was designed as a distributed service — no single server is a hard dependency for name resolution across the environment.

---

## DNS Server Roles

| Host | Role | Notes |
|---|---|---|
| **SRV-1** | Primary DNS (Headquarters) | Master for all forward and reverse zones; DNSSEC signing origin |
| **SRV-2** | Secondary DNS (Headquarters) | Zone transfers from SRV-1 |
| **SRV-01** | Secondary DNS + RODC-integrated DNS (Branch) | Zone transfers from SRV-1 |
| **ISP** | Standalone DNS | Separate, independent DNS infrastructure for the simulated external network |

---

## Forward Lookup Zone: TKP.local

Hosted primary on `SRV-1`, secondary on `SRV-2` and `SRV-01`.

| Record Type | Name | Points To | Purpose |
|---|---|---|---|
| A | `www` | SRV-2 | Web server (IIS) |
| CNAME | (FTP alias) | SRV-2 | FTP service alias |
| CNAME | (DFS alias) | SRV-2 | DFS Namespace alias |
| MX | `TKP.local` | SRV-2 | Mail routing placeholder — SRV-2 does not run a real mail server; the record exists to demonstrate correct MX configuration, not to deliver mail |
| NS | `TKP.local` | SRV-1, SRV-2, SRV-01 | Authoritative name server records |

---

## Reverse Lookup Zones

Three reverse lookup zones are hosted primary on `SRV-1`, one per internal network, each containing PTR and NS records:

| Zone | Network | Purpose |
|---|---|---|
| `10.10.10.in-addr.arpa` | LAN A | PTR records for SRV-1, SRV-2 |
| `20.20.20.in-addr.arpa` | LAN B | PTR records for SRV-3 |
| `60.60.60.in-addr.arpa` | LAN F | PTR records for SRV-01, SRV-02 |

All three reverse zones are DNSSEC-signed on `SRV-1` and replicated as secondary to the other internal DNS servers, mirroring the forward zone's Primary/Secondary structure.

The `ISP` host maintains its own separate reverse lookup zone for its own network (`40.40.40.in-addr.arpa`), signed independently with its own DNSSEC configuration — it is not part of the `TKP.local` zone hierarchy.

---

## DNSSEC

DNSSEC is enabled on `SRV-1` for:

- The `TKP.local` forward zone
- All three internal reverse lookup zones

Zone signing takes place on `SRV-1` as the primary/master server; signed zone data (including RRSIG, DNSKEY, and NSEC records) is transferred to the secondary servers (`SRV-2`, `SRV-01`) along with the rest of the zone during normal zone transfer.

The `ISP` DNS server independently signs its own reverse zone with its own DNSSEC configuration, entirely separate from the `TKP.local` DNSSEC chain — reflecting that the ISP is a separate administrative and trust domain, not a subordinate zone of `TKP.local`.

---

## RODC-Integrated DNS at the Branch

`SRV-01`, the Branch RODC, also runs DNS as a secondary server (master: `SRV-1`). This lets Branch clients (`SRV-02` and others on LAN F) resolve internal names locally without a round trip to Headquarters for every query, while keeping the Branch DNS server read-only/secondary, consistent with the RODC's read-only role for AD (see [02-active-directory.md](02-active-directory.md)).

---

## Conditional Forwarding to the Simulated ISP

`SRV-1` is configured with a conditional forwarder pointing external name resolution (e.g., `google.com`) to the `ISP` DNS server. Because `SRV-2` and `SRV-01` are secondaries of `SRV-1`'s zones and domain clients use the internal DNS servers, any client using the internal DNS infrastructure can resolve the simulated external site through this forwarder — without every internal DNS server needing its own separate forwarder configuration.

This models a realistic pattern: internal DNS servers don't recursively resolve the open internet themselves; they forward specific external namespaces to a designated, controlled path (here, the simulated ISP), keeping external resolution centralized and observable.

---

## Zone Replication Summary

```
SRV-1 (Primary: forward zone + 3 reverse zones, DNSSEC-signed)
   │
   ├── zone transfer ──► SRV-2   (Secondary)
   └── zone transfer ──► SRV-01  (Secondary, RODC-integrated)

ISP (independent Primary: own reverse zone, own DNSSEC)
```

---

## Verification

- `Resolve-DnsName` / `nslookup` used to confirm A, CNAME, MX, and NS record resolution for `TKP.local` from multiple internal hosts.
- PTR resolution tested against all three internal reverse zones.
- DNSSEC validation confirmed via signed-zone lookups (RRSIG presence) on `SRV-1` and successful validation from secondary servers after zone transfer.
- Conditional forwarding tested by resolving the simulated external hostname from an internal client using only its configured internal DNS servers.
- Zone transfer from `SRV-1` to both `SRV-2` and `SRV-01` verified after each zone change.

---

## Related Documents

- [01-network-design.md](01-network-design.md) — network segments referenced by the reverse zones
- [02-active-directory.md](02-active-directory.md) — RODC role and Branch DC placement
- [04-pki-design.md](04-pki-design.md) — certificate trust for the HTTPS services these DNS records resolve
- [09-troubleshooting.md](09-troubleshooting.md) — DNSSEC and conditional forwarder troubleshooting scenarios
