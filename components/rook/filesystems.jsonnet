local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local func = import "lib/function.libjsonnet";
local inv = kap.inventory();
local fs = inv.parameters.rook.filesystem;
local affinity =  if "affinity" in fs.metadata_server then fs.metadata_server.affinity else {};

{
  RookFilesystem(apiVersion, kind, name): kube.CustomResource(apiVersion, kind, name) {
    spec+: {
      metadataPool: {
        [if "replicated" in fs.metadata_pool then "replicated"]: {
          size: if ("size" in fs.metadata_pool.replicated) then fs.metadata_pool.replicated.size else 1,
        },
      },
      dataPools: [
        {
          failureDomain: fs.data_pool.failure_domain,
          [if "replicated" in fs.data_pool then "replicated"]: fs.data_pool.replicated,
          [if "erasure_coded" in fs.data_pool then "erasureCoded"]: fs.data_pool.erasure_coded,
        },
      ],
      metadataServer: {
        activeCount: if ("active_count" in fs.metadata_server) then fs.metadata_server.active_count else 1,
        activeStandby: if ("active_standby" in fs.metadata_server) then fs.metadata_server.active_standby else true,
        [if "affinity" in fs.metadata_server then "placement"]: func.Affinity(affinity), 
        [if "resource" in fs.metadata_server  then "resources"]: func.Resource(fs.metadata_server.resource),  
      },
    },
  },
}
