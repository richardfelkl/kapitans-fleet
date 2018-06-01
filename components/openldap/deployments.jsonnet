local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server_containers = inv.parameters.openldap.server.deployment.containers;
local ldapadmin_containers = inv.parameters.openldap.ldapadmin.deployment.containers;
local openldap_pvcs = import "./pvcs.jsonnet";

local ldap_db_volume =
if (server_containers.openldap.volumes.database.type == "HostPath") then
  kube.HostPathVolume(server_containers.openldap.volumes.database.path)
else if (server_containers.openldap.volumes.database.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(openldap_pvcs.database);

local ldap_config_volume =
if (server_containers.openldap.volumes.config.type == "HostPath") then
  kube.HostPathVolume(server_containers.openldap.volumes.config.path)
else if (server_containers.openldap.volumes.config.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(openldap_pvcs.ldapconfig);

local openldap_container = kube.Container("openldap") {
  image: server_containers.openldap.image.registry + "/" +
         server_containers.openldap.image.name + ":" +
         server_containers.openldap.image.tag,

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

  env_+: if ("env" in server_containers.openldap) then server_containers.openldap.env else {}
};

local ldapadmin_container = kube.Container("ldapadmin") {
  image: ldapadmin_containers.ldapadmin.image.registry + "/" +
         ldapadmin_containers.ldapadmin.image.name + ":" +
         ldapadmin_containers.ldapadmin.image.tag,
  ports_+: {
    http: { containerPort: 80 },
  },

  env_+: if ("env" in ldapadmin_containers.ldapadmin) then ldapadmin_containers.ldapadmin.env else {},

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
