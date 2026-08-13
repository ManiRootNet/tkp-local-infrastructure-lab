# 07 — Site-to-Site VPN

## Overview

This document covers the site-to-site VPN connecting the Headquarters and Branch sites through their edge routers, `EDGE-1` and `EDGE-2`, along with the NAT/PAT design that accompanies it.

---

## Tunnel Design

| Parameter | Value |
|---|---|
| VPN type | Site-to-Site |
| Protocol | L2TP/IPsec |
| Authentication | Pre-Shared Key (PSK) |
| Tunnel endpoints | `EDGE-1` ↔ `EDGE-2` |
| Direction established | EDGE-1 → EDGE-2 |

> Actual PSK values, keys, and any other secrets are intentionally excluded from this repository. See [configs/vpn-parameters.md](../configs/vpn-parameters.md) for the non-sensitive parameter reference. See [Security & Privacy](../README.md#security--privacy) in the main README.

The tunnel is established between the two **edge** routers rather than through the core router (`R-1`). `R-1` only routes the resulting encrypted traffic between LAN C and LAN E as ordinary IP traffic — it has no awareness of, or role in, the VPN itself (see [01-network-design.md](01-network-design.md) for why `R-1` is kept as a pure routing layer).

---

## NAT/PAT

NAT/PAT is configured at the edge as part of the inter-site connectivity design, from `EDGE-1` toward `EDGE-2`. This allows the Headquarters and Branch internal address spaces (`10.10.10.0/24`, `20.20.20.0/24`, `60.60.60.0/24`) to remain independently addressed, private ranges, translated only at the point where traffic actually crosses the site boundary, rather than requiring globally-unique internal addressing across the whole organization.

---

## Why L2TP/IPsec with PSK

L2TP/IPsec with a pre-shared key was chosen as a well-understood, widely-supported site-to-site VPN combination for this environment: L2TP provides the tunneling, and IPsec provides encryption and integrity for the tunnel, with PSK as a straightforward authentication method appropriate for a two-router, statically-known topology (as opposed to certificate-based authentication, which would be more appropriate for a larger number of dynamically-connecting peers).

---

## Verification

- Confirmed tunnel establishment and `Connected` status via RRAS on both `EDGE-1` and `EDGE-2`.
- Reviewed IKE Phase 1 and Phase 2 negotiation logs to confirm matching encryption/authentication parameters on both ends.
- Confirmed end-to-end connectivity between a Headquarters host (e.g., `SRV-2`) and a Branch host (e.g., `SRV-02`) across the tunnel.
- Confirmed NAT/PAT translation behavior at `EDGE-1` using connection-tracking output during cross-site tests.

---

## Related Documents

- [01-network-design.md](01-network-design.md) — overall topology and why `R-1` stays VPN-unaware
- [08-security-controls.md](08-security-controls.md) — how this tunnel fits into the broader security boundary design
- [09-troubleshooting.md](09-troubleshooting.md) — VPN tunnel troubleshooting scenario
