local deployments = import "./deployments.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  local c = self,
  jenkins_deployment: deployments.JenkinsMaterDeployment(inv.parameters.jenkins.master.deployment.name),

  jenkins_service: kube.Service(inv.parameters.jenkins.master.service.name) {
      target_pod:: c["jenkins_deployment"].spec.template,
      target_container_name:: "jenkinsMaster",
      spec+: { clusterIP: inv.parameters.jenkins.master.service.ip }
  },
}