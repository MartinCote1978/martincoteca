output "url" {
  description = "Public URL of the website"
  value       = "http://${data.google_dns_managed_zone.gcp_wwwmartincoteca_zone.dns_name}"
}
