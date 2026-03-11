{ config, inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/persist/sops/age/keys.txt";

    secrets."sebi-password" = {
      neededForUsers = true;
    };
  };

  users.users.sebi.hashedPasswordFile = config.sops.secrets."sebi-password".path;
  users.mutableUsers = false;
}
