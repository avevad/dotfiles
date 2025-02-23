{ pkgs }:

{
  DEPLOY = {
    PUSHY_REV = builtins.readFile ./deployment/pushy.txt;
    PUSHY_TEST_REV = builtins.readFile ./deployment/pushy_test.txt;
    PUSHY_DOCS_REV = builtins.readFile ./deployment/pushy_docs.txt;
  };

  HAPROXY_CERT = builtins.readFile ./secrets/haproxy.pem;
  HAPROXY_CERT_PUSHY = builtins.readFile ./secrets/haproxy_pushy.pem;

  TOKENS = import ./secrets/tokens.nix;
}
