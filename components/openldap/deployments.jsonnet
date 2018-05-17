local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local openldap_pvcs = import "./pvcs.jsonnet";

local ldap_db_volume =
if (inv.parameters.openldap.server.deployment.volumes.database.type == "HostPath") then
  kube.HostPathVolume(inv.parameters.openldap.server.deployment.volumes.database.path)
else if (inv.parameters.openldap.server.deployment.volumes.database.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(openldap_pvcs.database);

local ldap_config_volume =
if (inv.parameters.openldap.server.deployment.volumes.config.type == "HostPath") then
  kube.HostPathVolume(inv.parameters.openldap.server.deployment.volumes.config.path)
else if (inv.parameters.openldap.server.deployment.volumes.config.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(openldap_pvcs.ldapconfig);

local openldap_container = kube.Container("openldap") {
  image: inv.parameters.openldap.server.deployment.image.registry + "/" +
         inv.parameters.openldap.server.deployment.image.name + ":" +
         inv.parameters.openldap.server.deployment.image.tag,

  ports_+: {
    ldap: { containerPort: 389 },
    ldaps: { containerPort: 636 },
  },

  volumeMounts: [
  {
    mountPath: "/var/lib/ldap",
    name: "ldapdatabase",
  },
  {
    mountPath: "/etc/ldap/slapd.d",
    name: "ldapconfig",
  }],

  env_+: if ("env" in inv.parameters.openldap.server.deployment) then inv.parameters.openldap.server.deployment.env else {}
};

local ldapadmin_container = kube.Container("ldapadmin") {
  image: inv.parameters.openldap.ldapadmin.deployment.image.registry + "/" +
         inv.parameters.openldap.ldapadmin.deployment.image.name + ":" +
         inv.parameters.openldap.ldapadmin.deployment.image.tag,
  ports_+: {
    http: { containerPort: 80 },
  },

  env_+: if ("env" in inv.parameters.openldap.ldapadmin.deployment) then inv.parameters.openldap.ldapadmin.deployment.env else {},

  livenessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
  },
  readinessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
  },
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
            ldapdatabase: ldap_db_volume,
            ldapconfig: ldap_config_volume,
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
