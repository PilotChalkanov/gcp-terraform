resource "google_compute_region_health_check" "be-hc" {

  provider = google

  region = var.region
  name   = "be-hc"
  http_health_check {
    port         = "5000"
    request_path = "/health"

  }
}

resource "google_compute_region_backend_service" "website-be" {
  provider = google

  load_balancing_scheme = "INTERNAL"

  backend {
    group = var.vm_instance_group
    balancing_mode = "CONNECTION"
  }

  region      = var.region
  name        = "website-be"
  protocol    = "TCP"

  timeout_sec = 10
  # port name cannot be used with INTERNAL LB, type TCP PASSTROUGH
  # port_name = "be-http"
  health_checks = [google_compute_region_health_check.be-hc.id]
}


resource "google_compute_forwarding_rule" "be-fwd-rule" {
  provider = google
  name   = "be-fwd-rule"
  backend_service = google_compute_region_backend_service.website-be.id
  region = var.region
  ip_address = "10.0.2.10"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  ports            = ["5000", "80"]
  network               = var.vpc_id
  # subnetwork should be the backend sub network
  subnetwork            = var.subnet_id
  network_tier          = "PREMIUM"
}