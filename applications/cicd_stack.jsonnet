local openldap = import "../components/openldap/main.jsonnet";
local jenkins = import "../components/jenkins/main.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  cicd_secret: kube.Secret(inv.parameters.cicd_stack.secrets.cicd_secret.name) {
    data_: {
      "LDAP_ADMIN_PASSWORD": inv.parameters.cicd_stack.secrets.cicd_secret.admin_password,
      "LDAP_CONFIG_PASSWORD": inv.parameters.cicd_stack.secrets.cicd_secret.config_password,
    }
  },

  jenkins_deployment+: jenkins.jenkins_deployment{
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            jenkinsmaster+: { env_+: { ADMIN_PASSWORD: kube.SecretKeyRef($.cicd_secret, "LDAP_ADMIN_PASSWORD")} }
          },
        },
      },
    },
  },

  jenkins_service: jenkins.jenkins_service,

  openldap_deployment+: openldap.openldap_deployment{
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            openldap+: { env_+: { LDAP_ADMIN_PASSWORD: kube.SecretKeyRef($.cicd_secret, "LDAP_ADMIN_PASSWORD"), LDAP_CONFIG_PASSWORD: kube.SecretKeyRef($.cicd_secret, "LDAP_CONFIG_PASSWORD")} }
          }
        },
      },
    },
  },

  ldapadmin_deployment: openldap.ldapadmin_deployment,

  openldap_service: openldap.openldap_service,

  ldapadmin_service: openldap.ldapadmin_service
}