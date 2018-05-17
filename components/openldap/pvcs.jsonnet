local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local master = inv.parameters.jenkins.master;

{
    database: kube.PersistentVolumeClaim("ldapdatabase") + { storage: inv.parameters.openldap.server.deployment.volumes.database.storage },
    ldapconfig: kube.PersistentVolumeClaim("ldapconfig") + { storage: inv.parameters.openldap.server.deployment.volumes.config.storage }
}