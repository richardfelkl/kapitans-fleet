local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local ldap_db_volume = kube.HostPathVolume(inv.parameters.openldap.server.deployment.volumes.database);
local ldap_config_volume = kube.HostPathVolume(inv.parameters.openldap.server.deployment.volumes.config);

local openldap_container = kube.Container("openldap") {
  image: inv.parameters.openldap.server.deployment.image.registry +
         inv.parameters.openldap.server.deployment.image.name +
         inv.parameters.openldap.server.deployment.image.tag,

  ports_+: {
    ldap: { containerPort: 389 },
    ldaps: { containerPort: 636 },
  },

  env_+: if ("env" in inv.parameters.openldap.server.deployment) then inv.parameters.openldap.server.deployment.env else {}
};

local ldapadmin_container = kube.Container("ldapadmin") {
  image: inv.parameters.openldap.ldapadmin.deployment.image.registry +
         inv.parameters.openldap.ldapadmin.deployment.image.name +
         inv.parameters.openldap.ldapadmin.deployment.image.tag,

  ports_+: {
    ldap: { containerPort: 80 },
  },

  env_+: if ("env" in inv.parameters.openldap.ldapadmin.deployment) then inv.parameters.openldap.ldapadmin.deployment.env else {}
};

{
  OpenldapDeployment(name): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            openldap: openldap_container
          },
          volumes_+:{
            ldap_database: ldap_db_volume,
            ldap_config: ldap_config_volume,
          },
        },
      },
    },
  },
  LdapAdminDeployment(name): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            ldapadmin: ldapadmin_container
          },
        },
      },
    },
  },
}
