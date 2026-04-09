terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.45.2"
    }
  }
}

provider "google" {
  project = var.project_id
}

# ══════════════════════════════════════════════════════════════════════════════
# VPC NETWORKS & SUBNETS
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_network" "network1" {
  name                    = var.network1_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet1" {
  name          = var.subnet1_name
  network       = google_compute_network.network1.id
  region        = var.region1
  ip_cidr_range = var.subnet1_cidr
}

resource "google_compute_network" "network2" {
  name                    = var.network2_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet2" {
  name          = var.subnet2_name
  network       = google_compute_network.network2.id
  region        = var.region2
  ip_cidr_range = var.subnet2_cidr
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1 — CREATE VPN GATEWAYS (Classic)
# Equivalent: gcloud compute target-vpn-gateways create ...
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_vpn_gateway" "vpn_gateway_1" {
  name    = "myvpn-1"
  network = google_compute_network.network1.id
  region  = var.region1
}

resource "google_compute_vpn_gateway" "vpn_gateway_2" {
  name    = "myvpn-2"
  network = google_compute_network.network2.id
  region  = var.region2
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2 — CREATE STATIC EXTERNAL IP ADDRESSES
# Equivalent: gcloud compute addresses create ...
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_address" "vpn_static_ip_1" {
  name   = "vpn-static-ip-1"
  region = var.region1
}

resource "google_compute_address" "vpn_static_ip_2" {
  name   = "vpn-static-ip-2"
  region = var.region2
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3 — FORWARDING RULES
# Three rules per gateway: ESP, UDP/500, UDP/4500
# Equivalent: gcloud compute forwarding-rules create ...
# ══════════════════════════════════════════════════════════════════════════════

# ─── Gateway 1 Forwarding Rules ───────────────────────────────────────────────

# ESP (Encapsulating Security Payload) — protocol 50
resource "google_compute_forwarding_rule" "fr_esp_1" {
  name        = "fr-esp-gw1"
  region      = var.region1
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip_1.address
  target      = google_compute_vpn_gateway.vpn_gateway_1.id
}

# IKE key exchange — UDP 500
resource "google_compute_forwarding_rule" "fr_udp500_1" {
  name        = "fr-udp500-gw1"
  region      = var.region1
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip_1.address
  target      = google_compute_vpn_gateway.vpn_gateway_1.id
}

# NAT traversal — UDP 4500
resource "google_compute_forwarding_rule" "fr_udp4500_1" {
  name        = "fr-udp4500-gw1"
  region      = var.region1
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip_1.address
  target      = google_compute_vpn_gateway.vpn_gateway_1.id
}

# ─── Gateway 2 Forwarding Rules ───────────────────────────────────────────────

resource "google_compute_forwarding_rule" "fr_esp_2" {
  name        = "fr-esp-gw2"
  region      = var.region2
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip_2.address
  target      = google_compute_vpn_gateway.vpn_gateway_2.id
}

resource "google_compute_forwarding_rule" "fr_udp500_2" {
  name        = "fr-udp500-gw2"
  region      = var.region2
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip_2.address
  target      = google_compute_vpn_gateway.vpn_gateway_2.id
}

resource "google_compute_forwarding_rule" "fr_udp4500_2" {
  name        = "fr-udp4500-gw2"
  region      = var.region2
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip_2.address
  target      = google_compute_vpn_gateway.vpn_gateway_2.id
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4 — VPN TUNNELS (bidirectional)
# Equivalent: gcloud compute vpn-tunnels create ...
# IKEv2, shared secret, full traffic selectors (0.0.0.0/0)
# ══════════════════════════════════════════════════════════════════════════════

# Tunnel: Network 1 → Network 2
# peer-address = static IP of Gateway 2
resource "google_compute_vpn_tunnel" "tunnel_1_to_2" {
  name                    = "tunnel-gw1-to-gw2"
  region                  = var.region1
  peer_ip                 = google_compute_address.vpn_static_ip_2.address
  shared_secret           = var.shared_secret
  ike_version             = 2
  target_vpn_gateway      = google_compute_vpn_gateway.vpn_gateway_1.id
  local_traffic_selector  = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]

  # Forwarding rules must exist before tunnels can be created
  depends_on = [
    google_compute_forwarding_rule.fr_esp_1,
    google_compute_forwarding_rule.fr_udp500_1,
    google_compute_forwarding_rule.fr_udp4500_1,
  ]
}

# Tunnel: Network 2 → Network 1
# peer-address = static IP of Gateway 1
resource "google_compute_vpn_tunnel" "tunnel_2_to_1" {
  name                    = "tunnel-gw2-to-gw1"
  region                  = var.region2
  peer_ip                 = google_compute_address.vpn_static_ip_1.address
  shared_secret           = var.shared_secret
  ike_version             = 2
  target_vpn_gateway      = google_compute_vpn_gateway.vpn_gateway_2.id
  local_traffic_selector  = ["0.0.0.0/0"]
  remote_traffic_selector = ["0.0.0.0/0"]

  depends_on = [
    google_compute_forwarding_rule.fr_esp_2,
    google_compute_forwarding_rule.fr_udp500_2,
    google_compute_forwarding_rule.fr_udp4500_2,
  ]
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5 — STATIC ROUTES
# Routes traffic between networks through the VPN tunnels
# Equivalent: gcloud compute routes create ...
# ══════════════════════════════════════════════════════════════════════════════

# Route: Network 1 → Network 2's CIDR via Tunnel 1
resource "google_compute_route" "route_1_to_2" {
  name                = "route-net1-to-net2"
  network             = google_compute_network.network1.id
  dest_range          = var.subnet2_cidr           # destination = Network 2 subnet
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel_1_to_2.id
  priority            = 1000
}

# Route: Network 2 → Network 1's CIDR via Tunnel 2
resource "google_compute_route" "route_2_to_1" {
  name                = "route-net2-to-net1"
  network             = google_compute_network.network2.id
  dest_range          = var.subnet1_cidr           # destination = Network 1 subnet
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel_2_to_1.id
  priority            = 1000
}

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL — FIREWALL RULES
# Allow ICMP & SSH across the tunnel so you can test connectivity
# ══════════════════════════════════════════════════════════════════════════════

resource "google_compute_firewall" "allow_internal_net1" {
  name    = "allow-internal-net1"
  network = google_compute_network.network1.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.subnet2_cidr]
}

resource "google_compute_firewall" "allow_internal_net2" {
  name    = "allow-internal-net2"
  network = google_compute_network.network2.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.subnet1_cidr]
}
