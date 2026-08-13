# TKP Local Infrastructure Lab

> A self-directed multi-site enterprise infrastructure lab spanning Active Directory, distributed DNS/DNSSEC, independent PKI trust domains, DFS, certificate-secured RemoteApp, site-to-site VPN, NAT/PAT, and PowerShell automation — designed, secured, tested, and documented like a real-world infrastructure engagement.

## Business Context

TKP is a fictional mid-sized organization operating across two sites: a Headquarters hosting core business operations and a Branch office connected through an upstream/ISP network. As the organization expanded, it required a centrally managed infrastructure capable of operating as a single domain across both locations while maintaining clear security boundaries between internal systems, the branch environment, and the external network.

This project was designed and implemented as an end-to-end infrastructure engagement rather than a collection of isolated service deployments. The architecture focuses on centralized identity, resilient name resolution, certificate-based trust, consolidated file access, controlled application publishing, secure inter-site connectivity, automation, and deliberate network security boundaries.

The objective was not simply to make individual services work, but to design an infrastructure where services, security controls, network connectivity, and operational requirements work together as a coherent system. Each major design decision is documented along with its implementation, validation, and troubleshooting process.

---

## Architecture Overview

The environment consists of two internal network areas connected through a central routing layer and a simulated upstream/ISP network.

The Headquarters environment contains the primary Active Directory infrastructure, internal DNS, Enterprise Root CA, IIS, DFS resources, and other core services.

The Branch environment contains an RODC, secondary DNS infrastructure, additional file resources, and RemoteApp services. The two sites are connected through a site-to-site L2TP/IPsec VPN between their edge routers.

The central router (`R-1`) provides routing between the network segments and does not host application services. NAT/PAT is implemented at the edge as part of the inter-site and upstream connectivity design.

The simulated ISP network represents an external trust boundary. Internal systems can reach and validate services hosted on the ISP segment, while the ISP host is prevented from initiating connectivity toward the internal networks.

### Network Topology

![Logical Network Topology](diagrams/logical-topology.png)

> Detailed network architecture, addressing, routing, and physical/logical topology are documented in [01-network-design.md](docs/01-network-design.md).

---

## Infrastructure Overview

| System | Network | IP Address | Primary Role |
|---|---|---:|---|
| **SRV-1** | LAN A | `10.10.10.1` | AD DS, Primary DNS, Enterprise Root CA, File Services |
| **SRV-2** | LAN A | `10.10.10.2` | Secondary DNS, IIS, FTP, DFS Namespace |
| **SRV-3** | LAN B | `20.20.20.1` | File Services, RDS / RemoteApp |
| **EDGE-1** | LAN A/B/C | `10.10.10.3` / `20.20.20.2` / `30.30.30.1` | Edge Routing, VPN, NAT/PAT |
| **R-1** | LAN C/D/E | `30.30.30.2` / `40.40.40.2` / `50.50.50.2` | Central Routing |
| **ISP** | LAN D | `40.40.40.1` | Simulated Upstream, DNS, IIS, Standalone Root CA |
| **EDGE-2** | LAN E/F | `50.50.50.1` / `60.60.60.3` | Branch Edge Routing, VPN |
| **SRV-01** | LAN F | `60.60.60.2` | RODC, Secondary DNS |
| **SRV-02** | LAN F | `60.60.60.1` | Client / Service Testing |

> Detailed addressing and interface information is available in [01-network-design.md](docs/01-network-design.md).

---

## Key Technologies

### Microsoft Infrastructure

- Active Directory Domain Services (AD DS)
- Read-Only Domain Controller (RODC)
- Active Directory-integrated DNS
- Primary and Secondary DNS
- DNSSEC
- Reverse Lookup Zones
- Conditional Forwarding
- Active Directory Certificate Services (AD CS)
- Enterprise Root CA
- Standalone Root CA
- Group Policy
- IIS
- HTTPS
- HTTP → HTTPS redirection
- FTP
- DFS Namespace
- Remote Desktop Services / RemoteApp
- PowerShell automation

### Network Infrastructure

- Multi-segment IPv4 routing
- Site-to-Site L2TP/IPsec VPN
- Pre-Shared Key (PSK)
- NAT/PAT
- Edge routing
- Central routing
- Upstream/ISP security boundary

---

## Engineering Highlights

### Centralized Identity

A single `TKP.local` Active Directory domain provides centralized identity and access management across both sites, with an RODC deployed at the Branch to reduce the security exposure of placing a writable Domain Controller in a remote location.

### Distributed DNS Architecture

DNS is designed as a distributed service using Primary, Secondary, and RODC-integrated DNS roles, with Forward and Reverse Lookup Zones, DNSSEC, and controlled external resolution through a Conditional Forwarder.

### Independent PKI Trust Domains

The environment deliberately uses two independent PKI trust domains:

- **Enterprise Root CA** on `SRV-1` for internal domain services.
- **Standalone Root CA** on `ISP` for the simulated external `www.google.com` service.

The ISP CA trust is distributed to domain-joined systems through Group Policy, allowing internal systems to establish trusted HTTPS connections to the simulated external service.

### Consolidated File Services

A DFS Namespace hosted on `SRV-2` provides a single logical access point for shared resources hosted across `SRV-1` and `SRV-3`, separating user access from the physical location of the underlying file shares.

### Certificate-Secured Remote Application

RemoteApp is deployed on `SRV-3` and used to publish Microsoft Paint as a lightweight application-publishing scenario, with certificate-based security and trust.

### Secure Inter-Site Connectivity

The Headquarters and Branch networks are connected through an L2TP/IPsec site-to-site VPN between `EDGE-1` and `EDGE-2`, using a pre-shared key and NAT/PAT as part of the edge connectivity design.

### Controlled Upstream Boundary

The simulated ISP network is treated as an untrusted external boundary:

```text
Internal Network  ───────►  ISP
       ALLOWED

ISP  ───────X──────►  Internal Network
             BLOCKED
```

This models a controlled boundary between enterprise infrastructure and an upstream network.

### Automation

Bulk Active Directory user provisioning is automated through CSV-driven PowerShell, allowing 100 uniquely attributed users to be created and enabled consistently without manual account-by-account configuration.

---

## Documentation

The repository is organized into focused technical documents, with each document covering a specific infrastructure domain.

| Document | Description |
|---|---|
| 01 — Network Design | Complete topology, LAN segments, IP addressing, routing, NAT/PAT, and logical/physical design |
| 02 — Active Directory | `TKP.local`, Domain Controllers, RODC, user provisioning, CSV structure, and shared folders |
| 03 — DNS Architecture | Primary/Secondary/RODC DNS, Forward/Reverse Zones, DNSSEC, Conditional Forwarding, and replication |
| 04 — PKI Design | Enterprise Root CA, Standalone Root CA, certificate trust, GPO distribution, and certificate usage |
| 05 — File Services | Shared folders, DFS Namespace, and validation from SRV-02 |
| 06 — Remote Access | RDS RemoteApp, application publishing, and certificate-based security |
| 07 — Site-to-Site VPN | L2TP/IPsec, PSK, NAT/PAT, and tunnel parameters |
| 08 — Security Controls | ISP isolation, firewall/ACL controls, and security validation |
| 09 — Troubleshooting | Real troubleshooting scenarios documented as Problem → Root Cause → Solution → Verification |
| 10 — Lessons Learned | Challenges, design reflections, improvements, and skills developed |

---

## Diagrams

The repository contains dedicated diagrams for the major infrastructure components:

- Logical Topology
- Physical Topology
- Active Directory Structure
- DNS Replication
- PKI Architecture
- VPN Tunnel

Editable `.drawio` source files are included where applicable.

---

## Automation & Scripts

The `scripts/` directory contains sanitized automation and verification scripts used during the project.

- `bulk-user-import.ps1` — PowerShell-based bulk AD user provisioning
- `sample-users.csv` — Fake/anonymized sample data
- `dns-zone-check.ps1` — Optional DNS verification script

No real credentials, passwords, PSKs, or other secrets are stored in the repository.

---

## Security & Privacy

This repository is designed for public portfolio and educational use.

All credentials, passwords, PSKs, certificates containing sensitive information, and other secrets have been excluded or sanitized.

Configuration examples contain only non-sensitive parameters and representative values.

The project is a fictional infrastructure environment and does not contain production credentials or real organizational data.

---

## Project Validation

The infrastructure is validated through practical testing across:

- [x] Network connectivity
- [x] Inter-site routing
- [x] VPN tunnel establishment
- [x] DNS resolution
- [x] DNSSEC validation
- [x] Forward and Reverse DNS resolution
- [x] Active Directory authentication
- [x] RODC functionality
- [x] Certificate trust
- [x] HTTPS access
- [x] HTTP → HTTPS redirection
- [x] DFS access
- [x] RemoteApp functionality
- [x] ISP boundary enforcement

Detailed validation results and troubleshooting scenarios are documented in the individual technical documents.

---

## Project Status

**Status:** Completed / Continuously documented

This repository represents a self-directed infrastructure engineering lab built to practice the design, implementation, security, troubleshooting, validation, and documentation of a multi-site Microsoft environment.

---

## Repository Structure

```text
tkp-local-infrastructure-lab/
├── README.md
├── LICENSE
├── .gitignore
│
├── docs/
│   ├── 01-network-design.md
│   ├── 02-active-directory.md
│   ├── 03-dns-architecture.md
│   ├── 04-pki-design.md
│   ├── 05-file-services.md
│   ├── 06-remote-access.md
│   ├── 07-site-to-site-vpn.md
│   ├── 08-security-controls.md
│   ├── 09-troubleshooting.md
│   └── 10-lessons-learned.md
│
├── diagrams/
│   ├── logical-topology.png
│   ├── logical-topology.drawio
│   ├── physical-topology.png
│   ├── ad-structure.png
│   ├── dns-replication.png
│   ├── pki-hierarchy.png
│   └── vpn-tunnel.png
│
├── screenshots/
│   ├── ad-users/
│   ├── dns-dnssec/
│   ├── pki-certificates/
│   ├── dfs/
│   ├── rds-remoteapp/
│   └── vpn-status/
│
├── scripts/
│   ├── bulk-user-import.ps1
│   ├── sample-users.csv
│   └── dns-zone-check.ps1
│
└── configs/
    ├── vpn-parameters.md
    └── dns-zone-samples.txt
```

---

## Disclaimer

This is a fictional, self-directed infrastructure lab created for learning, experimentation, technical documentation, and portfolio development.

The architecture is intentionally designed to simulate the types of requirements and constraints encountered in real-world enterprise infrastructure environments.
