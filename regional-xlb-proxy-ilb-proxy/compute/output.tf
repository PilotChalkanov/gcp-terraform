output "fe-instance-group" {
  value = google_compute_instance_group.fe-group.id
}

output "be-instance-group" {
  value = google_compute_instance_group.be-group.id
}