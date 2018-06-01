local deployments = import "./deployments.jsonnet";
local pvcs = import "./pvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.mysql.server;
local secret = inv.parameters.mysql.secret;

{
  local c = self,

  mysql_secret: kube.Secret(secret.name) {
    data_: {
      "MYSQL_DB_PASSWORD": secret.data.mysql_db_password,
      "MYSQL_ROOT_PASSWORD": secret.data.mysql_root_password,
    }
  },

 mysql_deployment: deployments.MysqlDeployment(server.deployment.name){
   spec+: {
     template+: {
       spec+: {
         containers_+: {
           mysql+: { env_+: { MYSQL_ROOT_PASSWORD: kube.SecretKeyRef($.mysql_secret, "MYSQL_ROOT_PASSWORD"), MYSQL_PASSWORD: kube.SecretKeyRef($.mysql_secret, "MYSQL_DB_PASSWORD")} }
         },
       },
     },
   },
 },

  mysql_service: kube.Service(server.service.name) {
      type:: server.service.type,
      target_pod:: c["mysql_deployment"].spec.template,
      target_container_name:: "mysql",
      spec+:{
          clusterIP: if ("clusterip" in server.service) then server.service.clusterip else {},
          loadBalancerIP: if ("loadbalancerip" in server.service) then server.service.loadbalancerip else {},
      },
  },
  mysql_pvc_database: if (server.deployment.containers.mysql.volumes.database.type == "PersistentVolumeClaim") then pvcs.database else {},
}