local kubeApiServer = import "../components/kube-apiserver/main.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  kube_apiserver_daemonset: kubeApiServer.kube_apiserver_daemonset,
  kubeapiserver_secret: kubeApiServer.kubeapiserver_secret
}