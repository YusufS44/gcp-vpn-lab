# ══════════════════════════════════════════════════════════════════════════════
# OUTPUTS  — mirrors the gcloud list commands from the lab
# ══════════════════════════════════════════════════════════════════════════════

output "vpn_gateway_1" {
  description = "Name and self-link of VPN Gateway 1 (myvpn-1)"
  value = {
    name      = google_compute_vpn_gateway.vpn_gateway_1.name
    region    = google_compute_vpn_gateway.vpn_gateway_1.region
    network   = google_compute_vpn_gateway.vpn_gateway_1.network
    self_link = google_compute_vpn_gateway.vpn_gateway_1.self_link
  }
}

output "vpn_gateway_2" {
  description = "Name and self-link of VPN Gateway 2 (myvpn-2)"
  value = {
    name      = google_compute_vpn_gateway.vpn_gateway_2.name
    region    = google_compute_vpn_gateway.vpn_gateway_2.region
    network   = google_compute_vpn_gateway.vpn_gateway_2.network
    self_link = google_compute_vpn_gateway.vpn_gateway_2.self_link
  }
}

output "static_ip_gateway_1" {
  description = "External IP address assigned to VPN Gateway 1"
  value       = google_compute_address.vpn_static_ip_1.address
}

output "static_ip_gateway_2" {
  description = "External IP address assigned to VPN Gateway 2"
  value       = google_compute_address.vpn_static_ip_2.address
}

output "vpn_tunnel_1_to_2" {
  description = "Tunnel from Network 1 → Network 2"
  value = {
    name       = google_compute_vpn_tunnel.tunnel_1_to_2.name
    region     = google_compute_vpn_tunnel.tunnel_1_to_2.region
    peer_ip    = google_compute_vpn_tunnel.tunnel_1_to_2.peer_ip
    ike        = google_compute_vpn_tunnel.tunnel_1_to_2.ike_version
    self_link  = google_compute_vpn_tunnel.tunnel_1_to_2.self_link
  }
}

output "vpn_tunnel_2_to_1" {
  description = "Tunnel from Network 2 → Network 1"
  value = {
    name       = google_compute_vpn_tunnel.tunnel_2_to_1.name
    region     = google_compute_vpn_tunnel.tunnel_2_to_1.region
    peer_ip    = google_compute_vpn_tunnel.tunnel_2_to_1.peer_ip
    ike        = google_compute_vpn_tunnel.tunnel_2_to_1.ike_version
    self_link  = google_compute_vpn_tunnel.tunnel_2_to_1.self_link
  }
}

output "route_net1_to_net2" {
  description = "Static route: Network 1 → Network 2 via Tunnel 1"
  value = {
    name       = google_compute_route.route_1_to_2.name
    dest_range = google_compute_route.route_1_to_2.dest_range
  }
}

output "route_net2_to_net1" {
  description = "Static route: Network 2 → Network 1 via Tunnel 2"
  value = {
    name       = google_compute_route.route_2_to_1.name
    dest_range = google_compute_route.route_2_to_1.dest_range
  }
}
