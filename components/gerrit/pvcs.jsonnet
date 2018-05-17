local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
    reviewsite: kube.PersistentVolumeClaim(inv.parameters.gerrit.server.deployment.volumes.reviewsite.name) + { storage: inv.parameters.gerrit.server.deployment.volumes.reviewsite.storage },
    database: kube.PersistentVolumeClaim(inv.parameters.gerrit.database.deployment.volumes.database.name) + { storage: inv.parameters.gerrit.database.deployment.volumes.database.storage },
}