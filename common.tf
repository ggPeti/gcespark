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


resource "google_compute_image" "nixos_1809" {
  name = "nixos-1809"

  raw_disk {
    source = "https://storage.googleapis.com/nixos-cloud-images/nixos-image-18.09.1228.a4c4cbb613c-x86_64-linux.raw.tar.gz"
  }
}


resource "google_compute_firewall" "default" {
  name = "default-allow-ssh-and-spark"
  network = "default"

  allow {
    protocol = "tcp"
    ports = [22, 7077, 8080]
  }
}


locals {
  instance_ip = "${google_compute_instance.gcespark_master.network_interface.0.access_config.0.nat_ip}"
}


output "ip" {
  value = "${local.instance_ip}"
}
