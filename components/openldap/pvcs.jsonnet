local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.openldap.server;

{
    database: kube.PersistentVolumeClaim("ldapdatabase") + { storage: server.deployment.volumes.database.storage },
    ldapconfig: kube.PersistentVolumeClaim("ldapconfig") + { storage: server.deployment.volumes.config.storage }
}