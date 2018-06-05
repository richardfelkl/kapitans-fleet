local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local cluster = inv.parameters.mysql.server.cluster;

{
  MysqlCluster(apiVersion, kind, name): kube.CustomResource(apiVersion, kind, name) {
    spec+: {
      multiMaster: if cluster.multi_master then cluster.multi_master else {},
      version: if ("version" in cluster) then cluster.version else {},
      replicas: if ("replicas" in cluster) then cluster.replicas else 1,
      secretRef: {
        name: cluster.secret,
      },
      volumeClaimTemplate: {
        metadata: {
          name: cluster.volume_claim_template.name,
        },
        spec: {
          [if "storage_class" in cluster.volume_claim_template then "storageClassName"]: cluster.volume_claim_template.storage_class,
          accessModes: [
            cluster.volume_claim_template.access_mode,
          ],
          resources: {
            requests: {
              storage: cluster.volume_claim_template.size,
            },
          },
        },
      },
    },
  },
}
