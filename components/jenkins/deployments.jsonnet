local containers = import "./containers.libjsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

local jenkins_home_volume = kube.HostPathVolume(inv.parameters.jenkins.master.deployment.volumes.jenkins_home);

local jenkins_master_container = kube.Container("jenkinsMaster") {
  image: inv.parameters.jenkins.master.deployment.image,

  ports_+: {
    http: { containerPort: 8080 },
    slaveListener: { containerPort: 50000 },
  },

  env_+: if ("env" in inv.parameters.jenkins.master.deployment) then inv.parameters.jenkins.master.deployment.env else {}
};

{
  JenkinsMaterDeployment(name): kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            jenkinsMaster: jenkins_master_container
          },
          volumes_+:{
            jenkins_home: jenkins_home_volume
          },
        },
      },
    },
  },
}
