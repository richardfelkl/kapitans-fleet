local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local jenkins_home_volume = kube.HostPathVolume(inv.parameters.jenkins.master.deployment.volumes.jenkins_home);

local jenkins_master_container = kube.Container("jenkinsmaster") {
  image: inv.parameters.jenkins.master.deployment.image.registry + "/" +
         inv.parameters.jenkins.master.deployment.image.name + ":" +
         inv.parameters.jenkins.master.deployment.image.tag,

  ports_+: {
    http: { containerPort: 8080 },
    slavelistener: { containerPort: 50000 },
  },

  volumeMounts: [
  {
    mountPath: "/var/jenkins_home",
    name: "jenkins_home",
  }],

  env_+: if ("env" in inv.parameters.jenkins.master.deployment) then inv.parameters.jenkins.master.deployment.env else {},

  livenessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
    initialDelaySeconds: 180,
  },
  readinessProbe: {
    httpGet:{
      path: "/",
      port: "http"
    },
    initialDelaySeconds: 180,
  },
};

{
  JenkinsMaterDeployment(name): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            jenkinsmaster: jenkins_master_container
          },
          volumes_+:{
            jenkins_home: jenkins_home_volume
          },
        },
      },
    },
  },
}
