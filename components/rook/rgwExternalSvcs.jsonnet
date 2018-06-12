local kube = import "lib/kube.libjsonnet";
local kap = import "lib/kapitan.libjsonnet";
local inv = kap.inventory();
local svc = inv.parameters.rook.rgw_external_service;

{
  ports: [
    {
      name: p["name"],
      port: p["port"],
      protocol: p["protocol"],
      targetPort: p["target_port"],
    } for p in svc.ports
  ],
}

{
  RookRgwExternalSvc(apiVersion, kind, name): kube.CustomResource(apiVersion, kind, name) {
    metadata+: {
      labels+: svc.label,
    },
    spec+: {
      ports: $.ports,
      selector: svc.selector,
      sessionAffinity: svc.session_afinity,
      type: svc.type,
    },
  },
}
