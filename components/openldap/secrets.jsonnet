local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  OpenldapSecret(name): kube.Secret(name) {
    data_: {
      "LDAP_ADMIN_PASSWORD": inv.parameters.openldap.admin_password,
      "LDAP_CONFIG_PASSWORD": inv.parameters.openldap.config_password,
    }
  }
}
