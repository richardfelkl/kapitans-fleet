local deployments = import "./deployments.jsonnet";
local pvcs = import "./pvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  local c = self,
  openldap_deployment: deployments.OpenldapDeployment(inv.parameters.openldap.server.deployment.name),
  ldapadmin_deployment: deployments.LdapAdminDeployment(inv.parameters.openldap.ldapadmin.deployment.name),

  openldap_service: kube.Service(inv.parameters.openldap.server.service.name) {
      type:: inv.parameters.openldap.server.service.type,
      target_pod:: c["openldap_deployment"].spec.template,
      target_container_name:: "openldap",
      spec+:{
          clusterIP: if ("clusterip" in inv.parameters.openldap.server.service ) then inv.parameters.openldap.server.service.clusterip else {},
      },
  },
  ldapadmin_service: kube.Service(inv.parameters.openldap.ldapadmin.service.name) {
      type:: inv.parameters.openldap.ldapadmin.service.type,
      target_pod:: c["ldapadmin_deployment"].spec.template,
      target_container_name:: "ldapadmin",
      spec+:{
          clusterIP: if ("clusterip" in inv.parameters.openldap.ldapadmin.service) then inv.parameters.openldap.ldapadmin.service.clusterip else {},
      },
  },
  openldap_pvc_database: if (inv.parameters.openldap.server.deployment.volumes.database.type == "PersistentVolumeClaim") then pvcs.database else {},
  openldap_pvc_ldapconfig: if (inv.parameters.openldap.server.deployment.volumes.config.type == "PersistentVolumeClaim") then pvcs.ldapconfig else {},
}