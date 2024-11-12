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


// VPC1


resource "google_compute_network" "tf-mod2-lab1-network1" {
  name = "tf-mod2-lab1-network1"
  auto_create_subnetworks = "false"
}
# VPC2
resource "google_compute_network" "tf-mod2-lab1-network2" {
  name = "tf-mod2-lab1-network2"
  auto_create_subnetworks = "false"
}


// subnet1
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork

resource "google_compute_subnetwork" "tf-mod2-lab1-sub1" {
  name          = "tf-mod2-lab1-sub1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-west1"
  network       = google_compute_network.tf-mod2-lab1-network1.id
}
# subnet2
resource "google_compute_subnetwork" "tf-mod2-lab1-sub2" {
  name          = "tf-mod2-lab1-sub2"
  ip_cidr_range = "10.0.2.0/24"
  region        = "europe-west1"
  network       = google_compute_network.tf-mod2-lab1-network2.id
}
# subnet3
resource "google_compute_subnetwork" "tf-mod2-lab1-sub3" {
  name          = "tf-mod2-lab1-sub3"
  ip_cidr_range = "10.0.3.0/24"
  region        = "europe-west1"
  network       = google_compute_network.tf-mod2-lab1-network2.id
}


// Create Firewall rule - allow icmp, tcp:22 (ssh), and tcp:1234 (custom)
//https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall
resource "google_compute_firewall" "tf-mod2-lab1-fwrule1" {
  project = "onyx-outpost-438905-q4"
  name        = "tf-mod2-lab1-fwrule1"
  network     = "tf-mod2-lab1-network1"
  // need the network created before the firewall rule
  // I noticed sometimes terraform didn't detect the dependency, so making explicit.
  depends_on = [google_compute_network.tf-mod2-lab1-network1]

  allow {
    protocol  = "tcp"
    ports     = ["22", "1234"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "tf-mod2-lab1-fwrule2" {
  project = "onyx-outpost-438905-q4"
  name        = "tf-mod2-lab1-fwrule2"
  network     = "tf-mod2-lab1-network2"
  // need the network created before the firewall rule
  // I noticed sometimes terraform didn't detect the dependency, so making explicit.
  depends_on = [google_compute_network.tf-mod2-lab1-network2]

  allow {
    protocol  = "tcp"
    ports     = ["22", "1234"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}




// Create a VM, and put it inside of subnet1
// https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
resource "google_compute_instance" "tf-mod2-lab1-vm1" {
  name = "tf-mod2-lab1-vm1"
  machine_type = "e2-micro"
  zone = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod2-lab1-network1, google_compute_subnetwork.tf-mod2-lab1-sub1]
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"
    }
    network = "tf-mod2-lab1-network1"
    subnetwork = "tf-mod2-lab1-sub1"
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
resource "google_compute_instance" "tf-mod2-lab1-vm2" {
  name = "tf-mod2-lab1-vm2"
  machine_type = "e2-micro"
  zone = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod2-lab1-network2, google_compute_subnetwork.tf-mod2-lab1-sub2]
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"
    }
    network = "tf-mod2-lab1-network2"
    subnetwork = "tf-mod2-lab1-sub2"
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
resource "google_compute_instance" "tf-mod2-lab1-vm3" {
  name = "tf-mod2-lab1-vm3"
  machine_type = "e2-micro"
  zone = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod2-lab1-network2, google_compute_subnetwork.tf-mod2-lab1-sub2]
  network_interface {
    // This indicates to give a public IP address

    network = "tf-mod2-lab1-network2"
    subnetwork = "tf-mod2-lab1-sub3"
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
resource "google_compute_instance" "tf-mod2-lab1-vm4" {
  name = "tf-mod2-lab1-vm4"
  machine_type = "e2-micro"
  zone = "europe-west1-c"
  depends_on = [google_compute_network.tf-mod2-lab1-network2, google_compute_subnetwork.tf-mod2-lab1-sub3]
  network_interface {
    // This indicates to give a public IP address

    network = "tf-mod2-lab1-network2"
    subnetwork = "tf-mod2-lab1-sub3"
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
// │ Error: Error creating instance: googleapi: Error 400: Invalid value for field 'resource.networkInterfaces[0].subnetwork': 'projects/orbital-linker-398719/regions/us-central1/subnetworks/tf-mod2-demo1-subnet1'. The referenced subnetwork resource cannot be found., invalid
// There's a dependency that terraform didn't resolve, so it's trying to create X which depends on Y existing.
// To solve, use depends_on
