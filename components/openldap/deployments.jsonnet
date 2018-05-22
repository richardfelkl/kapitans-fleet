local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.openldap.server;
local ldapadmin = inv.parameters.openldap.ldapadmin;
local openldap_pvcs = import "./pvcs.jsonnet";

local ldap_db_volume =
if (server.deployment.volumes.database.type == "HostPath") then
  kube.HostPathVolume(server.deployment.volumes.database.path)
else if (server.deployment.volumes.database.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(openldap_pvcs.database);

local ldap_config_volume =
if (server.deployment.volumes.config.type == "HostPath") then
  kube.HostPathVolume(server.deployment.volumes.config.path)
else if (server.deployment.volumes.config.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(openldap_pvcs.ldapconfig);

local openldap_container = kube.Container("openldap") {
  image: server.deployment.image.registry + "/" +
         server.deployment.image.name + ":" +
         server.deployment.image.tag,

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

  env_+: if ("env" in server.deployment) then server.deployment.env else {}
};

local ldapadmin_container = kube.Container("ldapadmin") {
  image: ldapadmin.deployment.image.registry + "/" +
         ldapadmin.deployment.image.name + ":" +
         ldapadmin.deployment.image.tag,
  ports_+: {
    http: { containerPort: 80 },
  },

  env_+: if ("env" in ldapadmin.deployment) then ldapadmin.deployment.env else {},

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
