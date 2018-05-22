local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.gerrit.server;
local database = inv.parameters.gerrit.database;

{
    reviewsite: kube.PersistentVolumeClaim(server.deployment.volumes.reviewsite.name) + { storage: server.deployment.volumes.reviewsite.storage },
    database: kube.PersistentVolumeClaim(database.deployment.volumes.database.name) + { storage: database.deployment.volumes.database.storage },
}