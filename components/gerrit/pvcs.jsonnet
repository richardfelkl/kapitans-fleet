local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local gerrit_volumes = inv.parameters.gerrit.server.deployment.containers.gerrit.volumes;

{
    reviewsite: kube.PersistentVolumeClaim(gerrit_volumes.reviewsite.name) + { storage: gerrit_volumes.reviewsite.storage },
}