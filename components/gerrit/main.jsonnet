local deployments = import "./deployments.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  local c = self,
  gerrit_deployment: deployments.GerritDeployment(inv.parameters.gerrit.server.deployment.name),
  mysql_deployment: deployments.MysqlDeployment(inv.parameters.gerrit.database.deployment.name),

  gerrit_service: kube.Service(inv.parameters.gerrit.server.service.name) {
      target_pod:: c["gerrit_deployment"].spec.template,
      target_container_name:: "gerrit",
  },
  mysql_service: kube.Service(inv.parameters.gerrit.database.service.name) {
      target_pod:: c["mysql_deployment"].spec.template,
      target_container_name:: "mysql",
  },
}