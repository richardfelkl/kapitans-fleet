local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local gerrit_volume = kube.HostPathVolume(inv.parameters.gerrit.server.deployment.volumes.reviewsite);
local mysql_volume = kube.HostPathVolume(inv.parameters.gerrit.database.deployment.volumes.database);

local gerrit_container = kube.Container("gerrit") {
  image: inv.parameters.gerrit.server.deployment.image,

  ports_+: {
    http: { containerPort: 8080 },
    ssh: { containerPort: 29418 },
  },

  env_+: if ("env" in inv.parameters.gerrit.server.deployment) then inv.parameters.gerrit.server.deployment.env else {}
};

local mysql_container = kube.Container("mysql") {
  image: inv.parameters.gerrit.database.deployment.image,

  ports_+: {
    mysql: { containerPort: 3306 },
  },

  env_+: if ("env" in inv.parameters.gerrit.database.deployment) then inv.parameters.gerrit.database.deployment.env else {}
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
