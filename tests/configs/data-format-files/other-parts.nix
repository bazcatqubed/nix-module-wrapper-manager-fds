{ config, lib, pkgs, ... }: {
  dataFormats.files."/etc/app/config.json".content = let
    cfg = config.dataFormats.files."/etc/app/config.json".content;
  in {
    words.allowlist = lib.mkIf (cfg.allowAll or false) [
      "OK"
    ];

    words.greeting = lib.mkIf (cfg.startGreeting or false) [
      "WHOA"
    ];
  };

  dataFormats.files."/etc/com.example.SampleApp/config".content = let
    cfg = config.dataFormats.files."/etc/com.example.SampleApp/config".content;
    race = lib.strings.toLower cfg.race;
  in {
    battle.skills = lib.mkMerge [
      (lib.mkIf (race == "human") [ "Persuasion" "Endurance running" ])

      (lib.mkIf (race == "orc") [ "Bloodlust" "Berserker" ])

      (lib.mkIf (race == "automaton") [ "All-seeing scanner" ])

      (lib.mkIf (race == "undead") [ "Plague immunity" ])
    ];
  };
}
