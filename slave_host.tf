resource "google_compute_instance" "gcespark_slave" {
  count = 3
  name = "cristi-spark-gce-slave-${count.index}"
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
    access_config {}
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


resource "null_resource" "gcespark_deploy_slave" {
  count = 3
  depends_on = [null_resource.gcespark_deploy_master]
  triggers = {
    instance = "${google_compute_instance.gcespark_slave.*.id[count.index]}"
    always  = "${uuid()}"
  }

  connection {
    user        = "root"
    host        = "${google_compute_instance.gcespark_slave.*.network_interface.0.access_config.0.nat_ip[count.index]}"
    private_key = "${tls_private_key.root_key.private_key_pem}"
  }

  provisioner "file" {
    content = templatefile("templates/slave_host.nix", { master_ip = local.private_ip })
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

  provisioner "remote-exec" {
    inline = [
      "nixos-rebuild switch",
      "nix-collect-garbage -d"
    ]
  }
}
