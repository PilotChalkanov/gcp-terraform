
# frontend vms
resource "google_compute_instance" "fe-vm1" {
  name         = "fe-vm1"
  machine_type = "e2-micro"
  zone         = var.zone
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = var.vpc_id
    subnetwork = var.subnet_fe_id
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
  zone         = var.zone
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = var.vpc_id
    subnetwork = var.subnet_fe_id
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
  zone = var.zone
}


# backend vms
resource "google_compute_instance" "be-vm1" {
  name         = "be-vm1"
  machine_type = "e2-micro"
  zone         = var.zone
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = var.vpc_id
    subnetwork = var.subnet_be_id
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
  zone         = var.zone
  network_interface {
    // This indicates to give a public IP address
    access_config {
      network_tier = "STANDARD"

    }
    network    = var.vpc_id
    subnetwork = var.subnet_be_id
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
  zone = var.zone

}