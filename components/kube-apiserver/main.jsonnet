local daemonsets = import "./daemonsets.jsonnet";
local secrets = import "./secrets.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local server = inv.parameters.kubeapiserver.server;

{
  local c = self,
  kube_apiserver_daemonset: daemonsets.KubeApiServerDaemonSet(server.daemonset.name),
  kubeapiserver_secret: secrets.kubeapiserver_secret,
}