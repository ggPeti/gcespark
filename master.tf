resource "google_compute_instance" "master" {
  name = "${var.env}-gcespark-master"
  machine_type = "n1-standard-2"
  zone = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = google_compute_image.nixos_1809.self_link
      size = 40
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.gcespark.address
    }
  }

  metadata = {
    sshKeys = "root:${tls_private_key.root_key.public_key_openssh}"
  }

  connection {
    user        = "root"
    host        = self.network_interface.0.access_config.0.nat_ip
    private_key = tls_private_key.root_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "nix-channel --remove nixos",
      "nix-channel --add https://nixos.org/channels/nixos-19.03 nixos",
      "nix-channel --update"
    ]
  }
}


resource "null_resource" "deploy_master" {
  count = 1
  triggers = {
    instance = google_compute_instance.master.id
    always  = uuid()
  }

  connection {
    user        = "root"
    host        = google_compute_instance.master.network_interface.0.access_config.0.nat_ip
    private_key = tls_private_key.root_key.private_key_pem
  }

  provisioner "file" {
    source      = "./nixos/"
    destination = "/etc/nixos/"
  }

  provisioner "file" {
    content      = "{ imports = [ profiles/master.nix ]; }"
    destination = "/etc/nixos/configuration.nix"
  }

  provisioner "file" {
    content = data.template_file.configuration_json.rendered
    destination = "/etc/nixos/configuration.json"
  }

  provisioner "remote-exec" {
    inline = [
      "nixos-rebuild switch --show-trace"
    ]
  }
}

resource "google_compute_address" "gcespark" {
  name = "${var.env}-gcespark-external"
}
