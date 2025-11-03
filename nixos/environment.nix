{ pkgs }:

{
  DEPLOY = {
    PUSHY_REV = builtins.readFile ./deployment/pushy.txt;
    PUSHY_TEST_REV = builtins.readFile ./deployment/pushy_test.txt;
    PUSHY_DOCS_REV = builtins.readFile ./deployment/pushy_docs.txt;
    TONSBP_SERVER_TEST_REV = builtins.readFile ./deployment/tonsbp_server_test.txt;
    TONSBP_SERVER_REV = builtins.readFile ./deployment/tonsbp_server.txt;
    TONSBP_APP_REV = builtins.readFile ./deployment/tonsbp_app.txt;
  };

  HAPROXY_CERT = builtins.readFile ./secrets/haproxy.pem;
  HAPROXY_CERT_PUSHY = builtins.readFile ./secrets/haproxy_pushy.pem;
  HAPROXY_CERT_TONSBP = builtins.readFile ./secrets/haproxy_tonsbp.pem;
  HAPROXY_CERT_PRO = builtins.readFile ./secrets/haproxy_pro.pem;

  TOKENS = import ./secrets/tokens.nix;
}
