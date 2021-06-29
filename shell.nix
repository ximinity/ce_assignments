with ((import (fetchTarball {
  name = "nixpkgs-master-2021-04-11";
  url = "https://github.com/nixos/nixpkgs/archive/a73020b2a150322c9832b50baeb0296ba3b13dd7.tar.gz";
  sha256 = "1s0ckc2qscrflr7bssd0s32zddp48dg5jk22w1dip2q2q7ks6cj0";
}) {}));
  let extensions = (with pkgs.vscode-extensions; [
      ms-vsliveshare.vsliveshare
      ms-vscode.cpptools
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
      name = "arm";
      publisher = "dan-c-underwood";
      version = "1.5.1";
      sha256 = "192hmfgfv7nqc942abkvxpg8fn5h90jn86m19ykmwn1fngxqa4yc";
    }] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
      name = "awesome-vhdl";
      publisher = "puorc";
      version = "0.0.1";
      sha256 = "1h55jahz8rpwyx14r3rqx9lsb00vzcj42pr95n4hhyipkbr3sc9z";
    }]);

  vscode-with-extensions = pkgs.vscode-with-extensions.override {
    vscodeExtensions = extensions;
  };

in pkgs.mkShell {
  buildInputs = [
    vscode-with-extensions
    # Software
    gcc-arm-embedded
    stlink
    python38
    python38Packages.pyserial
    qemu
    qemu-utils
    valgrind
    # Hardware
    ghdl
    gtkwave
  ];
}
