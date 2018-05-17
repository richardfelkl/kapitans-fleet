local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.gerrit.server;
local database = inv.parameters.gerrit.database;

local gerrit_pvcs = import "./pvcs.jsonnet";

local gerrit_volume =
if (server.deployment.volumes.reviewsite.type == "HostPath") then
  kube.HostPathVolume(server.deployment.volumes.reviewsite.path)
else if (server.deployment.volumes.reviewsite.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(gerrit_pvcs.reviewsite);

local mysql_volume =
if (database.deployment.volumes.database.type == "HostPath") then
  kube.HostPathVolume(database.deployment.volumes.database.path)
else if (database.deployment.volumes.database.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(gerrit_pvcs.database);

local gerrit_container = kube.Container("gerrit") {
  image: server.deployment.image.registry + "/" +
         server.deployment.image.name + ":" +
         server.deployment.image.tag,

  ports_+: {
    http: { containerPort: 8080 },
    ssh: { containerPort: 29418 },
  },

  volumeMounts: [
  {
    mountPath: "/var/gerrit/review_site",
    name: "reviewsite",
  }],

  env_+: if ("env" in server.deployment) then server.deployment.env else {},

  readinessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
    initialDelaySeconds: 180
  },
};

local mysql_container = kube.Container("mysql") {
  image: database.deployment.image.registry + "/" +
         database.deployment.image.name + ":" +
         database.deployment.image.tag,

  ports_+: {
    mysql: { containerPort: 3306 },
  },

  volumeMounts: [
  {
    mountPath: "/var/lib/mysql",
    name: "database",
  }],

  env_+: if ("env" in database.deployment) then database.deployment.env else {},

  livenessProbe: {
    exec:{
      command: [ "sh", "-c", "mysqladmin ping -u root -p${MYSQL_ROOT_PASSWORD}"]
    },
    initialDelaySeconds: 30,
    periodSeconds: 10,
    timeoutSeconds: 5,
    successThreshold: 1,
    failureThreshold: 3,
  },
  readinessProbe: {
    exec:{
      command: [ "sh", "-c", "mysqladmin ping -u root -p${MYSQL_ROOT_PASSWORD}"]
    },
    initialDelaySeconds: 30,
    periodSeconds: 10,
    timeoutSeconds: 5,
    successThreshold: 1,
    failureThreshold: 3,
  },
};

{
  GerritDeployment(name): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            gerrit: gerrit_container
          },
          volumes_+:{
            reviewsite: gerrit_volume
          },
        },
      },
    },
  },
  MysqlDeployment(name): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            mysql: mysql_container
          },
          volumes_+:{
            database: mysql_volume
          },
        },
      },
    },
  },
}
