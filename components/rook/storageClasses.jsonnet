local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local sc = inv.parameters.rook.storage_class;

{
  RookStorageClass(name): kube.StorageClass(name) {
    provisioner: if ("provisioner" in sc) then sc.provisioner else 'ceph.rook.io/block',
    parameters: {
      pool: sc.pool,
      clusterNamespace: sc.cluster_ns,
      fstype: if ("fstype" in sc) then sc.fstype else {},
    },
  },
}
