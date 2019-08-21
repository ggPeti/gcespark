{ config, pkgs, lib, ... }:
let
  cfg = config.services.hadoopCluster;
in {
  options.services.hadoopCluster = with lib.types; {
    enable = lib.mkEnableOption "Hadoop node";

    master = lib.mkOption {
      type = bool;
      description = "Whether it is a master node";
    };

    master_ip = lib.mkOption {
      type = string;
      description = "IP address of master node";
    };

    worker_ips = lib.mkOption {
      type = listOf string;
      default = [];
      description = "List of IP addresses of worker nodes";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ config.services.hadoop.package ];

    users.groups.hadoop = {};
    users.users.hadoop = {
      group = "hadoop";
      createHome = true;
      home = "/home/hadoop";
    };

    system.activationScripts = {
      hadoopGroupRWX = {
        text = "chmod -R g+rwx ${config.users.users.hadoop.home}";
        deps = [];
      };
    };

    #systemd.services.hdfs-namenode.serviceConfig.Type = "simple";

    services.hadoop = {

      hdfs.namenode.enabled = cfg.master;
      hdfs.datanode.enabled = !cfg.master;
      yarn.nodemanager.enabled = cfg.master;
      yarn.resourcemanager.enabled = cfg.master;

      coreSite = {
        "fs.defaultFS" = "hdfs://${cfg.master_ip}:9000";
         };
      hdfsSite = {
        "dfs.namenode.name.dir" = "${config.users.users.hadoop.home}/data/nameNode";
        "dfs.datanode.data.dir" = "${config.users.users.hadoop.home}/data/dataNode";
        "dfs.namenode.checkpoint.dir" = "${config.users.users.hadoop.home}/data/namesecondary";
        "dfs.replication" = 1;
      };
      
      yarnSite = {
        #"yarn.resourcemanager.resource-tracker.address" = "${cfg.master_ip}:8025";
        #"yarn.resourcemanager.scheduler.address" = "${cfg.master_ip}:8030";
        "yarn.resourcemanager.address" = "${cfg.master_ip}:8032";
        "yarn.resourcemanager.hostname" = "${cfg.master_ip}";
        "yarn.nodemanager.resource.memory-mb" = 6144;
        "yarn.nodemanager.resource.cpu-vcores" = 2;
        "yarn.nodemanager.local-dirs" = "${config.users.users.hadoop.home}/data/nm-local-dir";
        #"yarn.resourcemanager.scheduler.address" = "${cfg.master_ip}:8030";
        #"yarn.nodemanager.log-dirs" = "${config.users.users.hadoop.home}/logs/nodemanager";
        "yarn.nodemanager.aux-services" = "mapreduce_shuffle";
      
      };
      mapredSite = {
        "mapreduce.framework.name" = "yarn";
      };
      package = import ../packages/hadoop.nix { inherit pkgs; inherit (cfg) worker_ips; };
    };
  };
}
