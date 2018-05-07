local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  OpenldapSecret(name): kube.Secret(name) {
    data_: {
      "LDAP_ADMIN_PASSWORD": inv.parameters.openldap.secret.admin_password,
      "LDAP_CONFIG_PASSWORD": inv.parameters.openldap.secret.config_password,
    }
  }
}
