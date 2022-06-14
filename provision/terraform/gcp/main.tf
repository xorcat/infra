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

resource "google_dns_record_set" "caa" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "CAA"
  rrdatas = [
    "0 issue \"letsencrypt.org\""
  ]
  ttl = 86400
}

resource "google_dns_record_set" "root-a" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "A"
  rrdatas = [
    data.sops_file.gcp_secrets.data["gcp_website_ip"]
  ]
  ttl = 86400
}

resource "google_dns_record_set" "www" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("www.%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "A"
  rrdatas = [
    data.sops_file.gcp_secrets.data["gcp_website_ip"]
  ]
  ttl = 86400
}

resource "google_dns_record_set" "mail" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("mail.%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "A"
  rrdatas = [
    data.sops_file.gcp_secrets.data["gcp_public_ip"]
  ]
  ttl = 86400
}

resource "google_dns_record_set" "mx" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "MX"
  rrdatas = [
    format("10 mail.%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  ]
  ttl = 86400
}

resource "google_dns_record_set" "spf" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "TXT"
  rrdatas = [
    format("\"%s\"", data.sops_file.gcp_secrets.data["gcp_spf_record"])
  ]
  ttl = 86400
}

resource "google_dns_record_set" "dmarc" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("_dmarc.%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "TXT"
  rrdatas = [
    format("\"%s\"", data.sops_file.gcp_secrets.data["gcp_dmarc_record"])
  ]
  ttl = 86400
}

resource "google_dns_record_set" "dkim" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("dkimselector._domainkey.%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "TXT"
  rrdatas = [
    format("\"%s\"", data.sops_file.gcp_secrets.data["gcp_dkim_record"])
  ]
  ttl = 86400
}

resource "google_dns_record_set" "dns-wl" {
  managed_zone = google_dns_managed_zone.domain.name
  name         = format("_token._dnswl.%s.", data.sops_file.gcp_secrets.data["gcp_domain"])
  type         = "TXT"
  rrdatas = [
    data.sops_file.gcp_secrets.data["gcp_dnswl_record"]
  ]
  ttl = 86400
}
