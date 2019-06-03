# Infrastructure definition

provider "google" {
  project     = ""
  region      = "europe-west1"
}


resource "tls_private_key" "rds_tactics_proxy" {
  algorithm = "RSA"
}


resource "local_file" "private_key" {
  filename = "${path.module}/SECRET_private_key"
  content  = "${tls_private_key.rds_tactics_proxy.private_key_pem}"

  provisioner "local-exec" {
    command = "chmod 600 ${path.module}/SECRET_private_key"
  }
}


locals {
  instance_ip = "${google_compute_instance.rds_tactics_proxy.network_interface.0.access_config.0.nat_ip}"
}


output "ip" {
  value = "${local.instance_ip}"
}
