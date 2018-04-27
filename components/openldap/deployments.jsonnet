local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local ldap_db_volume = kube.HostPathVolume(inv.parameters.openldap.volumes.database);
local ldap_config_volume = kube.HostPathVolume(inv.parameters.openldap.volumes.config);

local openldap_container = kube.Container("openldap") {
  image: inv.parameters.openldap.image,

  ports_+: {
    ldap: { containerPort: 389 },
    ldaps: { containerPort: 636 },
  },

  env_+: if ("openldapenv" in inv.parameters.openldap) then inv.parameters.openldap.openldapenv else {}
};

local ldapadmin_container = kube.Container("ldapadmin") {
  image: inv.parameters.openldap.ldapadminimage,

  ports_+: {
    ldap: { containerPort: 80 },
  },

  env_+: if ("ldapadminenv" in inv.parameters.openldap) then inv.parameters.openldap.ldapadminenv else {}
};

{
  OpenldapDeployment(name, secret): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            openldap: openldap_container + { env_+: { LDAP_ADMIN_PASSWORD: kube.SecretKeyRef(secret, "LDAP_ADMIN_PASSWORD"), LDAP_CONFIG_PASSWORD: kube.SecretKeyRef(secret, "LDAP_CONFIG_PASSWORD")} }
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
            ldapAdmin: ldapadmin_container
          },
        },
      },
    },
  },
}
