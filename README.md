# infrastructure code for spark on gce

To do the following operations, first have [Nix](https://nixos.org/nix) installed, and then run `nix-shell`.

### To deploy a new version:
1. Download service account key [from the secret server](https://secret.emarsys.net/cred/detail/4215/), save it as `account.json` in the project root
2. Run `terraform apply`

### To ssh into the host:
Run `TERM=xterm ssh -i SECRET_private_key root@$(terraform output ip)`

### To check the host's static public IP address:
Run `terraform output ip`

### To check if haproxy is running:
In the host, run the following: `journalctl -u haproxy`

### To check all running services:
In the host, run the following: `systemctl -t service`


1. Deployer environment
all the tools needed to deploy the system
in our case terraform
defined in shell.nix

2.
3.