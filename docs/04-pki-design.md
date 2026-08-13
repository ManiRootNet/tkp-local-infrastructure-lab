# 04 — PKI Design

## Overview

This document covers the Public Key Infrastructure (PKI) design across the TKP environment: two independent Certificate Authority (CA) hierarchies, why they are kept separate rather than chained, how trust between them is established through Group Policy, and where the resulting certificates are used.

---

## Two Independent CA Hierarchies

Unlike a typical single-organization PKI (Root CA → Subordinate CA), this environment deliberately runs **two separate, unrelated CA hierarchies**:

| CA | Type | Host | Domain-Integrated | Issues Certificates For |
|---|---|---|---|---|
| **TKP Enterprise Root CA** | Enterprise Root CA | `SRV-1` | Yes (AD CS, integrated with `TKP.local`) | Internal services: RDS RemoteApp, IIS/HTTPS |
| **ISP Root CA** | Standalone Root CA | `ISP` | No (outside the domain) | The simulated external service, `www.google.com` |

These are **not** a parent/child (Root → Subordinate) chain. They are two independent trust roots, each authoritative for its own side of the environment.

### Why Two Independent Hierarchies Instead of One Chain

- **The ISP is outside the domain.** An Enterprise CA requires AD DS integration to issue certificates automatically via templates; since `ISP` is intentionally outside `TKP.local` (it represents an external network, not an internal server — see [08-security-controls.md](08-security-controls.md)), a Standalone CA is the correct fit there, not an Enterprise CA.
- **It models a real trust problem.** In practice, organizations routinely need to trust certificates issued by CAs they do not control — a third-party CA, a partner organization, a SaaS vendor's internal PKI, etc. Two unrelated CA hierarchies, bridged only by an explicit trust decision, is a more realistic simulation of that situation than a single internal chain would be.
- **It keeps the domain's own trust root authoritative for the domain.** The Enterprise Root CA on `SRV-1` only ever issues certificates for services that are actually part of `TKP.local`. It never has to reason about, or be exposed to, the ISP's certificate practices.

---

## Establishing Trust Between the Two Hierarchies: Group Policy Distribution

Because the two CAs are independent, a domain-joined client has no inherent reason to trust a certificate issued by the `ISP` Root CA — it isn't in the client's Trusted Root store by default, and it isn't part of the `TKP.local` AD CS chain.

To resolve this without manually installing the certificate on every machine, the **ISP Root CA's certificate is distributed to all domain-joined computers via Group Policy**, adding it to their local Trusted Root Certification Authorities store. Once applied, any domain-joined host can establish a trusted, warning-free HTTPS connection to the simulated `www.google.com` service, exactly as if that CA had been a recognized public CA.

This is the same mechanism organizations use in the real world to trust an internal or third-party CA across a fleet of managed machines — GPO-based root certificate distribution instead of per-machine manual installation.

```
TKP Enterprise Root CA (SRV-1, domain-integrated)
        │
        └── issues certs for internal services (RDS, IIS)

ISP Root CA (ISP, standalone, outside the domain)
        │
        └── issues cert for the simulated external site (www.google.com)
        │
        └── trust bridged to domain clients via Group Policy
            (added to Trusted Root store — not a CA chain)
```

---

## Certificate Usage

| Certificate | Issued By | Used By | Purpose |
|---|---|---|---|
| RDS/RemoteApp certificate | TKP Enterprise Root CA | `SRV-3` | Secures the published RemoteApp (Paint) session |
| IIS/HTTPS certificate | TKP Enterprise Root CA | `SRV-2` | Secures `https://www.TKP.local` |
| External site certificate | ISP Root CA | `ISP` | Secures the simulated `https://www.google.com` |

---

## Verification

- Confirmed the ISP Root CA certificate is present in the Trusted Root Certification Authorities store on domain-joined test machines after `gpupdate`, via `certlm.msc` and `gpresult /r`.
- Confirmed `https://www.google.com` (simulated) loads without a certificate warning from a domain-joined client.
- Confirmed the RDS RemoteApp session launches without a certificate trust warning, validating the Enterprise Root CA chain for internal services.
- Confirmed `https://www.TKP.local` presents a certificate trusted by domain clients by default (as members of `TKP.local` inherently trust their own Enterprise Root CA).

---

## Related Documents

- [03-dns-architecture.md](03-dns-architecture.md) — name resolution for the services these certificates secure
- [06-remote-access.md](06-remote-access.md) — RDS RemoteApp certificate usage in detail
- [08-security-controls.md](08-security-controls.md) — why the ISP is treated as an external/untrusted network boundary
- [09-troubleshooting.md](09-troubleshooting.md) — certificate trust troubleshooting scenario
