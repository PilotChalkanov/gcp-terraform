resource "google_compute_region_health_check" "be-hc" {

  provider = google

  region = var.region
  name   = "be-hc"
  http_health_check {
    port         = "5000"
    request_path = "/health"

  }
}

# WE DON'T NEED A SECOND PROXY SUBNET for ENVOY

# resource "google_compute_subnetwork" "proxy-be" {
#   name          = "proxy-be"
#   provider      = google
#   ip_cidr_range = "10.5.0.0/24"
#   region        = var.region
#   purpose       = "REGIONAL_MANAGED_PROXY"
#   role          = "ACTIVE"
#   network       = var.vpc_id
# }

resource "google_compute_region_target_http_proxy" "target-proxy-ilb" {
  provider = google

  region  = var.region
  name    = "target-proxy-ilb"
  url_map = google_compute_region_url_map.default.id
  depends_on = [google_compute_region_url_map.default]
}

resource "google_compute_region_url_map" "default" {
  provider = google

  region          = "europe-west1"
  name            = "website-map"
  default_service = google_compute_region_backend_service.website-be.id
}

resource "google_compute_region_backend_service" "website-be" {
  provider = google

  load_balancing_scheme = "INTERNAL_MANAGED"

  backend {
    group = var.vm_instance_group
    balancing_mode = "UTILIZATION"
    capacity_scaler = 0.8
  }

  region      = var.region
  name        = "website-be"
  protocol    = "HTTP"

  timeout_sec = 10
  # port name can be given in case of MANAGED lb
  port_name = "be-http"
  health_checks = [google_compute_region_health_check.be-hc.id]
}


resource "google_compute_forwarding_rule" "be-fwd-rule" {
  provider = google
  name   = "be-fwd-rule"
  region = var.region
  ip_address = "10.0.2.10"
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "5000"
  network               = var.vpc_id
  # subnetwork should be the backend sub network
  subnetwork            = var.subnet_id
  network_tier          = "PREMIUM"
  target = google_compute_region_target_http_proxy.target-proxy-ilb.id
  depends_on = [google_compute_region_target_http_proxy.target-proxy-ilb]
}