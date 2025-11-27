{ ... }:
{
  imports = [
  ];

  wsl.enable = true;
  wsl.defaultUser = "nixos";
  users.users.sebi.isNormalUser = true;
}

