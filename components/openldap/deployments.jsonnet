local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local ldap_db_volume = kube.HostPathVolume(inv.parameters.openldap.volumes.database);
local ldap_config_volume = kube.HostPathVolume(inv.parameters.openldap.volumes.config);

{
  OpenldapDeployment(name, secret): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            openldap: containers.openldap_container + { env_+: { LDAP_ADMIN_PASSWORD: kube.SecretKeyRef(secret, "LDAP_ADMIN_PASSWORD"), LDAP_CONFIG_PASSWORD: kube.SecretKeyRef(secret, "LDAP_CONFIG_PASSWORD")} }
          },
          volumes_+:{
            ldap_database: ldap_db_volume,
            ldap_config: ldap_config_volume,
          },
        },
      },
    },
  },
  LdapAdminDeployment(name, secret): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            ldapAdmin: containers.ldapadmin_container
          },
        },
      },
    },
  },
}
