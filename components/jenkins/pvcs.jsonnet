local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local master = inv.parameters.jenkins.master;

{
    jenkinshome: kube.PersistentVolumeClaim(master.deployment.volumes.jenkinshome.name) + { storage: master.deployment.volumes.jenkinshome.storage },
}