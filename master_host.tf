resource "google_compute_instance" "gcespark_master" {
  name = "cristi-spark-gce-master"
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


resource "null_resource" "gcespark_deploy_master" {
  triggers = {
    instance = "${google_compute_instance.gcespark_master.id}"
    always  = "${uuid()}"
  }

  connection {
    user        = "root"
    host        = "${local.public_ip}"
    private_key = "${tls_private_key.root_key.private_key_pem}"
  }

  provisioner "file" {
    content = templatefile("templates/master_host.nix", { master_ip = local.private_ip })
    destination = "/root/host.nix"
  }

  provisioner "file" {
    source = "templates/configuration.nix"
    destination = "/etc/nixos/configuration.nix"
  }

  provisioner "file" {
    content = templatefile("templates/hadoop_cluster.nix", { master_ip = local.private_ip })
    destination = "/root/hadoop_cluster.nix"
  }

  provisioner "file" {
    source = "nixpkgs-pinned.nix"
    destination = "/root/nixpkgs-pinned.nix"
  }

  provisioner "file" {
    source = "templates/tpcds.nix"
    destination = "/root/tpcds.nix"
  }

   provisioner "file" {
    source = "templates/hive.nix"
    destination = "/root/hive.nix"
  }

  provisioner "remote-exec" {
    inline = [
      "nixos-rebuild switch",
      "#nix-collect-garbage -d"
    ]
  }
}
resource "google_compute_address" "gcespark" {
  name = "gcespark-external"
}
