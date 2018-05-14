local openldap = import "../components/openldap/main.jsonnet";
local jenkins = import "../components/jenkins/main.jsonnet";
local gerrit = import "../components/gerrit/main.jsonnet";
local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();

{
  cicd_secret: kube.Secret(inv.parameters.cicd_stack.secrets.cicd_secret.name) {
    data_: {
      "LDAP_ADMIN_PASSWORD": inv.parameters.cicd_stack.secrets.cicd_secret.admin_password,
      "LDAP_CONFIG_PASSWORD": inv.parameters.cicd_stack.secrets.cicd_secret.config_password,
      "GERRIT_DB_PASSWORD": inv.parameters.cicd_stack.secrets.cicd_secret.gerrit_db_password,
      "MYSQL_ROOT_PASSWORD": inv.parameters.cicd_stack.secrets.cicd_secret.mysql_root_password,
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

  ldapadmin_deployment+: openldap.ldapadmin_deployment{
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            ldapadmin+: { env_+: { PHPLDAPADMIN_LDAP_HOSTS: "#PYTHON2BASH:[{'server': [{'server': [{'tls': False},{'host':'" + inv.parameters.openldap.server.service.name +
                                  "'}]},{'login': [{'bind_id': 'cn=admin," + inv.parameters.openldap.global.ldap_domain + "'},{'bind_pass': '" + kube.SecretKeyRef($.cicd_secret, "LDAP_ADMIN_PASSWORD") + "'}]}]}]"} }
          },
        },
      },
    },
  },

  gerrit_deployment+: gerrit.gerrit_deployment{
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            gerrit+: { env_+: { DB_ENV_MYSQL_PASSWORD: kube.SecretKeyRef($.cicd_secret, "GERRIT_DB_PASSWORD"), LDAP_PASSWORD: kube.SecretKeyRef($.cicd_secret, "LDAP_ADMIN_PASSWORD"),
                                GERRIT_ADMIN_PWD: kube.SecretKeyRef($.cicd_secret, "LDAP_ADMIN_PASSWORD")} }
          },
        },
      },
    },
  },

  mysql_deployment+: gerrit.mysql_deployment{
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            mysql+: { env_+: { MYSQL_ROOT_PASSWORD: kube.SecretKeyRef($.cicd_secret, "MYSQL_ROOT_PASSWORD"), MYSQL_PASSWORD: kube.SecretKeyRef($.cicd_secret, "GERRIT_DB_PASSWORD")} }
          },
        },
      },
    },
  },

  openldap_service+: openldap.openldap_service{
      spec+: { clusterIP: inv.parameters.openldap.server.service.ip }
  },

  ldapadmin_service+: openldap.ldapadmin_service{
      spec+: { clusterIP: inv.parameters.openldap.ldapadmin.service.ip }
  },

  jenkins_service+: jenkins.jenkins_service{
      spec+: { clusterIP: inv.parameters.jenkins.master.service.ip }
  },

  gerrit_service+: gerrit.gerrit_service{
      spec+: { clusterIP: inv.parameters.gerrit.server.service.ip }
  },

  mysql_service+: gerrit.mysql_service{
      spec+: { clusterIP: inv.parameters.gerrit.database.service.ip }
  },
}