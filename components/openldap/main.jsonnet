local deployments = import "./deployments.jsonnet";
local pvcs = import "./pvcs.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local ldapadmin = inv.parameters.openldap.ldapadmin;
local server = inv.parameters.openldap.server;
local secret = inv.parameters.openldap.secret;

{
  local c = self,

  openldap_secret: kube.Secret(secret.name) {
    data_: {
      "LDAP_ADMIN_PASSWORD": secret.data.admin_password,
      "LDAP_CONFIG_PASSWORD": secret.data.config_password,
    }
  },

  openldap_deployment: deployments.OpenldapDeployment(server.deployment.name){
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            openldap+: { env_+: { LDAP_ADMIN_PASSWORD: kube.SecretKeyRef($.openldap_secret, "LDAP_ADMIN_PASSWORD"), LDAP_CONFIG_PASSWORD: kube.SecretKeyRef($.openldap_secret, "LDAP_CONFIG_PASSWORD")} }
          }
        },
      },
    },
  },

  ldapadmin_deployment: deployments.LdapAdminDeployment(ldapadmin.deployment.name){
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            ldapadmin+: { env_+: { PHPLDAPADMIN_LDAP_HOSTS: "#PYTHON2BASH:[{'server': [{'server': [{'tls': False},{'host':'" + inv.parameters.openldap.server.service.name +
                                  "'}]},{'login': [{'bind_id': 'cn=admin," + inv.parameters.openldap.global.ldap_domain + "'},{'bind_pass': '" + kube.SecretKeyRef($.openldap_secret, "LDAP_ADMIN_PASSWORD") + "'}]}]}]"} }
          },
        },
      },
    },
  },

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