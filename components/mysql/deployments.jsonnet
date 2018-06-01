local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server_containers = inv.parameters.mysql.server.deployment.containers;

local mysql_pvcs = import "./pvcs.jsonnet";

local mysql_volume = if (server_containers.mysql.volumes.database.type == "HostPath") then
                      kube.HostPathVolume(server_containers.mysql.volumes.database.path)
                     else if (server_containers.mysql.volumes.database.type == "PersistentVolumeClaim") then
                      kube.PersistentVolumeClaimVolume(mysql_pvcs.database);

local mysql_container = kube.Container("mysql") {
  image: server_containers.mysql.image.registry + "/" +
         server_containers.mysql.image.name + ":" +
         server_containers.mysql.image.tag,

  args_+: if ("args" in server_containers.mysql) then server_containers.mysql.args else {},

  ports_+: {
    mysql: { containerPort: 3306 },
  },

  volumeMounts: [
  {
    mountPath: "/var/lib/mysql",
    name: "database",
  }],

  env_+: if ("env" in server_containers.mysql) then server_containers.mysql.env else {},

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