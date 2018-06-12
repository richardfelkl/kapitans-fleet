local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  RookPool(pool, kind, name): kube.CustomResource(pool.api_version, kind, name) {
    spec+: {
      failureDomain: if ("failure_domain" in pool) then pool.failure_domain else 'osd',
      crushRoot: if ("crush_root" in pool) then pool.crush_root else 'default',
      [if "replicated" in pool then "replicated"]: {
        size: if ("size" in pool.replicated) then pool.replicated.size else 1,
      },
      [if "erasure_coded" in pool then "erasureCoded"]: {
        dataChunks: if ("data_chunks" in pool.erasure_coded) then pool.erasure_coded.data_chunks else 2,
        codingChunks: if ("coding_chunks" in pool.erasure_coded) then pool.erasure_coded.coding_chunks else 1,
      },
    },
  }, 
}
