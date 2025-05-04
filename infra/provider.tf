# GCP provider

provider "google" {
  project = var.project_id
  region  = var.region
}

# GCP beta provider
provider "google-beta" {
  project = var.project_id
  region  = var.region
}
