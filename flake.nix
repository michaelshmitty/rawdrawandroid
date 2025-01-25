{
  description = "Flake for rawandroid";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    devshell,
    ...
  } @ inputs: let
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];

    forAllSystems = function:
      nixpkgs.lib.genAttrs supportedSystems (system:
        function (import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
          overlays = [
            devshell.overlays.default
          ];
        }));
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    devShells = forAllSystems (pkgs: {
      default = let
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "30" ];
          includeNDK = true;
        };

        androidSdk = androidComposition.androidsdk;
      in pkgs.devshell.mkShell {
        name = "rawandroid devshell";
        packages = with pkgs; [
          androidSdk
          envsubst
          gnumake
          jdk
          unzip
          zip
        ];
        env = [
          {
            name = "ANDROID_SDK_ROOT";
            eval = "${androidSdk}/libexec/android-sdk";
          }
          {
            name = "ANDROID_NDK_ROOT";
            eval = "${androidSdk}/libexec/android-sdk/ndk-bundle";
          }
        ];
        commands = [];
      };
    });
  };
}
