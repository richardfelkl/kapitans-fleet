local deployments = import "./deployments.jsonnet";
local pvcs = import "./pvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.gerrit.server;
local database = inv.parameters.gerrit.database;

{
  local c = self,
  gerrit_deployment: deployments.GerritDeployment(server.deployment.name),
  mysql_deployment: deployments.MysqlDeployment(database.deployment.name),

  gerrit_service: kube.Service(server.service.name) {
      type:: server.service.type,
      target_pod:: c["gerrit_deployment"].spec.template,
      target_container_name:: "gerrit",
      spec+:{
          clusterIP: if ("clusterip" in server.service) then server.service.clusterip else {},
      },
  },
  mysql_service: kube.Service(database.service.name) {
      type:: database.service.type,
      target_pod:: c["mysql_deployment"].spec.template,
      target_container_name:: "mysql",
      spec+:{
          clusterIP: if ("clusterip" in database.service) then database.service.clusterip else {},
      },
  },
  gerrit_pvc_reviewsite: if (server.deployment.volumes.reviewsite.type == "PersistentVolumeClaim") then pvcs.reviewsite else {},
  gerrit_pvc_database: if (database.deployment.volumes.database.type == "PersistentVolumeClaim") then pvcs.database else {},
}