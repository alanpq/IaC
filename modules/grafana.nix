{config, ...}: {
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
        };

        # Prevents Grafana from phoning home
        analytics.reporting_enabled = false;
      };
      provision = {
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
            isDefault = true;
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
      }
    }

    otelcol.processor.batch "default" {
      output {
        metrics = [otelcol.exporter.prometheus.default.input]
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
  '';
}
