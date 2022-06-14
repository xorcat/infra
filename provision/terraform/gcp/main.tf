terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.74.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.1"
    }
  }
}

data "sops_file" "gcp_secrets" {
  source_file = "secret.sops.yaml"
}

provider "google" {
  credentials = base64decode(data.sops_file.gcp_secrets.data["gcp_sa"])
  project     = data.sops_file.gcp_secrets.data["gcp_project"]
  region      = data.sops_file.gcp_secrets.data["gcp_region"]
}

resource "google_dns_managed_zone" "domain" {
  name        = replace(data.sops_file.gcp_secrets.data["gcp_domain"], ".", "-")
  dns_name    = format("%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  description = format("%s - domain created for home-k8s", data.sops_file.gcp_secrets.data["gcp_domain"])
}

resource "google_dns_policy" "domain-policy" {
  name           = format("%s-policy", replace(data.sops_file.gcp_secrets.data["gcp_domain"], ".", "-"))
  enable_logging = true
  description    = "Created to enable cloud DNS logging"
}

resource "google_dns_record_set" "home" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("home.%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "A"
  rrdatas = [
    data.sops_file.gcp_secrets.data["gcp_public_ip"]
  ]
  ttl = 86400
}
