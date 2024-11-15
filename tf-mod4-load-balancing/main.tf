terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.51.0"
    }
  }
}


// Note: If you need to reference the outputs (assigned values)
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork#id
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network#id


// Create the VPC1

resource "google_compute_network" "tf-mod4-lab-network1" {
  name = "tf-mod4-lab-network1"
  auto_create_subnetworks = "false"
}
// Create the V
// Create the subnet2
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork

resource "google_compute_subnetwork" "tf-mod4-lab-subnet1" {
  name          = "tf-mod4-lab-subnet1"
  ip_cidr_range = "10.2.0.0/24"
  region        = "europe-west1"
  network       = google_compute_network.tf-mod4-lab-network1.id

}



// Create Firewall rule - allow icmp, tcp:22 (ssh), and tcp:1234 (custom)
//https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "tf-mod4-lab-fwrule1" {
  project = "onyx-outpost-438905-q4"
  name        = "tf-mod4-lab-fwrule1"
  network     = "tf-mod4-lab-network1"
  // need the network created before the firewall rule
  // I noticed sometimes terraform didn't detect the dependency, so making explicit.
  depends_on = [google_compute_network.tf-mod4-lab-network1,
    google_compute_network.tf-mod4-lab-network1,

  ]

  allow {
    protocol  = "tcp"
    ports     = ["22", "1234"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}


// Create a VM1, and put it inside of subnet1
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "tf-mod4-lab-vm1" {
  name         = "tf-mod4-lab-vm1"
  machine_type = "e2-micro"
  zone         = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod4-lab-network1, google_compute_subnetwork.tf-mod4-lab-subnet1]
  network_interface {
    // This indicates to give a public IP address

    network    = "tf-mod4-lab-network1"
    subnetwork = "tf-mod4-lab-subnet1"
  }

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = "sudo apt-get update && sudo apt-get install -y git"

  }
}

// Create a VM2, and put it inside of subnet1
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "tf-mod4-lab-vm2" {
  name = "tf-mod4-lab-vm2"
  machine_type = "e2-micro"
  zone = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod4-lab-network1, google_compute_subnetwork.tf-mod4-lab-subnet1]
  network_interface {
    // This indicates to give a public IP address

    network = "tf-mod4-lab-network1"
    subnetwork = "tf-mod4-lab-subnet1"
  }

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
     startup-script = "sudo apt-get update && sudo apt-get install -y git"
  }

}

# Instance-Group with the vms

resource "google_compute_instance_group" "tf-mod4-instance-group" {
  name        = "tf-mod4-instance-group"
  description = "Terraform test instance group"
  zone        = "europe-west1-c"
  network     = google_compute_network.tf-mod4-lab-network1.id

  instances = [google_compute_instance.tf-mod4-lab-vm1.id, google_compute_instance.tf-mod4-lab-vm2.id]
  depends_on = [google_compute_instance.tf-mod4-lab-vm1, google_compute_instance.tf-mod4-lab-vm2]
  named_port {
    name = "app-http"
    port = 5000
  }

}

resource "google_compute_region_health_check" "default" {
  depends_on = [google_compute_firewall.tf-mod4-lab-fwrule1]
  provider = google

  region = "europe-west1"
  name   = "website-hc"
  http_health_check {
    port = 5000
    request_path = "/health"
  }

}

# ProxySubnet for LB
resource "google_compute_region_backend_service" "default" {
  provider = google

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_instance_group.tf-mod4-instance-group.id
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }


  region      = "europe-west1"
  name        = "website-backend"
  protocol    = "HTTP"
  timeout_sec = 10
  port_name = "app-http"
  health_checks = [google_compute_region_health_check.default.id]
}


resource "google_compute_region_url_map" "default" {
  provider = google

  region          = "europe-west1"
  name            = "website-map"
  default_service = google_compute_region_backend_service.default.id
}


resource "google_compute_region_target_http_proxy" "default" {
  provider = google

  region  = "europe-west1"
  name    = "website-proxy"
  url_map = google_compute_region_url_map.default.id
}


resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "tf-ilb-proxy-subnet"
  provider      = google
  ip_cidr_range = "10.0.3.0/24"
  region        = "europe-west1"
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = google_compute_network.tf-mod4-lab-network1.id
}


resource "google_compute_address" "x-addr" {
  name = "website-ip-1"
  provider = google
  region = "europe-west1"
  network_tier = "STANDARD"

}

resource "google_compute_forwarding_rule" "tf-mod4-xlb" {
  provider = google
  depends_on = [google_compute_subnetwork.proxy_subnet]
  name   = "website-forwarding-rule"
  region = "europe-west1"

  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.default.id
  network               = google_compute_network.tf-mod4-lab-network1.id
  ip_address            = google_compute_address.x-addr.address
  network_tier          = "STANDARD"
}

//terraform show -json | jq

// If you see something like this:
// │ Error: Error creating instance: googleapi: Error 400: Invalid value for field 'resource.networkInterfaces[0].subnetwork': 'projects/orbital-linker-398719/regions/us-central1/subnetworks/xlb-proxy-ilb-pass-trough-subnet1'. The referenced subnetwork resource cannot be found., invalid
// There's a dependency that terraform didn't resolve, so it's trying to create X which depends on Y existing.
// To solve, use depends_on
