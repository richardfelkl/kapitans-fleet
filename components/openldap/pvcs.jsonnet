local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server_volumes = inv.parameters.openldap.server.deployment.containers.openldap.volumes;

{
    database: kube.PersistentVolumeClaim(server_volumes.database.name) + { storage: server_volumes.database.storage },
    ldapconfig: kube.PersistentVolumeClaim(server_volumes.config.name) + { storage: server_volumes.config.storage }
}