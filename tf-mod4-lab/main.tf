terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

module "networking" {
  source = "./networking"
  namespace = var.namespace
  region = var.region
  project_name = var.project_name

}

module "compute"{
  source="./compute"
  namespace = var.namespace
  zone = "${var.region}-c"
  vpc_id = module.networking.vpc_id
  subnet_id = module.networking.subnet_id
  depends_on = [module.networking]
}

module "external-lb" {
  source = "./external-lb"
  namespace = var.namespace
  vm_instance_group = module.compute.fe-instance-group
  depends_on = [module.networking]
  region = var.region
  vpc_id = module.networking.vpc_id
}
