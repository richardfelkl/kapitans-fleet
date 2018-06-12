local clusters = import "./clusters.jsonnet";
local pools = import "./pools.jsonnet";
local storageClasses = import "./storageClasses.jsonnet";
local filesystems = import "./filesystems.jsonnet";
local objects = import "./objects.jsonnet";
local rgwSvcs = import "./rgwExternalSvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local rook = inv.parameters.rook;
local cluster = rook.cluster;
local sc = rook.storage_class;
local fs = if "filesystem" in rook then rook.filesystem else {};
local obj = if "object" in rook then rook.object else {};
local rgwSvc = if "rgw_external_service" in rook then rook.rgw_external_service else {};
local pool = inv.parameters.rook.pool;

{
  rook_cluster: clusters.RookCluster(cluster.api_version, 'Cluster', cluster.name),
  rook_storage_class: storageClasses.RookStorageClass(sc.name),
  [if "filesystem" in rook then "rook_filesystem"]: filesystems.RookFilesystem(fs.api_version, 'Filesystem', fs.name),
  [if "object" in rook then "rook_object_store"]: objects.RookObject(obj.api_version, 'ObjectStore', obj.name),
  [if "rgw_external_service" in rook then "rook_rgw_external_service"]: rgwSvcs.RookRgwExternalSvc('v1', 'Service', rgwSvc.name),
}

{
  ['rook_pool_' + name]: pools.RookPool(pool[name], 'Pool', name) for name in std.objectFields(pool)
}