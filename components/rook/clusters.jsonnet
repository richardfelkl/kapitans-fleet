local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local func = import "lib/function.libjsonnet";
local inv = kap.inventory();
local cluster = inv.parameters.rook.cluster;
local affinity =  if "affinity" in cluster then cluster.affinity else {};

{
  node(nodes): [
    {
      name: id,
      directories: if ("storage_directories" in nodes[id]) then nodes[id].storage_directories else {},
      [if "resource" in nodes[id] then "resources"]: func.Resource(nodes[id].resource),
      [if "devices" in nodes[id] then "devices"]: nodes[id].devices, 
      [if "device_filter" in nodes[id] then "deviceFilter"]: nodes[id].device_filter,
    } for id in std.objectFields(nodes)
  ],
}

{
  RookCluster(apiVersion, kind, name): kube.CustomResource(apiVersion, kind, name) {
    spec+: {
      monCount: if ("mon_count" in cluster) then cluster.mon_count else 3,
      dataDirHostPath: if ("data_host_path" in cluster) then cluster.data_host_path else '/var/lib/rook',
      network: {
        hostNetwork: if ("host_network" in cluster) then cluster.host_network else 'false',
      },
      storage: {
        useAllNodes: if ("use_all_nodes" in cluster) then cluster.use_all_nodes else false,
        useAllDevices: if ("use_all_devices" in cluster) then cluster.use_all_devices else false,
        deviceFilter: if ("device_filter" in cluster) then cluster.device_filter else false,
        location: if ("location" in cluster) then cluster.location else false,
        directories: if ("storage_directories" in cluster) then cluster.storage_directories else {},
        config: {
          storeType: if ("store_type" in cluster) then cluster.store_type else {},
          databaseSizeMB: if ("db_size_mb" in cluster) then cluster.db_size_mb else {},
          journalSizeMB: if ("journal_size_mb" in cluster) then cluster.journal_size_mb else {},
        }
      },
      [if "affinity" in cluster then "placement"]: func.TargetAffinity(affinity), 
      [if "resource" in cluster  then "resources"]: func.TargetResource(cluster.resource), 
      [if "node" in cluster  then "nodes"]: $.node(cluster.node), 

    },
  },
}
