output "environment" {
  value = terraform.workspace
}

output "available_zones" {
  value = data.google_compute_zones.available.names
}

output "instances" {
  value = {
    for kernel, vm in google_compute_instance.criu_test :
    kernel => {
      name        = vm.name
      external_ip = vm.network_interface[0].access_config[0].nat_ip
      zone        = vm.zone
    }
  }
}