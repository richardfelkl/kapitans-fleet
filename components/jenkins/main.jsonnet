local deployments = import "./deployments.jsonnet";
local pvcs = import "./pvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local master = inv.parameters.jenkins.master;

{
  local c = self,
  jenkins_deployment: deployments.JenkinsMaterDeployment(master.deployment.name),

  jenkins_service: kube.Service(master.service.name) {
      type:: master.service.type,
      target_pod:: c["jenkins_deployment"].spec.template,
      target_container_name:: "jenkinsmaster",
      spec+:{
        clusterIP: if( "clusterip" in inv.parameters.jenkins.master.service) then inv.parameters.jenkins.master.service.clusterip else {},
      },
  },
  jenkins_pvc_jenkinshome: if (master.deployment.volumes.jenkinshome.type == "PersistentVolumeClaim") then pvcs.jenkinshome else {},
}