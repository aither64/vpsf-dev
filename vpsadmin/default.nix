{ config, ... }:
{
  imports = [
    ./database.nix
    ./api.nix
    ./webui.nix
    ./redis.nix
    ./frontend.nix
    ./mailer.nix
    ./rabbitmq.nix
  ];
}
