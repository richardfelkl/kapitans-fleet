local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local volumes = inv.parameters.mysql.server.deployment.containers.mysql.volumes;

{
    database: kube.PersistentVolumeClaim(volumes.database.name) + { storage: volumes.database.storage },
}