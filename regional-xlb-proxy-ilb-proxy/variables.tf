variable "namespace" {
  description = "The project namespace as a unique resource"
  type = string
}

variable "region" {
  description = "GCP region"
  default = "europe-central2"
}

variable "project_name" {
  default = "onyx-outpost-438905-q4"
}