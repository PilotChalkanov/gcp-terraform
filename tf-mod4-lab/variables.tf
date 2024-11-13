variable "namespace" {
  description = "The project namespace as a unique resource"
  type = string
}

variable "region" {
  description = "GCP region"
  default = "europe-west1"
}