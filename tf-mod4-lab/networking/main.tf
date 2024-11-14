resource "google_compute_network" "vpc" {
  name                    = "vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet-fe" {
  name          = "subnet-fe"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet-be" {
  name          = "subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "firewall-lb-fe" {
  project = var.project_name
  name    = "firewall-lb-fe"
  network = google_compute_network.vpc.id

  // need the network created before the firewall rule
  // I noticed sometimes terraform didn't detect the dependency, so making explicit.
  depends_on = [google_compute_network.vpc]

  allow {
    protocol = "tcp"
    ports = ["22", "80", "5000"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}
#
# resource "google_compute_firewall" "firewall-lb-be" {
#   project = var.project_name
#   name    = "firewall-lb-be"
#   network = google_compute_network.vpc.id
#
#   // need the network created before the firewall rule
#   // I noticed sometimes terraform didn't detect the dependency, so making explicit.
#   depends_on = [google_compute_network.vpc]
#
#   allow {
#     protocol = "tcp"
#     ports = ["80", "5000", "22"]
#   }
#   allow {
#     protocol = "icmp"
#   }
#   source_ranges = ["10.4.0.0/24"]
#   direction = "INGRESS"
#
#
# }
