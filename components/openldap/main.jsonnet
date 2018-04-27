local deployments = import "./deployments.jsonnet";
local secret = import "./secrets.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local name = inv.parameters.openldap.instance_name;

{
  local c = self,
  openldap_deployment: statefulset.OpenldapDeployment(name + "-server", self.openldap_secret),
  ldapadmin_deployment: statefulset.LdapAdminDeployment(name + "-admin", self.openldap_secret),
  openldap_secret: secret.OpenldapSecret(name),

  openldap_service: kube.Service(name + "-server") {
      target_pod:: c["openldap_deployment"].spec.template,
      target_container_name:: "openldap",
      spec+: { clusterIP: inv.parameters.openldap.server_ip }
  },
  ldapadmin_service: kube.Service(name + "-admin") {
      target_pod:: c["ldapadmin_deployment"].spec.template,
      target_container_name:: "ldapadmin",
      spec+: { clusterIP: inv.parameters.openldap.admin_ip }
  },
}