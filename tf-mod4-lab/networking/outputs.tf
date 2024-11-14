output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_fe_id" {
  value = google_compute_subnetwork.subnet-fe.id
}

output "subnet_be_id" {
  value = google_compute_subnetwork.subnet-be.id
}

output "firewall-lb-1-id"{
  value = google_compute_firewall.firewall-lb-fe.id
}