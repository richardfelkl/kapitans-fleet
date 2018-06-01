local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local master_volumes = inv.parameters.jenkins.master.deployment.containers.jenkins.volumes;

{
    jenkinshome: kube.PersistentVolumeClaim(master_volumes.jenkinshome.name) + { storage: master_volumes.jenkinshome.storage },
}