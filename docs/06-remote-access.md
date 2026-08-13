# 06 — Remote Access

## Overview

This document covers the Remote Desktop Services (RDS) RemoteApp deployment on `SRV-3`, which publishes a lightweight application rather than a full interactive desktop session, secured with certificate-based trust.

---

## Deployment

`SRV-3` hosts an RDS RemoteApp deployment publishing **Microsoft Paint** as a standalone, remotely-accessible application. Users launch Paint directly through the RemoteApp connection rather than logging into a full remote desktop session.

---

## Why RemoteApp Instead of a Full Remote Desktop Session

- **Reduced exposure:** a RemoteApp session only publishes the specific application a user needs, rather than an entire desktop environment with access to the full file system, other installed software, and system settings.
- **Clearer access boundary:** it demonstrates a controlled-access pattern — publishing a single piece of functionality — that is closer to how organizations actually expose internal tools to users who need a specific application, not full desktop access.
- **Paint as a deliberately simple example:** the application itself is intentionally lightweight; the point of the exercise is the publishing, security, and trust mechanism around it, not the application's own functionality.

---

## Certificate-Based Security

The RemoteApp deployment is secured with a certificate issued by the **TKP Enterprise Root CA** (hosted on `SRV-1` — see [04-pki-design.md](04-pki-design.md)). Because `SRV-3` and client machines are domain-joined and inherently trust the Enterprise Root CA, the RemoteApp connection is established without a certificate trust warning.

This certificate serves two purposes:
- **Encrypts** the RDP/RemoteApp session traffic.
- **Authenticates** the RD Session Host to the connecting client, so the client can verify it is connecting to the legitimate `SRV-3` host and not an impersonating device.

---

## Verification

- Launched the published Paint RemoteApp from a domain-joined client and confirmed no certificate trust warning appears, validating the Enterprise Root CA chain end-to-end.
- Confirmed the certificate presented by the RD Session Host matches the expected FQDN for `SRV-3`.
- Confirmed the session functions correctly (application launches, responds, and closes cleanly) over the routed path from both Headquarters and Branch client locations.

---

## Related Documents

- [04-pki-design.md](04-pki-design.md) — Enterprise Root CA and certificate issuance
- [01-network-design.md](01-network-design.md) — routed path from Branch clients to SRV-3
- [09-troubleshooting.md](09-troubleshooting.md) — RemoteApp certificate warning troubleshooting scenario
