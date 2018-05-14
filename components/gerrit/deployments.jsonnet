local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local gerrit_volume = kube.HostPathVolume(inv.parameters.gerrit.server.deployment.volumes.reviewsite);
local mysql_volume = kube.HostPathVolume(inv.parameters.gerrit.database.deployment.volumes.database);

local gerrit_container = kube.Container("gerrit") {
  image: inv.parameters.gerrit.server.deployment.image.registry + "/" +
         inv.parameters.gerrit.server.deployment.image.name + ":" +
         inv.parameters.gerrit.server.deployment.image.tag,

  ports_+: {
    http: { containerPort: 8080 },
    ssh: { containerPort: 29418 },
  },

  volumeMounts: [
  {
    mountPath: "/var/gerrit/review_site",
    name: "reviewsite",
  }],

  env_+: if ("env" in inv.parameters.gerrit.server.deployment) then inv.parameters.gerrit.server.deployment.env else {},

  readinessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
    initialDelaySeconds: 180
  },
};

local mysql_container = kube.Container("mysql") {
  image: inv.parameters.gerrit.database.deployment.image.registry + "/" +
         inv.parameters.gerrit.database.deployment.image.name + ":" +
         inv.parameters.gerrit.database.deployment.image.tag,

  ports_+: {
    mysql: { containerPort: 3306 },
  },

  volumeMounts: [
  {
    mountPath: "/var/lib/mysql",
    name: "database",
  }],

  env_+: if ("env" in inv.parameters.gerrit.database.deployment) then inv.parameters.gerrit.database.deployment.env else {},

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
