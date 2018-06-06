local clusters = import "./clusters.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local mysql = inv.parameters.mysql;
local secret = mysql.secret;
local cluster = mysql.server.cluster;

{

  mysql_secret: kube.Secret(secret.name) {
    data_: {
      "MYSQL_DB_PASSWORD": secret.data.mysql_db_password,
      "MYSQL_ROOT_PASSWORD": secret.data.mysql_root_password,
    }
  },

  mysql_operator: clusters.MysqlCluster(cluster.api_version, cluster.kind, cluster.name),

}
