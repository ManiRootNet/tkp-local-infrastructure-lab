# VPN Configuration Parameters — EDGE-1 ↔ EDGE-2

> Non-sensitive reference parameters only. No PSK, private keys, or other secrets are included in this file or anywhere in this repository. See [Security & Privacy](../README.md#security--privacy).

## Tunnel Summary

| Parameter | Value |
|---|---|
| Tunnel Type | Site-to-Site |
| Protocol | L2TP/IPsec |
| Authentication Method | Pre-Shared Key (PSK) |
| PSK Value | `[REDACTED]` |
| Interface Type | RRAS Demand-Dial |
| Tunnel Endpoints | `EDGE-1` ↔ `EDGE-2` |
| Establishing Side | EDGE-1 → EDGE-2 |

## IKE Phase 1 (ISAKMP / Main Mode)

| Parameter | Value |
|---|---|
| Encryption | `[document actual value used]` |
| Hash / Integrity | `[document actual value used]` |
| Diffie-Hellman Group | `[document actual value used]` |
| Authentication Method | Pre-Shared Key |

## IKE Phase 2 (Quick Mode)

| Parameter | Value |
|---|---|
| Encryption | `[document actual value used]` |
| Integrity | `[document actual value used]` |
| Perfect Forward Secrecy (PFS) | `[document actual value used]` |

## NAT-T / NAT Considerations

Both VPN endpoints operate behind NAT. IPsec NAT Traversal is required — see [09-troubleshooting.md, Scenario 5](../docs/09-troubleshooting.md#scenario-5--l2tpipsec-vpn-connection-failure-nat-t-and-rras-authentication) for the specific registry configuration (`AssumeUDPEncapsulationContextOnSendRule = 2` under `PolicyAgent`) required to make NAT-T work correctly in this topology.

## NAT/PAT

| Parameter | Value |
|---|---|
| NAT/PAT Location | `EDGE-1` |
| Direction | EDGE-1 → EDGE-2 |
| Purpose | Keeps Headquarters/Branch internal addressing independent across the tunnel |

## Related Documents

- [07-site-to-site-vpn.md](../docs/07-site-to-site-vpn.md) — full tunnel design and rationale
- [09-troubleshooting.md](../docs/09-troubleshooting.md) — VPN and FTP-over-VPN troubleshooting scenarios
