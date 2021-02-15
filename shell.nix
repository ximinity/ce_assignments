with (import <nixpkgs> {});
let extensions = (with pkgs.vscode-extensions; [
      ms-vsliveshare.vsliveshare
      ms-vscode.cpptools
    ]);
  vscode-with-extensions = pkgs.vscode-with-extensions.override {
      vscodeExtensions = extensions;
    };
in pkgs.mkShell {
  buildInputs = [
    gcc-arm-embedded
    stlink
    python38
    python38Packages.pyserial
    qemu
    qemu-utils
    vscode-with-extensions
  ];
}
