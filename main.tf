# Data block 1: discover latest Ubuntu 24.04 image
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

# Data block 2: discover existing network
data "google_compute_network" "network" {
  name = var.network_name
}

# Data block 3: discover available zones
data "google_compute_zones" "available" {
  region = var.region
}

resource "google_compute_instance" "criu_test" {
  for_each = var.kernel_versions

  name = "criu-${terraform.workspace}-${replace(each.value, ".", "-")}"

  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = data.google_compute_network.network.self_link

    access_config {}
  }

  metadata_startup_script = templatefile(
    "${path.module}/scripts/bootstrap.sh",
    {
      kernel_version = each.value
      criu_ref       = var.criu_ref
      environment    = terraform.workspace
    }
  )

  labels = {
    environment = terraform.workspace
    kernel      = replace(each.value, ".", "-")
    purpose     = "criu-testing"
  }

  tags = [
    "criu-test",
    terraform.workspace
  ]
}