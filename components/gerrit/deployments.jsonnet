local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.gerrit.server;

local gerrit_pvcs = import "./pvcs.jsonnet";

local gerrit_volume =
if (server.deployment.volumes.reviewsite.type == "HostPath") then
  kube.HostPathVolume(server.deployment.volumes.reviewsite.path)
else if (server.deployment.volumes.reviewsite.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(gerrit_pvcs.reviewsite);

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
