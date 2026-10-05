{
  config,
  pkgs,
  ...
}: let
  mkPlugin = {
    pname,
    version,
    hash,
  }:
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit pname version;
      src = pkgs.fetchurl {
        url = "https://grafana.com/api/plugins/${finalAttrs.pname}/versions/${finalAttrs.version}/download";
        inherit hash;
      };
      nativeBuildInputs = [pkgs.unzip];
      sourceRoot = ".";
      installPhase = ''
        mkdir -p $out
        cp -r . $out/
      '';
    });
in {
  imports = [
    ./node_exporter.nix
  ];
  services = {
    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 9911;
          enforce_domain = false;
          enable_gzip = true;
          domain = "grafana.alanp.me";

          # Alternatively, if you want to serve Grafana from a subpath:
          # domain = "your.domain";
          # root_url = "https://your.domain/grafana/";
          # serve_from_sub_path = true;
        };

        security = {
          admin_user = "admin";
          admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
          secret_key = "SW2YcwTIb9zpOOhoPsMm"; # TODO: rotate this & use sops
        };

        # Prevents Grafana from phoning home
        analytics.reporting_enabled = false;
      };
      declarativePlugins = with pkgs.grafanaPlugins; [
      ];
      provision = {
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
            isDefault = true;
          }
          {
            name = "Tempo";
            type = "tempo";
            url = "http://127.0.0.1:3200";
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://127.0.0.1:3100";
          }
        ];
      };
    };
    caddy.virtualHosts."grafana.alanp.me".extraConfig = let
      cfg = config.services.grafana.settings.server;
    in ''
      reverse_proxy http://${cfg.http_addr}:${toString cfg.http_port}
    '';

    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9090;

      extraFlags = [
        "--web.enable-remote-write-receiver"
      ];
    };

    alloy = {
      enable = true;

      configPath = "/etc/alloy/config.alloy";
    };

    tempo = {
      enable = true;
      settings = {
        server = {
          http_listen_port = 3200;
          grpc_listen_port = 9096;
        };
        # Alloy forwards traces here over OTLP/gRPC.
        distributor.receivers.otlp.protocols.grpc.endpoint = "127.0.0.1:4319";
        ingester.max_block_duration = "5m";
        compactor.compaction.block_retention = "48h";
        storage.trace = {
          backend = "local";
          wal.path = "/var/lib/tempo/wal";
          local.path = "/var/lib/tempo/blocks";
        };
      };
    };

    loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server = {
          http_listen_port = 3100;
          grpc_listen_port = 9095;
        };
        common = {
          instance_addr = "127.0.0.1";
          path_prefix = "/var/lib/loki";
          storage.filesystem = {
            chunks_directory = "/var/lib/loki/chunks";
            rules_directory = "/var/lib/loki/rules";
          };
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
        };
        schema_config.configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
    };
  };

  sops.secrets.grafana-admin-password = {
    owner = "grafana";
    group = "grafana";
  };

  environment.etc."alloy/config.alloy".text = ''
    otelcol.receiver.otlp "default" {
      grpc {
        endpoint = "127.0.0.1:4317"
      }

      http {
        endpoint = "127.0.0.1:4318"
      }

      output {
        metrics = [otelcol.processor.batch.default.input]
        traces  = [otelcol.processor.batch.default.input]
        logs    = [otelcol.processor.batch.default.input]
      }
    }

    otelcol.processor.batch "default" {
      output {
        metrics = [otelcol.exporter.prometheus.default.input]
        traces  = [otelcol.exporter.otlp.tempo.input]
        logs    = [otelcol.exporter.loki.default.input]
      }
    }

    otelcol.exporter.prometheus "default" {
      forward_to = [prometheus.remote_write.default.receiver]
    }

    prometheus.remote_write "default" {
      endpoint {
        url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}/api/v1/write"
      }
    }

    otelcol.exporter.otlp "tempo" {
      client {
        endpoint = "127.0.0.1:4319"
        tls {
          insecure = true
        }
      }
    }

    otelcol.exporter.loki "default" {
      forward_to = [loki.write.default.receiver]
    }

    loki.write "default" {
      endpoint {
        url = "http://127.0.0.1:3100/loki/api/v1/push"
      }
    }
  '';
}
