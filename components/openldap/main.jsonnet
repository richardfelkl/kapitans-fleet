local deployments = import "./deployments.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  local c = self,
  openldap_deployment: deployments.OpenldapDeployment(inv.parameters.openldap.server.deployment.name),
  ldapadmin_deployment: deployments.LdapAdminDeployment(inv.parameters.openldap.ldapadmin.deployment.name),

  openldap_service: kube.Service(inv.parameters.openldap.server.service.name) {
      target_pod:: c["openldap_deployment"].spec.template,
      target_container_name:: "openldap",
      spec+: { clusterIP: inv.parameters.openldap.server.service.ip }
  },
  ldapadmin_service: kube.Service(inv.parameters.openldap.ldapadmin.service.name) {
      target_pod:: c["ldapadmin_deployment"].spec.template,
      target_container_name:: "ldapadmin",
      spec+: { clusterIP: inv.parameters.openldap.ldapadmin.service.ip }
  },
}