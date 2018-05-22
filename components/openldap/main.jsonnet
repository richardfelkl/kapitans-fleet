local deployments = import "./deployments.jsonnet";
local pvcs = import "./pvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local ldapadmin = inv.parameters.openldap.ldapadmin;
local server = inv.parameters.openldap.server;

{
  local c = self,
  openldap_deployment: deployments.OpenldapDeployment(server.deployment.name),
  ldapadmin_deployment: deployments.LdapAdminDeployment(ldapadmin.deployment.name),

  openldap_service: kube.Service(server.service.name) {
      type:: server.service.type,
      target_pod:: c["openldap_deployment"].spec.template,
      target_container_name:: "openldap",
      spec+:{
          clusterIP: if ("clusterip" in server.service ) then server.service.clusterip else {},
      },
  },
  ldapadmin_service: kube.Service(ldapadmin.service.name) {
      type:: ldapadmin.service.type,
      target_pod:: c["ldapadmin_deployment"].spec.template,
      target_container_name:: "ldapadmin",
      spec+:{
          clusterIP: if ("clusterip" in ldapadmin.service) then ldapadmin.service.clusterip else {},
      },
  },
  openldap_pvc_database: if (server.deployment.volumes.database.type == "PersistentVolumeClaim") then pvcs.database else {},
  openldap_pvc_ldapconfig: if (server.deployment.volumes.config.type == "PersistentVolumeClaim") then pvcs.ldapconfig else {},
}