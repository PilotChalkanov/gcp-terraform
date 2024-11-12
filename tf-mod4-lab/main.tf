// Forwarding rule for Regional External Load Balancing
resource "google_compute_forwarding_rule" "default" {
  provider = google
  depends_on = [google_compute_subnetwork.proxy]
  name     = "website-forwarding-rule"
  region   = "europe-west1"

  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.default.id
  network               = google_compute_network.default.id
  ip_address            = google_compute_address.default.address
  network_tier          = "STANDARD"
}

resource "google_compute_region_target_http_proxy" "default" {
  provider = google

  region  = "europe-west1"
  name    = "website-proxy"
  url_map = google_compute_region_url_map.default.id
}

resource "google_compute_region_url_map" "default" {
  provider = google

  region          = "europe-west1"
  name            = "website-map"
  default_service = google_compute_region_backend_service.default.id
}

resource "google_compute_region_backend_service" "default" {
  provider = google

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group           = google_compute_region_instance_group_manager.rigm.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  region      = "europe-west1"
  name        = "website-backend"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_region_health_check.default.id]
}

data "google_compute_image" "debian_image" {
  provider = google
  family   = "debian-11"
  project  = "debian-cloud"
}

resource "google_compute_region_instance_group_manager" "rigm" {
  provider = google
  region   = "europe-west1"
  name     = "website-rigm"
  version {
    instance_template = google_compute_instance_template.instance_template.id
    name              = "primary"
  }



  base_instance_name = "internal-glb"
  target_size        = 2
}

resource "google_compute_instance_template" "instance_template" {
  provider     = google
  name         = "template-website-backend"
  machine_type = "e2-micro"

  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id

    access_config {
      network_tier = "STANDART"
    }
  }

  disk {
    source_image = data.google_compute_image.debian_image.self_link
    auto_delete  = true
    boot         = true
  }

  metadata = {
    startup-script = <<-EOF1
      #! /bin/bash
      set -euo pipefail

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y jq git  # Install jq and git only

      NAME=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/hostname")
      IP=$(curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip")
      METADATA=$(curl -f -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/?recursive=True" | jq 'del(.["startup-script"])')

      # Clone the repository into /opt/repo (replace with your repo URL)
      git clone https://github.com/eric-keller/npp-cloud

      cat <<EOF > /opt/repo/metadata.html
      <pre>
      Name: $NAME
      IP: $IP
      Metadata: $METADATA
      </pre>
      EOF
    EOF1

  }

  tags = ["allow-ssh", "load-balanced-backend"]
}

resource "google_compute_region_health_check" "default" {
  depends_on = [google_compute_firewall.fw4]
  provider = google

  region = "europe-west1"
  name   = "website-hc"
  http_health_check {
    port_specification = "USE_SERVING_PORT"
  }
}

resource "google_compute_address" "default" {
  name         = "website-ip-1"
  provider     = google
  region       = "europe-west1"
  network_tier = "STANDARD"
}

resource "google_compute_firewall" "fw1" {
  provider = google
  name     = "website-fw-1"
  network  = google_compute_network.default.id
  source_ranges = ["10.1.2.0/24"]
  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  direction = "INGRESS"
}

resource "google_compute_firewall" "fw2" {
  depends_on = [google_compute_firewall.fw1]
  provider = google
  name     = "website-fw-2"
  network  = google_compute_network.default.id
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = ["allow-ssh"]
  direction = "INGRESS"
}

resource "google_compute_firewall" "fw3" {
  depends_on = [google_compute_firewall.fw2]
  provider = google
  name     = "website-fw-3"
  network  = google_compute_network.default.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["load-balanced-backend"]
  direction = "INGRESS"
}

resource "google_compute_firewall" "fw4" {
  depends_on = [google_compute_firewall.fw3]
  provider = google
  name     = "website-fw-4"
  network  = google_compute_network.default.id
  source_ranges = ["10.129.0.0/26"]
  target_tags = ["load-balanced-backend"]
  allow {
    protocol = "tcp"
    ports = ["80"]
  }
  allow {
    protocol = "tcp"
    ports = ["443"]
  }
  allow {
    protocol = "tcp"
    ports = ["8000"]
  }
  direction = "INGRESS"
}

resource "google_compute_firewall" "fw5" {
  name        = "fw5-ingress"
  network     = google_compute_network.default.id

  // Ensure the network is created before this firewall rule
  depends_on = [google_compute_network.default]

  allow {
    protocol  = "tcp"
    ports     = ["80"]  // Allow HTTP (port 80)
  }

  source_ranges = ["0.0.0.0/0"]  // Allow inbound traffic from anywhere
}



resource "google_compute_network" "default" {
  provider                = google
  name                    = "website-net"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "default" {
  provider      = google
  name          = "website-net-default"
  ip_cidr_range = "10.1.2.0/24"
  region        = "europe-west1"
  network       = google_compute_network.default.id
}

resource "google_compute_subnetwork" "proxy" {
  provider      = google
  name          = "website-net-proxy"
  ip_cidr_range = "10.129.0.0/26"
  region        = "europe-west1"
  network       = google_compute_network.default.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}