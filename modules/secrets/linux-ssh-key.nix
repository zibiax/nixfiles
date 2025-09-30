{ lib, user, ... }:
let
  secretPath = ../../secrets/ssh/id_ed25519.age;
in
{
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
// lib.mkIf (builtins.pathExists secretPath) {
  age.secrets."ssh/id_ed25519" = {
    file = secretPath;
    owner = user;
    group = "users";
    mode = "0600";
    path = "/home/${user}/.ssh/id_ed25519";
  };
}
