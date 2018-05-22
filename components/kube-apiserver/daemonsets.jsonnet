local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local secrets = import "./secrets.jsonnet";
local inv = kap.inventory();

local sslcertshost_volume = kube.HostPathVolume(inv.parameters.kubeapiserver.server.daemonset.volumes.sslcertshost);
local secrets_volume = kube.SecretVolume(secrets.kubeapiserver_secret);
local sslcertshost2_volume = kube.HostPathVolume(inv.parameters.kubeapiserver.server.daemonset.volumes.sslcertshost2);

local kube_apiserver_container = kube.Container("kubeapiserver") {
  image: "k8s.gcr.io/hyperkube:v1.10.0",
  command: ["/hyperkube",
            "apiserver",
            "--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ValidatingAdmissionWebhook,ResourceQuota,DefaultTolerationSeconds,NodeRestriction,MutatingAdmissionWebhook",
            "--advertise-address=$(POD_IP)",
            "--allow-privileged=true",
            "--anonymous-auth=false",
            "--authorization-mode=Node,RBAC",
            "--bind-address=0.0.0.0",
            "--etcd-cafile=/etc/kubernetes/secrets/etcd-client-ca.crt",
            "--etcd-certfile=/etc/kubernetes/secrets/etcd-client.crt",
            "--etcd-keyfile=/etc/kubernetes/secrets/etcd-client.key",
            "--etcd-servers=https://192.168.10.93:4001,https://192.168.10.94:4001,https://192.168.10.92:4001",
            "--insecure-port=8080",
            "--secure-port=6443",
            "--service-cluster-ip-range=10.254.0.0/16",
            "--storage-backend=etcd3",
            "--tls-cert-file=/etc/kubernetes/secrets/apiserver.crt",
            "--tls-private-key-file=/etc/kubernetes/secrets/apiserver.key",
            "--client-ca-file=/etc/kubernetes/secrets/ca.crt"],
  volumeMounts: [
  {
    mountPath: "/etc/ssl/certs",
    name: "sslcertshost",
    readOnly: true,
  },
  {
    mountPath: "/etc/kubernetes/secrets",
    name: "secrets",
    readOnly: true,
  },
  {
    mountPath: "/etc/kubernetes/ssl",
    name: "sslcertshost2",
    readOnly: true,
  }],
};

{
  KubeApiServerDaemonSet(name): kube.DaemonSet(name) {
    spec+: {
      selector:{
        matchLabels:{
          tier: "control-plane",
          "k8s-app": "kube-apiserver"
        },
      },
      template+: {
        spec+: {
          containers_+: {
            kubeapiserver: kube_apiserver_container
          },
          volumes_+:{
            sslcertshost: sslcertshost_volume,
            secrets: secrets_volume,
            sslcertshost2: sslcertshost2_volume,
          },
          tolerations:[
            {
              key: "node-role.kubernetes.io/master",
              operator: "Exists",
              effect: "NoSchedule"
            },
          ],
        },
      },
    },
  },
}