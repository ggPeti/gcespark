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
      hdfs.datanode.enabled = !cfg.master;
      yarn.nodemanager.enabled = cfg.master;
      yarn.resourcemanager.enabled = cfg.master;
      coreSite = {
        "fs.defaultFS" = "hdfs://${master_ip}:9000";
        "yarn.scheduler.capacity.root.queues" = "default";
        "yarn.scheduler.capacity.root.default.capacity" = 100;
      }; 
      hdfsSite = { 
        "dfs.namenode.name.dir" = "/home/hadoop/data/nameNode";
        "dfs.datanode.data.dir" = "/home/hadoop/data/dataNode";
        "dfs.replication" = 1;
         };
      yarnDefault = {
        "yarn.resourcemanager.address" = "${master_ip}:8032";
      };
      yarnSite = {
        #"yarn.nodemanager.hostname" = "${master_ip}"; 
        #"yarn.nodemanager.address" = "${master_ip}:0";

        #"yarn.resourcemanager.hostname" = "${master_ip}";
        #"yarn.resourcemanager.address" = "${master_ip}:8032";
        
        "yarn.resourcemanager.scheduler.address" = "${master_ip}:8030";
        "yarn.nodemanager.log-dirs" = "/home/hadoop/logs/nodemanager";
        "yarn.nodemanager.aux-services" = "mapreduce_shuffle";
      };
      mapredSite = {
        "mapreduce.framework.name" = "yarn";
      };
      package = pkgs.hadoop_3_1.overrideAttrs (oldAttrs: { installPhase = builtins.replaceStrings ["HADOOP_PREFIX"] ["HADOOP_HOME"] oldAttrs.installPhase; });
      
    };
  };
}