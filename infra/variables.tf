variable "project_id" {
  description = "The ID of the project in which to create the VM"
  type        = string
}

variable "region" {
  description = "The region in which to create the VM"
  type        = string
  default     = "us-central1"
}
