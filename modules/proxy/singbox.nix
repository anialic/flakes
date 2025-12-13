{ lib, ... }:
{
  modules.proxy = {
    options.singbox = {
      enable = lib.mkEnableOption "sing-box transparent proxy";
      mark = lib.mkOption {
        type = lib.types.int;
        default = 233;
        description = "fwmark for sing-box";
      };
      direct = lib.mkOption {
        type = lib.types.int;
        default = 234;
        description = "direct mark";
      };
      table = lib.mkOption {
        type = lib.types.int;
        default = 233;
        description = "routing table number";
      };
      configFile = lib.mkOption {
        example = lib.literalExpression ''assets + "/configs/singbox.json"'';
        default = null;
        type = lib.types.path;
        description = "Path to sing-box subscription config file";
      };
    };

    module =
      {
        node,
        pkgs,
        lib,
        ...
      }:
      lib.mkIf (node.proxy.enable && node.proxy.singbox.enable) (
        let
          preStart = pkgs.writeText "singbox-pre.sh" ''
            export OUTBOUNDS=$(mktemp)
            jq -r '[.outbounds[] | select(.type | contains("vmess", "shadowsocks"))]' \
              $CREDENTIALS_DIRECTORY/sub > $OUTBOUNDS
            export SELECT=$(mktemp)
            jq -r '[[.[].tag] | {tag: "s_select", type: "selector", outbounds: .}]' $OUTBOUNDS > $SELECT
            export URLTEST=$(mktemp)
            jq -r '[[.[].tag] | {tag: "s_auto", type: "urltest", outbounds: .}]' $OUTBOUNDS > $URLTEST

            cat ${singbox-config} $SELECT $URLTEST $OUTBOUNDS | jq -s -r '
              .[0].outbounds += .[1] + .[2] + .[3] | .[0]
            ' > /run/sing-box/config.json
          '';

          singbox-config = pkgs.writeText "config.json" (
            lib.generators.toJSON { } {
              route.rule_set = [
                {
                  type = "local";
                  tag = "s_geoip-cn";
                  format = "binary";
                  path = "${pkgs.sing-geoip}/share/sing-box/rule-set/geoip-cn.srs";
                }
                {
                  type = "local";
                  tag = "s_geosite-cn";
                  format = "binary";
                  path = "${pkgs.sing-geosite}/share/sing-box/rule-set/geosite-geolocation-cn.srs";
                }
                {
                  type = "local";
                  tag = "s_geosite-!cn";
                  format = "binary";
                  path = "${pkgs.sing-geosite}/share/sing-box/rule-set/geosite-geolocation-!cn.srs";
                }
              ];
              experimental.clash_api = {
                external_controller = "0.0.0.0:9090";
                external_ui = "${pkgs.zashboard}";
                default_mode = "Enhanced";
              };
              experimental.cache_file = {
                enabled = true;
                store_rdrc = true;
              };
              dns = {
                final = "remote";
                strategy = "ipv4_only";
                servers = [
                  {
                    type = "tls";
                    server = "8.8.8.8";
                    detour = "s_out";
                    tag = "remote";
                  }
                  {
                    type = "https";
                    server = "223.5.5.5";
                    tag = "local";
                  }
                ];
                rules = [
                  {
                    clash_mode = "Direct";
                    server = "local";
                  }
                  {
                    clash_mode = "Global";
                    server = "remote";
                  }
                  {
                    rule_set = "s_geosite-cn";
                    server = "local";
                  }
                  {
                    type = "logical";
                    mode = "and";
                    rules = [
                      {
                        rule_set = "s_geosite-!cn";
                        invert = true;
                      }
                      { rule_set = "s_geoip-cn"; }
                    ];
                    server = "remote";
                  }
                ];
              };
              inbounds = [
                {
                  type = "tproxy";
                  tag = "s_tproxy-in";
                  listen_port = 9898;
                }
              ];
              outbounds = [
                {
                  type = "selector";
                  tag = "s_out";
                  outbounds = [
                    "s_auto"
                    "s_select"
                    "s_direct"
                  ];
                  default = "s_auto";
                }
                {
                  type = "direct";
                  tag = "s_direct";
                }
              ];
              route = {
                rules = [
                  { action = "sniff"; }
                  {
                    type = "logical";
                    mode = "or";
                    rules = [
                      { protocol = "dns"; }
                      { port = 53; }
                    ];
                    action = "hijack-dns";
                  }
                  {
                    clash_mode = "Direct";
                    outbound = "s_direct";
                  }
                  {
                    clash_mode = "Global";
                    outbound = "s_out";
                  }
                  {
                    type = "logical";
                    mode = "or";
                    rules = [
                      { port = 853; }
                      {
                        network = "udp";
                        port = 443;
                      }
                      { protocol = "stun"; }
                    ];
                    action = "reject";
                  }
                  {
                    type = "logical";
                    mode = "and";
                    rules = [
                      { rule_set = "s_geoip-cn"; }
                      {
                        rule_set = "s_geosite-!cn";
                        invert = true;
                      }
                    ];
                    outbound = "s_direct";
                  }
                  {
                    rule_set = "s_geosite-cn";
                    outbound = "s_direct";
                  }
                  {
                    ip_is_private = true;
                    outbound = "s_direct";
                  }
                ];
                final = "s_out";
                auto_detect_interface = true;
                default_domain_resolver = "local";
              };
            }
          );
        in
        {
          boot.kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            "net.ipv4.conf.all.rp_filter" = 0;
          };

          networking.firewall.extraInputRules = ''
            meta mark ${toString node.proxy.singbox.mark} accept
          '';

          networking.nftables.tables.nixos-fw.content = lib.mkAfter ''
            define RESERVED_IP = {
                0.0.0.0/8,
                10.0.0.0/8,
                100.64.0.0/10,
                127.0.0.0/8,
                169.254.0.0/16,
                172.16.0.0/12,
                192.0.2.0/24,
                192.88.99.0/24,
                192.168.0.0/16,
                198.18.0.0/15,
                198.51.100.0/24,
                203.0.113.0/24,
                224.0.0.0/4,
                240.0.0.0/4,
            }
            chain singbox-input {
              type filter hook input priority mangle; policy accept;
              meta mark != ${toString node.proxy.singbox.mark} ct state new ct mark set ${toString node.proxy.singbox.direct}
            }
            chain singbox-output {
              type route hook output priority 10; policy accept;
              ct mark ${toString node.proxy.singbox.direct} return
              ip daddr $RESERVED_IP udp dport != 53 return
              ip daddr $RESERVED_IP tcp dport != 53 return
              ip protocol { tcp, udp } meta mark set ${toString node.proxy.singbox.mark}
            }
            chain singbox-prerouting {
              type filter hook prerouting priority mangle; policy accept;
              ip daddr $RESERVED_IP return
              ip protocol { tcp, udp } meta mark set ${toString node.proxy.singbox.mark} tproxy ip to 127.0.0.1:9898
            }
          '';

          systemd.network.networks.loopback = {
            matchConfig.Name = "lo";
            routes = [
              {
                Destination = "0.0.0.0/0";
                Type = "local";
                Table = node.proxy.singbox.table;
              }
            ];
            routingPolicyRules = [
              {
                FirewallMark = node.proxy.singbox.mark;
                Table = node.proxy.singbox.table;
              }
            ];
          };

          services.sing-box.enable = true;
          networking.nftables.checkRuleset = false;
          networking.firewall.checkReversePath = false;

          systemd.services.sing-box = {
            path = with pkgs; [ jq ];
            serviceConfig.LoadCredential = "sub:${node.proxy.singbox.configFile}";
            serviceConfig.ExecStartPre = lib.mkForce ''
              ${pkgs.bash}/bin/bash ${preStart}
            '';
          };
        }
      );
  };
}
