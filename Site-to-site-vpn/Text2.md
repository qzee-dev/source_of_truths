markdown
# Hybrid Network Connectivity: Site-to-Site VPN & IPsec Integration Guide

Virtual Private Gateway is a bridge that connects your cloud network to your on-premises office.

## Core Networking Components

1. **Virtual Private Gateway (VGW):** This is the anchor point on the cloud side. It is a virtual router that AWS (or your cloud provider) attaches to your Virtual Private Cloud (VPC) to receive and process VPN traffic.
2. **Customer Gateway (CGW):** This represents the anchor point on your side. In reality, it is a physical firewall, router, or server sitting in your office or data center (like a Cisco ASA, Fortinet firewall, or a Linux server running StrongSwan). In the cloud console, you create a "Customer Gateway" object simply to tell the cloud your physical router's public IP address.

---

## Understanding IPsec Framework & Site-to-Site VPNs

A **Site-to-Site VPN** is the configuration that creates a secure connection between your Virtual Private Gateway (VGW) on the cloud side and your Customer Gateway (CGW) on the physical data center or office side.

**IPsec** is a framework of protocols and security processes integrated into a Site-to-Site VPN to make the connection secure. It is not a single algorithm. Instead, it is like a master security standard that bundles several different protocols and encryption algorithms together.

When you configure a Site-to-Site VPN, IPsec acts as the step-by-step process that negotiates keys, authenticates the two gateways, and encrypts the actual data traveling between them.

* **Confidentiality:** IPsec gives you Confidentiality: It hides the content of your message. Anyone watching the wire knows exactly who is talking to whom (because the IP headers are visible so routers can deliver the packet), but they have zero idea what you are saying.

### What is Inside the IPsec Framework?

To understand how it works inside a VPN, think of IPsec as a security team where different members have different jobs:

1. **The Handshake Protocol (IKE - Internet Key Exchange):**
   This is the process that starts the VPN connection. Before any data moves, the cloud gateway and your office router use IKE to introduce themselves, check pre-shared keys (passwords), and agree on which encryption rules they will use.
2. **The Encryption Protocols (ESP / AH):**
   Once the handshake is done, ESP (Encapsulating Security Payload) takes over. This is the protocol responsible for scrambling your data payload and wrapping it securely, as we discussed earlier.
3. **The Cryptographic Algorithms (The Tools):**
   IPsec uses specific math formulas (algorithms) to do the heavy lifting. When setting up your VPN, you choose which algorithms IPsec should use. Examples include:
   * **Encryption Algorithms:** AES-256 or AES-GCM (these actually scramble the data).
   * **Hashing/Integrity Algorithms:** SHA-256 or SHA-512 (these make sure no one alters the data in transit).

### The Analogy: A Secure Courier Service

If a Site-to-Site VPN is the contract to send private documents between two company offices over a public highway, IPsec is the specialized security protocol that dictates exactly how it must be done:
* IPsec says: *"We must use an armored truck (ESP)."*
* IPsec says: *"The guards at both buildings must verify each other's ID cards before opening the gates (IKE Handshake)."*
* IPsec says: *"The lock on the briefcase must use a 3-dial combination lock (AES Algorithm)."*

### Summary

You cannot have a standard enterprise Site-to-Site VPN without IPsec. Site-to-Site VPN is the concept (connecting two networks over the internet), and IPsec is the engine (the suite of protocols, processes, and math algorithms) that makes that connection private and secure.

When setting up a Site-to-Site VPN, you have to choose between IKEv1 and IKEv2 (the two versions of the IPsec handshake process). Do you want to know the difference between them, or are you ready to look at how to map out your network subnets for the VPN?

---

## On-Premises Configuration Strategies

No, you cannot use a standard cloud provider (like provider "aws") to configure your physical on-premises router.

Terraform can easily configure the cloud side (the Customer Gateway, VPN Connection, and Virtual Private Gateway) because AWS/Azure expose public APIs to handle those changes. However, standard cloud providers have no access or permission to log into your physical, on-premises router sitting inside your local server room or office.

To configure the on-premises side, you have two choices:
1. **The Automation Route:** Use a dedicated on-prem network provider in Terraform (if your physical router brand supports it) or configuration management tools like Ansible.
2. **The Traditional Route (Highly Recommended):** Define the cloud side in Terraform, export the configuration details, and apply them to your router manually or via local scripts.

Here is exactly how both methods work and how to set them up.

### Method 1: The Automation Route (Using Terraform + Ansible)

If you want a fully automated pipeline, you use Terraform to build the cloud infrastructure and output the VPN keys, then pass those keys to a tool designed for network hardware configuration like Ansible.

#### Step A: Write the Terraform Cloud Infrastructure
This block sets up the cloud side and outputs the configuration data (like Pre-Shared Keys and Tunnel IPs) that your on-premises router desperately needs.

```hcl
# 1. Define the Cloud Side Placeholder for your Router
resource "aws_customer_gateway" "on_prem_router" {
  bgp_asn    = 65000
  ip_address = "203.0.113.10" # Your physical on-prem public IP
  type       = "ipsec.1"
}

# 2. Create the Virtual Private Gateway on AWS Side
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.main.id
}

# 3. Create the VPN Connection (The IPSec Tunnel details)
resource "aws_vpn_connection" "site_to_site" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.on_prem_router.id
  type                = "ipsec.1"
  static_routes_only  = true
}

# 4. EXPORT the keys so your on-prem automation can read them
output "vpn_tunnel1_address" {
  value = aws_vpn_connection.site_to_site.tunnel1_address
}
output "vpn_tunnel1_preshared_key" {
  value     = aws_vpn_connection.site_to_site.tunnel1_preshared_key
  sensitive = true
}
```

#### Step B: Use Ansible to Push IPSec Configuration On-Premises
Once Terraform prints out the `tunnel1_address` and `tunnel1_preshared_key`, an automation script runs an Ansible playbook to log into your on-prem device over SSH and apply the IPSec settings.

```yaml
# Example playbook snippet targeting an on-prem Cisco router
- name: Configure On-Premises IPSec Tunnel
  hosts: cisco_routers
  tasks:
    - name: Set up Crypto Isakmp Policy (Phase 1)
      cisco.ios.ios_config:
        lines:
          - crypto isakmp policy 10
          - encr aes 256
          - hash sha256
          - authentication pre-share
          - group 14
          - crypto isakmp key {{ vpn_tunnel1_preshared_key }} address {{ vpn_tunnel1_address }}
```

### Method 2: The Traditional Route (Download & Apply)

If you do not have complex automation tools set up for your local network hardware, follow these manual steps to bridge the gap:
1. **Run your Terraform code:** Apply the code from Step A above.
2. **Download the Device Configuration:** Go into your Cloud Console (e.g., AWS VPC Dashboard -> Site-to-Site VPN Connections). Select your VPN connection and click *Download Configuration*.
3. **Select your Vendor:** Choose your specific on-prem router model (e.g., Cisco, Fortinet, Palo Alto).
4. **Apply Configuration:** The downloaded file will contain step-by-step CLI commands or GUI instructions specifically formatted for your router brand. Paste these commands into your on-premises configuration terminal.

### Critical Parameters You Must Sync

Regardless of the method you choose, your on-prem configuration must mirror the cloud parameters perfectly, or Phase 1 or Phase 2 of the IPSec handshake will fail:
* **IKE Version:** Must match (usually IKEv2 is preferred).
* **Encryption/Hashing:** (e.g., AES-256 and SHA-256 on both sides).
* **Diffie-Hellman (DH) Group:** (e.g., Group 14 or Group 2).
* **Pre-Shared Key (PSK):** The long random text string generated by the cloud must match your local router's crypto key entry exactly.

What specific brand and model of router or firewall are you running on-premises (e.g., Cisco ISR, FortiGate, pfSense, Palo Alto)? I can give you the exact structural commands or configuration layout required for that specific device.

---

## End-to-End Implementation Guide

To achieve this complete end-to-end setup, you must configure security policies and routing tables on both sides (AWS and On-Premises). Below is the definitive, step-by-step implementation guide using a mix of Terraform for the AWS side and standard Network Administration principles for your on-premises router/firewall.

### Step 1: Allow UDP 500, UDP 4500, and ESP (Protocol 50)

These protocols are required for the IPSec VPN negotiation (IKE, NAT-Traversal, and Encapsulating Security Payload).

#### 🛠️ AWS Side (Terraform)
You must allow these protocols through your AWS Security Groups or Network ACLs (NACLs) facing the public internet, but more importantly, you must ensure your AWS VPC Route Tables point to the Virtual Private Gateway (vgw).

AWS automatically handles the acceptance of these protocols on its managed VPN endpoints (VGW/Transit Gateway), so you don’t need to explicitly open ports 500/4500 on an AWS firewall for the VPN connection itself.

#### 🏢 On-Premises Side (Router/Firewall CLI)
Use code with caution.
You must create an inbound access control list (ACL) on your public-facing interface to allow traffic from the AWS Tunnel Outside IP addresses (which Terraform outputs when you create the VPN connection).
```bash

Example Cisco ASA / Router configuration syntax:

access-list OUTSIDE-IN permit udp host <AWS_TUNNEL_IP> host <ON_PREM_PUBLIC_IP> eq 500
access-list OUTSIDE-IN permit udp host <AWS_TUNNEL_IP> host <ON_PREM_PUBLIC_IP> eq 4500
access-list OUTSIDE-IN permit esp host <AWS_TUNNEL_IP> host <ON_PREM_PUBLIC_IP>
```

Step 2: Configure Routing (Both Sides)

Traffic needs to know how to find the opposing network.

🏢 Add Route from On-Prem CIDR to AWS VPC CIDR (On-Premises Side)

On your physical router, add a static route pointing all AWS-bound traffic into the virtual tunnel interface (VTI) you created.
```bash

Syntax: ip route <AWS_VPC_CIDR> <Subnet_Mask> <Tunnel_Interface>

ip route 10.0.0.0 255.255.0.0 Tunnel1
```

🛠️ Add Route from AWS VPC CIDR to On-Prem CIDR (AWS Side - Terraform)

In Terraform, you can achieve this easily using Route Propagation. This tells the AWS Route Table to automatically learn your on-premises networks from the VPN gateway.
```hcl

Enable Route Propagation on your AWS Private Route Table

resource "aws_route_table_association" "private_prop" {
route_table_id = aws_route_table.private.id
subnet_id      = aws_subnet.dms_subnet.id
}
resource "aws_vpn_gateway_route_propagation" "on_prem_prop" {
vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
route_table_id = aws_route_table.private.id
}
```

Step 3: Validate Tunnel UP & IPSec SA Status

Once configurations are applied, you must verify the crypto handshake is successful.

🏢 On-Premises Verification

Run these standard diagnostic commands on your local router to check the Phase 1 (ISAKMP) and Phase 2 (IPSec) Security Associations (SA):
bash show crypto isakmp sa    # Should show status: QM_IDLE (Active) show crypto ipsec sa     # Look for "pkts encaps" and "pkts decaps" increments > 0 

🛠️ AWS Verification

You can check this directly via the AWS CLI or console. In Terraform, you can output the tunnel status monitoring flags:
```bash

AWS CLI Verification Command

aws ec2 describe-vpn-connections --vpn-connection-ids vpn-xxxxxxxxxxxxx --query "VpnConnections[*].VgwTelemetry"
```
(Status should read "UP" for at least one of the two tunnels).

Step 4: Network Isolation & Access Validation (DMS & RDS)

Now you must restrict traffic inside AWS using Security Groups to ensure strict traffic isolation between DMS, RDS, and your On-Premises Source Database.

🛡️ AWS Side Network Rules (Terraform)

```hcl

1. DMS Security Group: Can reach On-Prem Source DB over VPN

resource "aws_security_group" "dms_sg" {
name        = "dms-migration-sg"
vpc_id      = aws_vpc.main.id

Egress: Allow DMS to talk to On-Prem Database (e.g., Oracle/SQL Server/Postgres ports)

egress {
from_port   = 5432 # Change to your DB port (e.g., 1521 for Oracle, 1433 for MSSQL)
to_port     = 5432
protocol    = "tcp"
cidr_blocks = ["192.168.1.0/24"] # Your On-Premises Source DB Subnet CIDR
}
}

2. RDS Security Group: Can reach DMS and App Tiers ONLY

resource "aws_security_group" "rds_sg" {
name        = "rds-production-sg"
vpc_id      = aws_vpc.main.id

Ingress: Allow inbound from DMS Security Group

ingress {
from_port       = 5432
to_port         = 5432
protocol        = "tcp"
security_groups = [aws_security_group.dms_sg.id]
}

Ingress: Allow inbound from App Tier Security Group

ingress {
from_port       = 5432
to_port         = 5432
protocol        = "tcp"
security_groups = [aws_security_group.app_tier_sg.id] # Your App Instance SG
}

Explicitly drops all traffic from On-Premises CIDRs by omission

}
```

🧪 Final Validation Tests

To confirm these paths are routing securely, execute these troubleshooting connectivity tests:
1. DMS to On-Prem: Provision a temporary test EC2 instance inside the DMS Subnet attached to the dms_sg. Attempt to ping or open a netcat connection (nc -zv <OnPrem_DB_IP> <Port>) to the on-prem database. It should connect successfully.
2. RDS Isolation Check: Attempt a network connection from your On-Premises environment directly to the RDS Private IP. It must time out because the RDS security group has no rules allowing your on-prem CIDR blocks.
What specific Database engine and port (e.g., PostgreSQL on 5432, Oracle on 1521) are you migrating from on-prem to RDS? I can help adjust the exact security group configurations to match your actual database traffic.

<FollowUp>
If you want to append specific vendor instructions or exact firewall security parameters to this repository guide, let me know:
* Your **on-premises firewall/router brand** (e.g., FortiGate, Cisco ASA, Palo Alto)
* The **target database engine** you are migrating (e.g., PostgreSQL, Oracle, MSSQL)
</FollowUp>
