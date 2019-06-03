# Infrastructure definition

provider "google" {
  project     = "symmetric-stage-242608"
  region      = "europe-west1"
}


resource "tls_private_key" "root_key" {
  algorithm = "RSA"
}


resource "local_file" "private_key" {
  filename = "${path.module}/SECRET_private_key"
  content  = "${tls_private_key.root_key.private_key_pem}"

  provisioner "local-exec" {
    command = "sudo chmod 600 ${path.module}/SECRET_private_key"
  }
}


locals {
  instance_ip = "${google_compute_instance.gcespark.network_interface.0.access_config.0.nat_ip}"
}


output "ip" {
  value = "${local.instance_ip}"
}
