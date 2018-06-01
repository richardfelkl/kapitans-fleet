local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local mysql_volumes = inv.parameters.mysql.server.deployment.containers.mysql.volumes;

{
    database: kube.PersistentVolumeClaim(mysql_volumes.database.name) + { storage: mysql_volumes.database.storage },
}