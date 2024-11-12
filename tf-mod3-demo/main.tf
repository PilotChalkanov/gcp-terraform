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

resource "google_compute_network" "tf-mod3-demo-network1" {
  name = "tf-mod3-demo-network1"
  auto_create_subnetworks = "false"
}
// Create the VPC1
resource "google_compute_network" "tf-mod3-demo-network2" {
  name = "tf-mod3-demo-network2"
  auto_create_subnetworks = "false"
}

// Create the subnet2
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork

resource "google_compute_subnetwork" "tf-mod3-demo-subnet1" {
  name          = "tf-mod3-demo-subnet1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west1"
  network       = google_compute_network.tf-mod3-demo-network1.id

}

resource "google_compute_subnetwork" "tf-mod3-demo-subnet2" {
  name          = "tf-mod3-demo-subnet2"
  ip_cidr_range = "10.0.2.0/24"
  region        = "europe-west1"
  network       = google_compute_network.tf-mod3-demo-network2.id

}

# Router

resource "google_compute_router" "tf-router-vpc1" {
  name    = "router-vpc1"
  network = google_compute_network.tf-mod3-demo-network1.id
  region = google_compute_subnetwork.tf-mod3-demo-subnet1.region

  bgp {
    asn=64514
    keepalive_interval = 20
  }
}

# NAT gateway rtr

resource "google_compute_router_nat" "tf-nat-gw-vpc1" {
  name = "nat-vpc1"
  router = "router-vpc1"
  region = google_compute_subnetwork.tf-mod3-demo-subnet1.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}


// Create Firewall rule - allow icmp, tcp:22 (ssh), and tcp:1234 (custom)
//https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "tf-mod3-demo-fwrule1" {
  project = "onyx-outpost-438905-q4"
  name        = "tf-mod3-demo-fwrule1"
  network     = "tf-mod3-demo-network1"
  // need the network created before the firewall rule
  // I noticed sometimes terraform didn't detect the dependency, so making explicit.
  depends_on = [google_compute_network.tf-mod3-demo-network1,
    google_compute_network.tf-mod3-demo-network2,

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

resource "google_compute_firewall" "tf-mod3-demo-fwrule2" {
  project = "onyx-outpost-438905-q4"
  name        = "tf-mod3-demo-fwrule2"
  network     = "tf-mod3-demo-network2"
  // need the network created before the firewall rule
  // I noticed sometimes terraform didn't detect the dependency, so making explicit.
  depends_on  = [google_compute_network.tf-mod3-demo-network1,
    google_compute_network.tf-mod3-demo-network2,

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

# VPC Peerings

resource "google_compute_network_peering" "peer-1-to-2" {
  name = "peer-1-to-2"
  network = google_compute_network.tf-mod3-demo-network1.self_link
  peer_network = google_compute_network.tf-mod3-demo-network2.self_link
  depends_on  = [google_compute_network.tf-mod3-demo-network1,
    google_compute_network.tf-mod3-demo-network2,
    google_compute_subnetwork.tf-mod3-demo-subnet1,
    google_compute_subnetwork.tf-mod3-demo-subnet2,
  ]
}

resource "google_compute_network_peering" "peer-2-to-1" {
  name = "peer-2-to-1"
  network = google_compute_network.tf-mod3-demo-network2.self_link
  peer_network = google_compute_network.tf-mod3-demo-network1.self_link
  depends_on  = [google_compute_network.tf-mod3-demo-network1,
    google_compute_network.tf-mod3-demo-network2,
    google_compute_subnetwork.tf-mod3-demo-subnet1,
    google_compute_subnetwork.tf-mod3-demo-subnet2,
  ]
}




// Create a VM1, and put it inside of subnet1
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "tf-mod3-demo-vm1" {
  name = "tf-mod3-demo-vm1"
  machine_type = "e2-micro"
  zone = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod3-demo-network1, google_compute_subnetwork.tf-mod3-demo-subnet1]
  network_interface {
    // This indicates to give a public IP address

    network = "tf-mod3-demo-network1"
    subnetwork = "tf-mod3-demo-subnet1"
  }

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  } 
  metadata = {
    startup-script = "sudo apt update; sudo apt install netcat-traditional ncat;"
  }

}

// Create a VM2, and put it inside of subnet1
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "tf-mod3-demo-vm2" {
  name = "tf-mod3-demo-vm2"
  machine_type = "e2-micro"
  zone = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod3-demo-network1, google_compute_subnetwork.tf-mod3-demo-subnet1]
  network_interface {
    // This indicates to give a public IP address

    network = "tf-mod3-demo-network2"
    subnetwork = "tf-mod3-demo-subnet2"
  }

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = "sudo apt update; sudo apt install netcat-traditional ncat;"
  }

}

//terraform show -json | jq

// If you see something like this:
// │ Error: Error creating instance: googleapi: Error 400: Invalid value for field 'resource.networkInterfaces[0].subnetwork': 'projects/orbital-linker-398719/regions/us-central1/subnetworks/tf-mod3-demo-subnet1'. The referenced subnetwork resource cannot be found., invalid
// There's a dependency that terraform didn't resolve, so it's trying to create X which depends on Y existing.
// To solve, use depends_on
