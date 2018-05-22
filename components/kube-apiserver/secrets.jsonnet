local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local secret = inv.parameters.kubeapiserver.secret;

{
  kubeapiserver_secret: kube.Secret(secret.name){
    data_: {
      "apiserver.crt": secret.data.apiserver_crt,
      "apiserver.key": secret.data.apiserver_key,
      "ca.crt": secret.data.ca_crt,
      "etcd-client-ca.crt": secret.data.etcd_client_ca_crt,
      "etcd-client.crt": secret.data.etcd_client_crt,
      "etcd-client.key": secret.data.etcd_client_key,
      "service-account.pub": secret.data.service_account_pub,
    }
  },
}