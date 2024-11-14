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

  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = var.vm_instance_group
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }

  region      = var.region
  name        = "website-be"
  protocol    = "HTTP"
  timeout_sec = 10
  port_name = "be-http"
  health_checks = [google_compute_region_health_check.be-hc.id]
}

resource "google_compute_region_target_http_proxy" "be-proxy-map" {
  provider = google

  region  = "europe-west1"
  name    = "website-proxy"
  url_map = google_compute_region_url_map.be-url-map.id
}

resource "google_compute_region_url_map" "be-url-map" {
  provider = google

  region          = "europe-west1"
  name            = "website-map"
  default_service = google_compute_region_backend_service.website-be.id
}

resource "google_compute_subnetwork" "subnet-be-proxy" {
  name          = "subnet-be-proxy"
  ip_cidr_range = "10.0.4.0/24"
  region        = var.region
  network       = var.vpc_id
}

resource "google_compute_forwarding_rule" "be-fwd-rule" {
  provider = google
  name   = "be-fwd-rule"
  region = var.region
  ip_address = "10.0.4.10"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "5000"
  target                = google_compute_region_target_http_proxy.be-proxy-map.id
  network               = var.vpc_id
  subnetwork            = google_compute_subnetwork.subnet-be-proxy.id
  network_tier          = "PREMIUM"

}