variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "Machine type used by CRIU test VMs"
  type        = string
}

variable "disk_size_gb" {
  description = "Boot disk size"
  type        = number
  default     = 20
}

variable "kernel_versions" {
  description = "Kernel versions/environments to test"
  type        = set(string)
}

variable "criu_ref" {
  description = "CRIU Git ref to test"
  type        = string
  default     = "master"
}

variable "network_name" {
  description = "Existing GCP VPC"
  type        = string
  default     = "default"
}