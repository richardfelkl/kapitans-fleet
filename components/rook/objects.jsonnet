local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local func = import "lib/function.libjsonnet";
local inv = kap.inventory();
local obj = inv.parameters.rook.object;
local affinity =  if "affinity" in obj.gateway then obj.gateway.affinity else {};

{
  RookObject(apiVersion, kind, name): kube.CustomResource(apiVersion, kind, name) {
    spec+: {
      metadataPool: {
        failureDomain: if ("failure_domain" in obj.metadata_pool) then obj.metadata_pool.failure_domain else 'host',
        [if "replicated" in obj.metadata_pool then "replicated"]: {
          size: if ("size" in obj.metadata_pool.replicated) then obj.metadata_pool.replicated.size else 1,
        },
      },
      dataPool: {
        failureDomain: if ("failure_domain" in obj.data_pool) then obj.data_pool.failure_domain else 'osd',
        [if "replicated" in obj.data_pool then "replicated"]: {
          size: if ("size" in obj.data_pool.replicated) then obj.data_pool.replicated.size else 1,
        },
        [if "erasure_coded" in obj.data_pool then "erasureCoded"]: {
          dataChunks: if ("data_chunks" in obj.data_pool.erasure_coded) then obj.data_pool.erasure_coded.data_chunks else 2,
          codingChunks: if ("coding_chunks" in obj.data_pool.erasure_coded) then obj.data_pool.erasure_coded.coding_chunks else 1,
        },
      },
      gateway: {
        type: if ("type" in obj.gateway) then obj.gateway.type else 's3',
        port: if ("port" in obj.gateway) then obj.gateway.port else 80,
        sslCertificateRef: if ("ssl_certificate_ref" in obj.gateway) then obj.gateway.ssl_certificate_ref else {},
        securePort: if ("secure_port" in obj.gateway) then obj.gateway.secure_port else {},
        instances: if ("instances" in obj.gateway) then obj.gateway.instances else 1,
        allNodes: if ("all_nodes" in obj.gateway) then obj.gateway.all_nodes else false,
        [if "affinity" in obj.gateway then "placement"]: func.Affinity(affinity), 
        [if "resource" in obj.gateway  then "resources"]: func.Resource(obj.gateway.resource),        
      },
    },
  },
}
