# 09 — Troubleshooting

## Overview

This document captures real troubleshooting scenarios encountered while building and validating the TKP environment, documented using a consistent structure: **Problem → Symptoms → Initial Hypothesis → Investigation → Commands/Tools Used → Evidence → Root Cause → Solution → Verification → Prevention**.

The goal of this section is not just to show that issues were fixed, but to show the diagnostic process used to get there.

---

## Scenario 1 — DNSSEC Validation Failure

**Problem:** After enabling DNSSEC on `SRV-1`, secondary DNS servers (`SRV-2`, `SRV-01`) failed to validate the signed `TKP.local` zone.

**Symptoms:** Clients querying the secondary DNS servers received `SERVFAIL` or unresolved responses for records that resolved correctly when queried directly against `SRV-1`.

**Initial Hypothesis:** Zone transfer of DNSSEC-related records (RRSIG, DNSKEY) was incomplete, or the trust anchor was not correctly configured on the secondary servers.

**Investigation:** Compared zone data on `SRV-1` against `SRV-2`/`SRV-01` after a full zone transfer; checked whether DNSSEC-specific record types were present on the secondaries.

**Commands/Tools Used:** `Resolve-DnsName -DnssecOk`, `dnscmd /zoneprint`, review of Trust Anchor configuration on each secondary.

**Evidence:** RRSIG and DNSKEY records were present in the zone transfer, but the trust anchor on the secondary servers had not been configured/updated to match the signed zone.

**Root Cause:** DNSSEC validation depends on the resolving server having a correct, current trust anchor for the zone — this is separate from the zone transfer itself and is not automatically configured just by transferring signed zone data.

**Solution:** Configured the trust anchor on `SRV-2` and `SRV-01` to match `SRV-1`'s signed zone, and confirmed RRSIG expiration windows were current.

**Verification:** Re-queried the same records against both secondary servers with `-DnssecOk` and confirmed successful validation (AD flag set).

**Prevention:** Documented trust anchor configuration as a required step alongside DNSSEC enablement, not an optional add-on — added to the DNS setup checklist for any future secondary DNS server added to the environment.

---

## Scenario 2 — Conditional Forwarder to ISP Not Working

**Problem:** Internal clients using `SRV-1` as their DNS server could not resolve the simulated external hostname (`www.google.com`).

**Symptoms:** `nslookup www.google.com` against `SRV-1` returned no response or timed out; direct queries against the `ISP` DNS server succeeded.

**Initial Hypothesis:** Either the conditional forwarder was misconfigured, or traffic between `SRV-1` and the `ISP` DNS server was being blocked at the network layer.

**Investigation:** Verified the conditional forwarder configuration on `SRV-1` pointed to the correct ISP DNS IP; tested UDP/53 reachability from `SRV-1` toward `ISP` across the routed path (`EDGE-1 → R-1 → LAN D`).

**Commands/Tools Used:** `nslookup` (direct queries against the forwarder IP), `Test-NetConnection -Port 53`, review of firewall rules on the LAN D boundary.

**Evidence:** UDP/53 traffic from `SRV-1` toward `ISP` was being dropped by the same directional isolation rule enforced for the ISP boundary (see [08-security-controls.md](08-security-controls.md)) — the rule had been scoped too broadly and was blocking legitimate internally-initiated DNS queries, not just ISP-initiated inbound traffic.

**Root Cause:** The firewall rule enforcing ISP one-way isolation did not correctly distinguish between "ISP-initiated inbound" (which should be blocked) and "internally-initiated outbound with expected return traffic" (which should be allowed) for UDP/53 specifically.

**Solution:** Adjusted the rule scope at the LAN D boundary to explicitly permit outbound UDP/53 from internal DNS servers to the ISP DNS server, and its return traffic, while keeping ISP-initiated inbound connections blocked.

**Verification:** Re-tested `nslookup www.google.com` against `SRV-1` from an internal client and confirmed successful resolution via the conditional forwarder.

**Prevention:** Added an explicit test case to the security-control verification checklist: confirm conditional forwarding works *after* any change to the ISP boundary firewall rules, not just ping-level reachability.

---

## Scenario 3 — DFS Namespace Not Reachable from SRV-02

**Problem:** `SRV-02`, at the Branch site, could not access the DFS namespace hosted on `SRV-2`.

**Symptoms:** UNC path `\\TKP.local\dfsroot` failed to resolve or timed out when accessed from `SRV-02`; the same path worked correctly from Headquarters clients.

**Initial Hypothesis:** Either DNS resolution of the namespace from the Branch site was failing, or SMB connectivity across the site-to-site VPN tunnel was blocked.

**Investigation:** Tested DNS resolution of the namespace name from `SRV-02` independently of the DFS access attempt; tested raw SMB (port 445) connectivity from `SRV-02` to `SRV-2` across the VPN tunnel.

**Commands/Tools Used:** `Resolve-DnsName`, `Test-NetConnection -Port 445`, `dfsutil /pktinfo`, DFS Diagnostic Report (DFS Management console).

**Evidence:** DNS resolution succeeded, but SMB (port 445) connectivity from `SRV-02` to `SRV-2` failed specifically across the tunnel — the VPN tunnel was up, but a NAT/PAT translation issue at `EDGE-1` was altering the expected return path for SMB sessions initiated from the Branch.

**Root Cause:** A NAT/PAT rule scoping issue at `EDGE-1` was affecting SMB traffic originating from the Branch side of the tunnel, breaking the session before DFS referral could complete.

**Solution:** Corrected the NAT/PAT rule at `EDGE-1` to properly handle the return path for Branch-initiated SMB sessions across the tunnel.

**Verification:** Re-tested UNC path access from `SRV-02` and confirmed both SRV-1- and SRV-3-hosted folder targets were reachable through the namespace.

**Prevention:** Added a specific SMB-over-VPN connectivity test to the post-VPN-configuration-change checklist, since ICMP/ping-only VPN verification had not caught this.

---

## Scenario 4 — RDS RemoteApp Certificate Warning

**Problem:** Launching the published RemoteApp (Paint) from a domain-joined client displayed a certificate trust warning instead of connecting cleanly.

**Symptoms:** Client prompted with an untrusted-certificate warning before the RemoteApp session would launch.

**Initial Hypothesis:** The client had not received the expected Group Policy update distributing CA trust, or the certificate's subject name did not match the FQDN the client was connecting to.

**Investigation:** Checked GPO application status on the affected client; inspected the certificate presented by `SRV-3` for its Common Name/Subject Alternative Name against the FQDN used to connect.

**Commands/Tools Used:** `gpresult /r`, `certlm.msc` (Trusted Root store inspection), certificate details inspection on the RDS connection.

**Evidence:** The GPO had applied correctly and the Enterprise Root CA was already trusted (this was internal, not the ISP CA scenario) — the actual mismatch was between the FQDN used in the RemoteApp connection shortcut and the certificate's issued Subject Name.

**Root Cause:** The RemoteApp connection was configured to use a short hostname rather than the certificate's full FQDN, causing a name-mismatch trust failure independent of the CA trust chain itself.

**Solution:** Reconfigured the RemoteApp connection to use the certificate's exact FQDN, matching the issued Subject Name.

**Verification:** Relaunched the RemoteApp from a domain-joined client and confirmed no certificate warning appeared.

**Prevention:** Documented the requirement that RDS/RemoteApp connection configuration must use the certificate's exact FQDN, added as a check item in [04-pki-design.md](04-pki-design.md) certificate issuance notes.

---

## Scenario 5 — L2TP/IPsec VPN Connection Failure (NAT-T and RRAS Authentication)

**Problem:** While establishing the L2TP/IPsec site-to-site VPN using a Windows RRAS Demand-Dial interface between `EDGE-1` and `EDGE-2`, the connection failed with:

```text
An error occurred during connection of the interface.

The remote connection was denied because the user name and
password combination you provided is not recognized, or the
selected authentication protocol is not permitted on the
remote access server.
```

**Symptoms:** The Demand-Dial VPN interface consistently failed to connect, with an authentication-denied error reported on the initiating side.

**Initial Hypothesis:** Because both VPN endpoints sit behind NAT, IPsec NAT Traversal (NAT-T) might not be correctly enabled — but the error text pointed toward credentials/authentication as well, so both areas needed to be checked.

**Investigation:** Checked whether Windows IPsec (PolicyAgent) was configured to allow NAT-T/UDP encapsulation given the NAT topology, and separately reviewed the Demand-Dial interface's stored credentials against the VPN user account on the remote RRAS server.

**Commands/Tools Used:** Registry Editor (`HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\PolicyAgent`), RRAS console (Network Interfaces → VPN Interface → Set Credentials), `compmgmt.msc` (local user/VPN account review), `ping` and `tracert` for post-fix verification.

**Evidence:** No `AssumeUDPEncapsulationContextOnSendRule` DWORD value existed under `PolicyAgent`, meaning Windows was not configured to assume a NAT-T context — a required setting when both IPsec peers are behind NAT. Separately, the Demand-Dial interface's stored credentials did not match a valid, VPN-permitted user account on the remote RRAS server.

**Root Cause:** Two independent issues were compounding the failure: (1) IPsec NAT-T was not enabled for the NAT topology in use, and (2) the Demand-Dial interface's authentication credentials did not match a valid VPN-enabled user on the remote RRAS server.

**Solution:**
1. Created the DWORD value `AssumeUDPEncapsulationContextOnSendRule` under `PolicyAgent` and set it to `2`, allowing Windows IPsec to use NAT-T (UDP encapsulation over port 4500) for this topology.
2. Restarted the server (`Restart-Computer`) so the PolicyAgent change took effect.
3. Corrected the Demand-Dial interface's stored credentials to match a valid VPN-permitted user account on the remote RRAS server, verifying that user's existence, password, and remote-access permission via `compmgmt.msc`.
4. Reconnected the Demand-Dial interface from the RRAS console.

**Verification:** Confirmed the interface reached a `Connected` state, then validated reachability with `ping <remote-server-IP>` and path validation with `tracert <remote-server-IP>` across the tunnel.

**Prevention:** Documented `AssumeUDPEncapsulationContextOnSendRule=2` as a required PolicyAgent setting for any future NAT-behind-NAT L2TP/IPsec deployment, and added Demand-Dial credential verification as a separate, explicit check — since an authentication error can look identical whether its root cause is IPsec/NAT-T or RRAS-level authentication. Troubleshooting is now approached as a layered chain (NAT/NAT-T → L2TP tunnel → RRAS authentication → VPN interface → routing → remote connectivity) rather than treating VPN failure as a single undifferentiated problem.

---

## Scenario 6 — ISP One-Way Isolation Not Enforced

**Problem:** During initial testing, the `ISP` host was able to successfully ping internal hosts, which should not have been possible under the intended directional isolation design.

**Symptoms:** `ping` from `ISP` toward internal addresses (e.g., `10.10.10.1`) succeeded, contrary to the intended one-way rule.

**Initial Hypothesis:** The firewall/ACL rule enforcing the isolation was either missing, misapplied, or overridden by routing table behavior at `R-1` or the edge routers.

**Investigation:** Reviewed rule direction (inbound vs. outbound) at the LAN D boundary, checked rule order/scope, and reviewed the routing tables on `R-1` and both edge routers for any rule that might bypass the intended block.

**Commands/Tools Used:** Firewall rule review at the LAN D boundary, routing table inspection (`route print` equivalent on each router), `ping` tests from multiple directions.

**Evidence:** The isolation rule had been applied in the outbound direction on the wrong interface, effectively blocking internal-to-ISP traffic in one misconfigured case while leaving ISP-to-internal traffic unrestricted — the opposite of the intended behavior.

**Root Cause:** Rule direction and interface binding were incorrectly configured during initial setup, inverting the intended access model.

**Solution:** Reconfigured the rule to correctly block inbound connections *originating from* the ISP interface toward internal segments, while explicitly permitting internally-initiated outbound traffic and its return path.

**Verification:** Re-tested `ping` in both directions — internal-to-ISP succeeded, ISP-to-internal failed — confirming the intended one-way behavior.

**Prevention:** Added a mandatory bidirectional connectivity test (not just one direction) to the security-control verification checklist, since testing only one direction had allowed the misconfiguration to go unnoticed initially.

---

## Scenario 7 — FTP Passive Data Connection Failure over the Site-to-Site VPN

**Problem:** The IIS FTP server (on `SRV-2`) was reachable from the Branch site across the L2TP site-to-site VPN. The FTP control connection (TCP/21) worked and clients could authenticate, but any operation requiring the data connection — directory listing, upload, download — failed.

**Symptoms:**
- TCP/21 connection: working
- FTP authentication: working
- Directory listing: failed
- File transfer: failed
- Passive FTP data connection: never established
- `netstat` showed no active connection on the configured passive port range

This narrowed the problem specifically to the FTP passive data channel, not the control channel or authentication.

**Initial Hypothesis:** Something between the client and `SRV-2` was interfering specifically with the passive data channel, since the control channel and authentication were both confirmed working — most likely NAT or firewall behavior specific to FTP, given the traffic was crossing an RRAS NAT device as part of the VPN path.

**Investigation:** Checked whether the negotiated passive-mode data port was actually being opened and connected to, and reviewed which components in the path perform FTP-aware inspection or rewriting — specifically the RRAS NAT configuration and Windows Firewall's FTP-specific filtering.

**Commands/Tools Used:** `netstat` (passive port range check), `netsh routing ip nat` (RRAS NAT/FTP ALG configuration review), `netsh advfirewall` (stateful FTP filtering review).

**Evidence:** RRAS NAT had FTP ALG/FTP Proxy active, and Windows Firewall had stateful FTP filtering enabled. Both features perform FTP-aware inspection and rewriting of the control channel to track and permit the expected data channel — behavior designed for traditional NAT/internet-facing FTP scenarios, not for FTP traffic already flowing over an internal, already-encrypted VPN tunnel. This FTP-aware processing was interfering with, rather than helping, the passive data channel negotiation.

**Root Cause:** RRAS's FTP ALG/Proxy and Windows Firewall's stateful FTP filtering were both attempting FTP-aware NAT/firewall handling of traffic that didn't need it in this topology, and that handling broke the passive data channel establishment.

**Solution:**
1. Removed the FTP ALG/Proxy from RRAS NAT: `netsh routing ip nat delete ftp`.
2. Restarted RRAS to apply the change: `net stop RemoteAccess` followed by `net start RemoteAccess`.
3. Disabled Windows Firewall's stateful FTP filtering: `netsh advfirewall set global statefulftp disable`, allowing the FTP data channel to be handled as ordinary TCP traffic instead of FTP-aware inspection.

**Verification:** Re-tested from the Branch site: control connection, authentication, passive data connection, directory listing, upload, and download all succeeded.

**Prevention:** Documented that a working control connection (TCP/21) is not sufficient evidence that FTP is fully functional — FTP's separate control/data channel design means the data channel, and any FTP-aware NAT/ALG or stateful firewall inspection in the path, must be checked independently. Added FTP ALG and stateful FTP filtering status as an explicit check item whenever FTP traffic crosses an RRAS NAT device.

---

## Related Documents

- [08-security-controls.md](08-security-controls.md) — ISP isolation design (Scenarios 2, 6)
- [03-dns-architecture.md](03-dns-architecture.md) — DNSSEC and conditional forwarding design (Scenarios 1, 2)
- [05-file-services.md](05-file-services.md) — DFS namespace design (Scenario 3)
- [04-pki-design.md](04-pki-design.md) — certificate issuance design (Scenario 4)
- [07-site-to-site-vpn.md](07-site-to-site-vpn.md) — VPN tunnel and NAT/PAT design (Scenarios 5, 7)
