with import <nixpkgs> {};

stdenv.mkDerivation {
  name = "Sui";
  buildInputs = with pkgs; [
    clang_14
    llvmPackages_14.libclang
    openssl
    pkg-config
  ];
  shellHook = ''
    export LIBCLANG_PATH="${pkgs.llvmPackages_14.libclang.lib}/lib";
  '';
}