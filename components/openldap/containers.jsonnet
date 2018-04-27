local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

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