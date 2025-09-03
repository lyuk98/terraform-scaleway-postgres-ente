{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    scaleway-cli
    terraform
    vault-bin
  ];
}
