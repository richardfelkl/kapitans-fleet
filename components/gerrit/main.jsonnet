local deployments = import "./deployments.jsonnet";
local pvcs = import "./pvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  local c = self,
  gerrit_deployment: deployments.GerritDeployment(inv.parameters.gerrit.server.deployment.name),
  mysql_deployment: deployments.MysqlDeployment(inv.parameters.gerrit.database.deployment.name),

  gerrit_service: kube.Service(inv.parameters.gerrit.server.service.name) {
      type:: inv.parameters.gerrit.server.service.type,
      target_pod:: c["gerrit_deployment"].spec.template,
      target_container_name:: "gerrit",
      spec+:{
          clusterIP: if ("clusterip" in inv.parameters.gerrit.server.service) then inv.parameters.gerrit.server.service.clusterip else {},
      },
  },
  mysql_service: kube.Service(inv.parameters.gerrit.database.service.name) {
      type:: inv.parameters.gerrit.database.service.type,
      target_pod:: c["mysql_deployment"].spec.template,
      target_container_name:: "mysql",
      spec+:{
          clusterIP: if ("clusterip" in inv.parameters.gerrit.database.service) then inv.parameters.gerrit.database.service.clusterip else {},
      },
  },
  gerrit_pvc_reviewsite: if (inv.parameters.gerrit.server.deployment.volumes.reviewsite.type == "PersistentVolumeClaim") then pvcs.reviewsite else {},
  gerrit_pvc_database: if (inv.parameters.gerrit.database.deployment.volumes.database.type == "PersistentVolumeClaim") then pvcs.database else {},
}