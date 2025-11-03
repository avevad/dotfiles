{ config, lib, pkgs, ... }:

let
  ENV = (import ./environment.nix) { pkgs = pkgs; };
in

{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = let
    ghcrAuth = {
      username = "avevad";
      passwordFile = "${pkgs.writeText "ghcr-token.txt" ENV.TOKENS.GITHUB_DEPLOY}";
      registry = "https://ghcr.io";
    };
  in {
    pushy-postgres = {
      image = "postgres:16";
      ports = [ "127.0.0.1:5432:5432" ];
      volumes = [ "/mnt/state/pushy/postgres:/var/lib/postgresql/data/pgdata" ];
      cmd = [ "-c" "log_checkpoints=false" ];
      environment = {
        POSTGRES_PASSWORD = "password";
        PGDATA = "/var/lib/postgresql/data/pgdata";
      };
      extraOptions = [ "--network=pushy" "--ip=192.168.1.101" ];
    };

    tonsbp-postgres = {
      image = "postgres:16";
      volumes = [ "/mnt/state/tonsbp/postgres:/var/lib/postgresql/data/pgdata" ];
      cmd = [ "-c" "log_checkpoints=false" ];
      environment = {
        POSTGRES_PASSWORD = "password";
        PGDATA = "/var/lib/postgresql/data/pgdata";
      };
      extraOptions = [ "--network=tonsbp" "--ip=192.168.2.101" ];
    };

    pushy-tgbot = {
      image = ENV.DEPLOY.PUSHY_REV;
      login = ghcrAuth;
      ports = [ "127.0.0.1:8000:8000" ];
      volumes = [ "${ ./secrets/voxapi-credentials.json }:/voxapi-credentials.json:ro" ];
      extraOptions = [ "--dns=10.100.0.1" "--network=pushy" ];
      environment = pkgs.lib.recursiveUpdate {
        PUSHY_TG_TOKEN=ENV.TOKENS.PUSHY_TG;
        PUSHY_DB_URL="postgresql+psycopg2://postgres:password@192.168.1.101/pushy";
        PUSHY_VERSION_SUFFIX="";
        PUSHY_VOXAPI_CREDS_FILE="/voxapi-credentials.json";
        PUSHY_VOXAPI_RULE_ID="8018889";
      } ENV.TOKENS.PUSHY_ENV_ETC;
    };

    pushy-test-tgbot = {
      image = ENV.DEPLOY.PUSHY_TEST_REV;
      login = ghcrAuth;
      cmd = [ "--root-path" "/api" ];
      ports = [ "127.0.0.1:8001:8000" ];
      extraOptions = [ "--dns=10.100.0.1" "--network=pushy" ];
      environment = pkgs.lib.recursiveUpdate {
        PUSHY_VERSION_SUFFIX="-${ builtins.substring 108 7 ENV.DEPLOY.PUSHY_TEST_REV }";
        PUSHY_DB_URL="postgresql+psycopg2://postgres:password@192.168.1.101/pushy_test";
        PUSHY_TG_TOKEN=ENV.TOKENS.PUSHY_TEST_TG;
      } ENV.TOKENS.PUSHY_TEST_ENV_ETC;
    };

    pushy-docs = {
      image = ENV.DEPLOY.PUSHY_DOCS_REV;
      login = ghcrAuth;
      ports = [ "127.0.0.1:8888:80" ];
    };

    tonsbp-server = {
      image = ENV.DEPLOY.TONSBP_SERVER_REV;
      login = ghcrAuth;
      ports = [ "127.0.0.1:8100:8000" ];
      extraOptions = [ "--dns=10.100.0.1" "--network=tonsbp" ];
      environment = {
        TONSBP_VERSION_SUFFIX="";
        TONSBP_PUSHY_API_KEY=ENV.TOKENS.TONSBP_PUSHY_API_KEY;
        TONSBP_PUSHY_WEBHOOK_ADMIN_KEY=ENV.TOKENS.TONSBP_PUSHY_WEBHOOK_ADMIN_KEY;
        TONSBP_WALLET_MAINNET="1";
        TONSBP_WALLET_MNEMONIC=ENV.TOKENS.TONSBP_WALLET_MNEMONIC;
        TONSBP_WALLET_ID=ENV.TOKENS.TONSBP_WALLET_ID;
        TONSBP_TONAPI_KEY=ENV.TOKENS.TONSBP_TONAPI_KEY;
        TONSBP_TONCENTER_KEY=ENV.TOKENS.TONSBP_TONCENTER_KEY;
        TONSBP_DB_URL="postgresql+psycopg2://postgres:password@192.168.2.101/tonsbp";
        TONSBP_CENTRAL_WEBHOOK_URL="https://tonsbp-central-api.helium.avevad.com/v1/payment?admin_key=${ ENV.TOKENS.TONSBP_PUSHY_WEBHOOK_ADMIN_KEY }";
      };
    };

    tonsbp-app = {
      image = ENV.DEPLOY.TONSBP_APP_REV;
      login = ghcrAuth;
      ports = [ "127.0.0.1:8337:80" ];
    };

    passmgr-vaultwarden = {
      image = "vaultwarden/server:1.33.0";
      ports = [ "127.0.0.1:8808:80" ];
      volumes = [ "/mnt/state/vaultwarden:/data" ];
      environment = {
        TZ = "Europe/Moscow";
        LOG_LEVEL = "error";
        EXTENDED_LOGGING = "true";
      };
    };

    metrics-prometheus = {
      image = "prom/prometheus";
      ports = [ "127.0.0.1:9090:9090" ];
      cmd = [
        "--config.file=/etc/prometheus/prometheus.yml"
        "--storage.tsdb.path=/prometheus"
        "--storage.tsdb.retention.time=1y"
        "--log.level=warn"
        "--enable-feature=exemplar-storage"
      ];
      volumes = [
        "${./etc/prometheus.yml}:/etc/prometheus/prometheus.yml:ro"
        "${./etc/prometheus.rules.yml}:/etc/prometheus/rules.yml:ro"
        "/mnt/state/prometheus:/prometheus"
      ];
      environment = {
        TZ="Europe/Moscow";
      };
      extraOptions = [ "--user=root" "--dns=10.100.0.1" ];
    };

    metrics-alertmanager = let
      alertmanagerYml = pkgs.writeText "alertmanager.yml" (builtins.replaceStrings
        [
          "@PUSHY_DEV_TEAM_WEBHOOK_URL@"
        ]
        [
          ENV.TOKENS.PUSHY_DEV_TEAM_ALERTS_URL
        ]
        (builtins.readFile ./etc/alertmanager.yml)
      );
    in {
      image = "prom/alertmanager";
      ports = [ "127.0.0.1:9093:9093" ];
      cmd = [
        "--config.file=/etc/alertmanager/alertmanager.yml"
        "--storage.path=/alertmanager"
        "--log.level=warn"
      ];
      volumes = [
        "${alertmanagerYml}:/etc/alertmanager/alertmanager.yml:ro"
        "/mnt/state/alertmanager:/alertmanager"
      ];
      environment = {
        TZ="Europe/Moscow";
      };
      extraOptions = [ "--user=root" "--dns=10.100.0.1" ];
    };

    metrics-grafana = {
      image = "grafana/grafana";
      ports = [ "127.0.0.1:3000:3000" ];
      volumes = [
        "/mnt/state/grafana:/var/lib/grafana"
      ];
      environment = {
        TZ="Europe/Moscow";
      };
      extraOptions = [ "--user=root" "--dns=10.100.0.1" ];
    };
  };
}
