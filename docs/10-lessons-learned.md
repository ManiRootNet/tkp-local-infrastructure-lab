# 10 — Lessons Learned

## Overview

This document reflects on the design decisions, challenges, and skills reinforced or newly developed while building the TKP environment — beyond what's already captured in the individual technical documents and [09-troubleshooting.md](09-troubleshooting.md).

---

## VPN troubleshooting taught me to separate layers, not treat "it's not connecting" as one problem

The L2TP/IPsec authentication failure (see [09-troubleshooting.md, Scenario 5](09-troubleshooting.md#scenario-5--l2tpipsec-vpn-connection-failure-nat-t-and-rras-authentication)) looked, at first glance, like a single error — a rejected connection. It actually had two independent causes stacked on top of each other: IPsec NAT-T wasn't enabled for the NAT-behind-NAT topology, *and* the Demand-Dial interface's stored credentials didn't match a valid VPN-permitted account on the remote RRAS server. Fixing only one would not have solved it.

That forced me to stop treating "the VPN won't connect" as a single symptom and instead work through it as a layered chain — NAT/NAT-T, tunnel negotiation, RRAS authentication, the interface itself, routing, and finally end-to-end reachability — checking each layer on its own evidence rather than assuming the first plausible cause was the only cause. It's a troubleshooting habit I now apply by default to any "it just doesn't connect" problem, not just VPNs: identify which layer the failure evidence actually points to before changing anything.

## FTP over VPN taught me that a working control connection proves less than it looks like it proves

The FTP passive-connection failure (see [09-troubleshooting.md, Scenario 7](09-troubleshooting.md#scenario-7--ftp-passive-data-connection-failure-over-the-site-to-site-vpn)) was the more counterintuitive of the two. TCP/21 connected, authentication succeeded — every obvious sign said "FTP is working" — and yet directory listings and transfers failed outright. The real issue was one layer deeper: RRAS's FTP ALG and Windows Firewall's stateful FTP filtering were both doing FTP-aware inspection that made sense for internet-facing NAT scenarios, but actively broke the passive data channel once that traffic was already flowing over an internal, encrypted VPN tunnel.

The lesson that stuck with me isn't really about FTP specifically — it's that "helper" features designed for one scenario (protecting/rewriting protocol-aware traffic across an untrusted NAT boundary) can be actively harmful in a different scenario (protocol traffic already inside a trusted, encrypted tunnel), and a passing control-channel test doesn't validate the whole protocol. I now treat multi-channel protocols (FTP being the clearest example) as needing their data path tested independently of their control path, and I check for protocol-aware NAT/firewall features as a specific line item whenever something is "half-working" like this.

## The PKI design sharpened something I already knew, rather than teaching it from zero

I'd worked with Certificate Authorities before, but designing this environment's PKI — two genuinely independent CA hierarchies (see [04-pki-design.md](04-pki-design.md)) instead of a single Root→Subordinate chain, then bridging trust between them deliberately through Group Policy — made the *reasoning* behind CA architecture much more concrete than it had been. Specifically, it clarified for me why an Enterprise CA has to be domain-integrated and therefore isn't the right tool for anything outside the domain, why a Standalone CA is the correct choice for that outside boundary, and that "trusting an external CA" is a deliberate, explicit administrative action (GPO-distributed root trust) — not something that happens automatically just because two systems can otherwise talk to each other. Building it hands-on, rather than just knowing the theory, is what actually made that distinction stick.

---

## What I'd Do Differently Next Time

- Test both directions and both the control and data path explicitly for any multi-channel or NAT-crossing service from the very first setup, rather than discovering the gap after the fact — the FTP and VPN issues above were both found because "it looked like it was working" until a very specific test exposed otherwise.
- Add a second writable Domain Controller for Headquarters-side redundancy — the current design has a single point of failure for directory writes (see [02-active-directory.md](02-active-directory.md)).
- Introduce Group Policy-based security baselines beyond just CA trust distribution (e.g., password policy, local security options) to round out the AD DS story.

---

## Related Documents

- [09-troubleshooting.md](09-troubleshooting.md) — full troubleshooting detail behind the lessons above
- [04-pki-design.md](04-pki-design.md) — PKI design referenced above
- [02-active-directory.md](02-active-directory.md) — Domain Controller placement and future redundancy note
