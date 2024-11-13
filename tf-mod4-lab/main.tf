terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = "vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = "10.0.3.0/24"
  region        = "europe-west1"
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "firewall-lb-1" {
  project = "onyx-outpost-438905-q4"
  name    = "firewall-lb-1"
  network = "vpc"
  // need the network created before the firewall rule
  // I noticed sometimes terraform didn't detect the dependency, so making explicit.
  depends_on = [google_compute_network.vpc]

  allow {
    protocol = "tcp"
    ports = ["22", "1234", "5000"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}


# frontend vms
resource "google_compute_instance" "fe-vm1" {
  name         = "fe-vm1"
  machine_type = "e2-micro"
  zone         = "europe-west1-c"
  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }


  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = <<-EOF
    sudo apt-get update && \
    sudo apt-get install -y git && \
    sudo git clone https://github.com/PilotChalkanov/gcp-terraform.git && \
    sudo apt-get install -y python3-flask && \
    python3 gcp-terraform/tf-mod4-lab/backend/frontend-app.py
  EOF
  }

}

resource "google_compute_instance" "fe-vm2" {
  name         = "fe-vm2"
  machine_type = "e2-micro"
  zone         = "europe-west1-c"
  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }


  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = <<-EOF
    sudo apt-get update && \
    sudo apt-get install -y git && \
    sudo git clone https://github.com/PilotChalkanov/gcp-terraform.git && \
    sudo apt-get install -y python3-flask &&\
    python3 gcp-terraform/tf-mod4-lab/backend/frontend-app.py
  EOF
  }

}

# frontend instance group

resource "google_compute_instance_group" "fe-group" {
  name = "fe-group"
  instances = [
    google_compute_instance.fe-vm1.id,
    google_compute_instance.fe-vm2.id
  ]
  named_port {
    name = "fe-http"
    port = 5000

  }
  zone = "europe-west1-c"
}


# backend vms
resource "google_compute_instance" "be-vm1" {
  name         = "be-vm1"
  machine_type = "e2-micro"
  zone         = "europe-west1-c"
  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }


  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = <<-EOF
    sudo apt-get update && \
    sudo apt-get install -y git && \
    sudo git clone https://github.com/PilotChalkanov/gcp-terraform.git && \
    sudo apt-get install -y python3-flask && \
    python3 gcp-terraform/tf-mod4-lab/backend/backend-app.py
  EOF
  }

}

resource "google_compute_instance" "be-vm2" {
  name         = "be-vm2"
  machine_type = "e2-micro"
  zone         = "europe-west1-c"
  depends_on = [google_compute_network.vpc, google_compute_subnetwork.subnet]
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }


  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = <<-EOF
    sudo apt-get update && \
    sudo apt-get install -y git && \
    sudo git clone https://github.com/PilotChalkanov/gcp-terraform.git && \
    sudo apt-get install -y python3-flask\
    python3 gcp-terraform/tf-mod4-lab/backend/backend-app.py
  EOF
  }

}

# backend instance group

resource "google_compute_instance_group" "be-group" {
  name = "be-group"
  instances = [
    google_compute_instance.be-vm1.id,
    google_compute_instance.be-vm2.id
  ]
  named_port {
    name = "be-http"
    port = 5000

  }
  zone = "europe-west1-c"
}

resource "google_compute_region_url_map" "url-xlb" {
  provider = google
  region          = "europe-west1"
  name            = "url-xlb"
  default_service = google_compute_region_backend_service.website-fe.id

}

resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "l7-ilb-proxy-subnet"
  provider      = google
  ip_cidr_range = "10.4.0.0/24"
  region        = "europe-west1"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = google_compute_network.vpc.id
}


resource "google_compute_region_backend_service" "website-fe" {
  provider = google

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 0.8
    group = google_compute_instance_group.fe-group.id
  }

  region      = "europe-west1"
  name        = "website-fe"
  protocol    = "HTTP"
  timeout_sec = 10

  port_name = "fe-http"

  health_checks = [google_compute_region_health_check.fe-hc.id]
}

resource "google_compute_region_health_check" "fe-hc" {
  provider           = google
  name               = "fe-hc"
  check_interval_sec = 1
  timeout_sec        = 1
  region             = "europe-west1"



  http_health_check {
    port         = "5000"
    request_path = "/health"

  }
}
// Forwarding rule for External Network Load Balancing using Backend Services
resource "google_compute_forwarding_rule" "fwd-rule-fe" {
  provider              = google
  name                  = "fwd-rule-fe"
  region                = "europe-west1"
  ip_protocol = "HTTP"
  port_range            = 80
  depends_on = [google_compute_subnetwork.proxy_subnet]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.http-proxy-fe.id
  network               = google_compute_network.vpc.id
}

resource "google_compute_region_target_http_proxy" "http-proxy-fe" {
  name     = "http-proxy-fe"
  provider = google
  region   = "europe-west1"
  url_map  = google_compute_region_url_map.url-xlb.id
}