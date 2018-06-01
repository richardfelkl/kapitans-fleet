local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server_containers = inv.parameters.gerrit.server.deployment.containers;

local gerrit_pvcs = import "./pvcs.jsonnet";

local gerrit_volume = if (server_containers.gerrit.volumes.reviewsite.type == "HostPath") then
                        kube.HostPathVolume(server_containers.gerrit.volumes.reviewsite.path)
                      else if (server_containers.gerrit.volumes.reviewsite.type == "PersistentVolumeClaim") then
                        kube.PersistentVolumeClaimVolume(gerrit_pvcs.reviewsite);

local gerrit_container = kube.Container("gerrit") {
  image: server_containers.gerrit.image.registry + "/" +
         server_containers.gerrit.image.name + ":" +
         server_containers.gerrit.image.tag,

  ports_+: {
    http: { containerPort: 8080 },
    ssh: { containerPort: 29418 },
  },

  volumeMounts: [
  {
    mountPath: "/var/gerrit/review_site",
    name: "reviewsite",
  }],

  env_+: if ("env" in server_containers.gerrit) then server_containers.gerrit.env else {},

  readinessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
    initialDelaySeconds: 180
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
}
