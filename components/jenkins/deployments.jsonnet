local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local master = inv.parameters.jenkins.master;

local jenkins_pvcs = import "./pvcs.jsonnet";

local jenkins_home_volume =
if (master.deployment.volumes.jenkinshome.type == "HostPath") then
  kube.HostPathVolume(master.deployment.volumes.jenkinshome.path)
else if (master.deployment.volumes.jenkinshome.type == "PersistentVolumeClaim") then
  kube.PersistentVolumeClaimVolume(jenkins_pvcs.jenkinshome);

local jenkins_master_container = kube.Container("jenkinsmaster") {
  image: master.deployment.image.registry + "/" +
         master.deployment.image.name + ":" +
         master.deployment.image.tag,

  ports_+: {
    http: { containerPort: 8080 },
    slavelistener: { containerPort: 50000 },
  },

  volumeMounts: [
  {
    mountPath: "/var/jenkins_home",
    name: "jenkinshome",
  }],

  env_+: if ("env" in master.deployment) then master.deployment.env else {},

  livenessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
    initialDelaySeconds: 180,
    periodSeconds: 20,
    timeoutSeconds: 10,
    failureThreshold: 12,
  },
  readinessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
    initialDelaySeconds: 180,
    periodSeconds: 20,
    timeoutSeconds: 10,
    failureThreshold: 12,
  },
};

{
  JenkinsMaterDeployment(name): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          securityContext:{
            fsGroup: 1000,
            runAsUser: 0
          },
          containers_+: {
            jenkinsmaster: jenkins_master_container
          },
          volumes_+:{
            jenkinshome: jenkins_home_volume
          },
        },
      },
    },
  },
}
