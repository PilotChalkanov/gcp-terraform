provider "google" {
  credentials = file("/home/niko/UNI/Networks/CloudNetworking/npp-cloud/onyx-outpost-438905-q4-ad8b6c690641.json")

  project = "onyx-outpost-438905-q4"
  region  = var.region  // default
  zone    = "europe-west1-c"  // default
}
