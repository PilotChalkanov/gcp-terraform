output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.subnet.id
}

output "firewall-lb-1-id"{
  value = google_compute_firewall.firewall-lb-1.id
}