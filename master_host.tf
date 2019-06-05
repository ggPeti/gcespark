resource "google_compute_instance" "gcespark" {
  name = "cristi-spark-gce"
  machine_type = "n1-standard-1"
  zone = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "${google_compute_image.nixos_1809.self_link}"
      size = 10
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${google_compute_address.gcespark.address}"
    }
  }

  metadata = {
    sshKeys = "root:${tls_private_key.root_key.public_key_openssh}" 
  }

  connection {
    user        = "root"
    host        = "${self.network_interface.0.access_config.0.nat_ip}"
    private_key = "${tls_private_key.root_key.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
      "nix-channel --remove nixos",
      "nix-channel --add https://nixos.org/channels/nixos-19.03 nixos",
      "nix-channel --update"
    ]
  }
}


resource "google_compute_image" "nixos_1809" {
  name = "nixos-1809"

  raw_disk {
    source = "https://storage.googleapis.com/nixos-cloud-images/nixos-image-18.09.1228.a4c4cbb613c-x86_64-linux.raw.tar.gz"
  }
}


resource "null_resource" "gcespark_deploy" {
  triggers = {
    instance = "${google_compute_instance.gcespark.id}"
    always  = "${uuid()}"
  }

  connection {
    user        = "root"
    host        = "${local.instance_ip}"
    private_key = "${tls_private_key.root_key.private_key_pem}"
  }

  provisioner "file" {
    source = "templates/master_host.nix"
    destination = "/root/host.nix"
  }

  provisioner "file" {
    source = "templates/configuration.nix"
    destination = "/etc/nixos/configuration.nix"
  }

  provisioner "file" {
    source = "nixpkgs-pinned.nix"
    destination = "/root/nixpkgs-pinned.nix"
  }

  provisioner "remote-exec" {
    inline = [
      "nixos-rebuild switch --show-trace",
      # "nix-collect-garbage"
    ]
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


resource "google_compute_address" "gcespark" {
  name = "gcespark-external"
}
