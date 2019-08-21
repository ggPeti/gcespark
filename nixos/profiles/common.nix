# NixOS profile for common parts of master and worker nodes
{ config, pkgs, lib, ...}:
let
  configurationJson =
    if builtins.pathExists ../configuration.json then
      builtins.fromJSON (builtins.readFile ../configuration.json)
    else
      lib.warn "../configuration.json not found" {};
in{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/google-compute-config.nix>
    ../modules/hadoop_cluster.nix
  ];
  config = {
    
    
    #hosts = builtins.listToAttrs (imap0 (i: x: {name="worker"+builtins.toString i; value=x;}) worker_ips) // {master="${master_ip}";};
    
    networking.firewall.enable = false;
    networking.hosts = 
      builtins.listToAttrs (lib.imap0 (i: x: {
        name=x; 
        value=[("worker" + builtins.toString i)];
        }) configurationJson.worker_ips) // {"${configurationJson.master_ip}" = ["master"]; };
    

    programs.bash.enableCompletion = true;

    users.groups.spark = {};
    users.users.spark = {
      group = "spark";
      createHome = true;
      home = "/home/spark";
    };

    services.hadoopCluster = {
      enable = true;
      master_ip = configurationJson.master_ip;
      worker_ips = configurationJson.worker_ips;
    };
    
  };
}
