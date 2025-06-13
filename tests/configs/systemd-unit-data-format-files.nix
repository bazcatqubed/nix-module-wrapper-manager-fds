{ config, lib, pkgs, ... }:

{
  dataFormats.enableExtraFormats = true;

  # Generating some systemd-networkd unit files ourselves.
  dataFormats.files."/etc/systemd/network/40-eno1.link" = {
    variant = "systemdIni";
    content = let
      settings = config.dataFormats.files."/etc/systemd/network/40-eno1.link".content;
    in {
      Match.OriginalName = "eno1";

      Network = {
        DHCP = "ipv4";
        LinkLocalAddressing = "ipv6";
        IPv6AcceptRa = true;
      };

      DHCPv4 = {
        RouteMetric = 100;
        UseMTU = true;
      };

      Routes = [
        {
          Gateway = "172.16.0.1";
          GatewayOnLink = true;
        }

        {
          Gateway = "fe80::1";
          GatewayOnLink = true;
        }
      ];
    };
  };

  dataFormats.files."/etc/systemd/network/40-enp3s0.link" = {
    variant = "systemdIni";
    content = {
      Match.OriginalName = "enp3s0";
    };
  };

  # If we want, we could just generate them systemd settings for ourselves.
  dataFormats.files."/etc/systemd/timesyncd.conf" = {
    variant = "systemdIni";
    content = {
      Time.FallbackNTP = [
        "ntp.nict.jp"
        "time.nist.gov"
        "time.facebook.com"
        "europe.pool.ntp.org"
        "asia.pool.ntp.org"
        "time.cloudflare.com"
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
      ];
    };
  };

  # tag::test[]
  build.extraPassthru.wrapperManagerTests = {
    actuallyBuilt = let
      wrapper = config.build.toplevel;
    in
      pkgs.runCommand "wrapper-manager-test-systemd-unit-data-format-files-actually-built" { } ''
        [ ! -d "${wrapper}/etc/systemd/user" ] \
        && [ -f "${wrapper}/etc/systemd/network/40-eno1.link" ] \
        && [ -f "${wrapper}/etc/systemd/network/40-enp3s0.link" ] \
        && [ -f "${wrapper}/etc/systemd/timesyncd.conf" ] \
        && touch $out
      '';
  };
  # end::test[]
}
