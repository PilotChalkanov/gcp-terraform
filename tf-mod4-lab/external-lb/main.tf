

resource "google_compute_region_url_map" "url-xlb" {
  provider = google
  region          = var.region
  name            = "url-xlb"
  default_service = google_compute_region_backend_service.website-fe.id

}

resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "l7-ilb-proxy-subnet"
  provider      = google
  ip_cidr_range = "10.4.0.0/24"
  region        = var.region
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
  network       = var.vpc_id
}


resource "google_compute_region_backend_service" "website-fe" {
  provider = google

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 0.8
    group = var.vm_instance_group
  }

  region      = var.region
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
  region             = var.region



  http_health_check {
    port         = "5000"
    request_path = "/health"

  }
}
// Forwarding rule for External Network Load Balancing using Backend Services
resource "google_compute_forwarding_rule" "fwd-rule-fe" {
  provider              = google
  name                  = "fwd-rule-fe"
  region                = var.region
  ip_protocol = "HTTP"
  port_range            = 80
  depends_on = [google_compute_subnetwork.proxy_subnet]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.http-proxy-fe.id
  network               = var.vpc_id
}

resource "google_compute_region_target_http_proxy" "http-proxy-fe" {
  name     = "http-proxy-fe"
  provider = google
  region   = var.region
  url_map  = google_compute_region_url_map.url-xlb.id
}