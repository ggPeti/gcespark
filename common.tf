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
    ports = [22, 7077, 8042, 8044, 8080, 9000]
  }
}


locals {
  public_ip = "${google_compute_instance.gcespark_master.network_interface.0.access_config.0.nat_ip}"
  private_ip = "${google_compute_instance.gcespark_master.network_interface.0.network_ip}"
}


output "ip" {
  value = "${local.public_ip}"
}


resource "google_compute_disk" "data_storage" {
  name  = "test-disk-cristi"
  type  = "pd-standard"
  size  = 2
  zone  = "europe-west1-b"
  physical_block_size_bytes = 4096
  
  lifecycle {
      prevent_destroy = false
  }
}

resource "google_compute_attached_disk" "attach_data_storage" {
  disk = "${google_compute_disk.data_storage.self_link}"
  instance = "${google_compute_instance.gcespark_master.self_link}"
  lifecycle {
      prevent_destroy = false
  }
}

//https://github.com/gregrahn/tpcds-kit
//