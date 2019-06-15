# NixOS module for gcespark
# Provisioned by Terraform

{ config, pkgs, lib, ... } :

{
  imports = [ ./hadoop_cluster.nix ];

  networking.firewall.enable = false;

fileSystems."/data" = {
    device = "/dev/sdb";
    autoFormat = true;
    fsType = "ext4";
  };

  programs.bash.enableCompletion = true;

  environment.systemPackages = [ (import /root/tpcds.nix { inherit pkgs; }) ];

  users.groups.spark = {};
  users.users.spark = {
    group = "spark";
    createHome = true;
    home = "/home/spark";
  };

  systemd.services.mysparkservice = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.User = "spark";
    path = [ pkgs.procps ];
    script = ''
      export SPARK_MASTER_HOST=${master_ip}
      export SPARK_LOG_DIR=/home/spark/logs
      export SPARK_NO_DAEMONIZE=true
      $${(import ./nixpkgs-pinned.nix {}).spark}/lib/spark-2.4.3-bin-without-hadoop/sbin/start-master.sh
    '';
  };

  services.hadoopCluster = {
    enable = true;
    master = true;
  };

  
}