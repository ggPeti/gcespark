{ config, pkgs, lib, ... }:
let cfg = config.services.hadoopCluster;
in
with lib;
{
  options.services.hadoopCluster = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to run a Hadoop node";
    };
    
    master = mkOption {
      type = types.bool;
      description = "Whether it is a master node";
    };
  };

  config = mkIf cfg.enable {
    users.groups.hadoop = {};
    users.users.hadoop = {
        group = "hadoop";
        createHome = true;
        home = "/home/hadoop";
    };

    system.activationScripts = {
        hadoopGroupRWX = {
        text = "chmod -R g+rwx /home/hadoop";
        deps = [];
        };
    };

    services.hadoop = { 
      hdfs.namenode.enabled = cfg.master;
      yarn.nodemanager.enabled = cfg.master;
      yarn.resourcemanager.enabled = cfg.master;
      coreSite = {
        "fs.defaultFS" = "hdfs://${master_ip}:9000";
        "yarn.scheduler.capacity.root.queues" = "default";
        "yarn.scheduler.capacity.root.default.capacity" = 100;
      }; 
      hdfsSite = { "dfs.replication" = 1; };
      yarnSite = {
        "yarn.nodemanager.hostname" = "${master_ip}"; 
        "yarn.resourcemanager.hostname" = "${master_ip}";
        "yarn.nodemanager.log-dirs" = "/home/hadoop/logs/nodemanager";
      };
      package = pkgs.hadoop_3_1;
    };
  };
}