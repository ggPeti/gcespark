{ config, pkgs, lib, ... }:
{
  options = {
    enabled = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to run a Hadoop master node
      '';
};
  };

  config = {
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
      hdfs.namenode.enabled = true;
      yarn.nodemanager.enabled = true;
      yarn.resourcemanager.enabled = true;
      coreSite = {
        "fs.defaultFS" = "hdfs://localhost:9000";
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