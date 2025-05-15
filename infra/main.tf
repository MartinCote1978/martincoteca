# Bucket to store website
resource "google_storage_bucket" "martincoteca_website" {
  provider = google
  name     = "martincoteca-website"
  location = "US"
}

# Make all objects public by default
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.martincoteca_website.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Upload all website files to the bucket
resource "null_resource" "upload_website_files" {
  provisioner "local-exec" {
    command = "gsutil -m cp -r ../website/* gs://${google_storage_bucket.martincoteca_website.name}/"
  }
  triggers = {
    content_hash = sha1(join("", [for f in fileset("../website", "**") : filesha1("../website/${f}")]))
  }
  depends_on = [google_storage_bucket.martincoteca_website]
}

# Reserve an external IP
resource "google_compute_global_address" "martincoteca_website_ip" {
  provider = google
  name     = "martincoteca-website-lb-ip"
}

# Get the managed DNS zone
data "google_dns_managed_zone" "gcp_wwwmartincoteca_zone" {
  provider = google
  name     = "martincoteca-website"
}

# Add the IP to the DNS
resource "google_dns_record_set" "martincoteca-website" {
  provider     = google
  name         = data.google_dns_managed_zone.gcp_wwwmartincoteca_zone.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.gcp_wwwmartincoteca_zone.name
  rrdatas      = [google_compute_global_address.martincoteca_website_ip.address]
}

# Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "martincoteca_website_backend" {
  provider    = google
  name        = "martincoteca-website-backend"
  description = "Contains files needed by the website"
  bucket_name = google_storage_bucket.martincoteca_website.name
  enable_cdn  = true
}

# Create HTTPS certificate
# resource "google_compute_managed_ssl_certificate" "website" {
#   provider = google-beta
#   name     = "website-cert"
#   managed {
#     domains = [google_dns_record_set.website.name]
#   }
# }

# GCP URL MAP
resource "google_compute_url_map" "martincoteca_urlmap_website" {
  provider        = google
  name            = "martincoteca-website-url-map"
  default_service = google_compute_backend_bucket.martincoteca_website_backend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.martincoteca_website_backend.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.martincoteca_website_backend.self_link
    }
  }
}

# GCP target proxy
resource "google_compute_target_http_proxy" "martincoteca_http_proxy" {
  provider = google
  name     = "martincoteca-website-target-proxy"
  url_map  = google_compute_url_map.martincoteca_urlmap_website.self_link
  #ssl_certificates = [google_compute_managed_ssl_certificate.website.self_link]
}

# GCP forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  provider              = google
  name                  = "martincoteca-website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.martincoteca_website_ip.address
  ip_protocol           = "TCP"
  #port_range            = "443"
  port_range = "80"
  #target                = google_compute_target_https_proxy.website.self_link
  target = google_compute_target_http_proxy.martincoteca_http_proxy.self_link
}
