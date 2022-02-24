{
  description = "An over-engineered Hello World in bash";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        scw-flake = with final; stdenv.mkDerivation rec {
          name = "scw-flake-${version}";

          src = ./.;

          installPhase =
            ''
              mkdir -p $out/bin
              cp scw-flake.sh $out/bin/
            '';
        };

        scaleway-cli = with final; stdenv.mkDerivation 
          buildGoModule rec {
            pname = "scaleway-cli";
            version = "2.4.0";

            src = fetchFromGitHub {
              owner = "scaleway";
              repo = "scaleway-cli";
              rev = "v${version}";
              sha256 = "yYzcziEKPSiMvw9LWd60MkHmYFAvN7Qza6Z117NOOv0=";
            };

            vendorSha256 = "7cGVeja1YE96PEV1IRklyh6MeMDFAP+2TpYvvFkBYnQ=";

            # some tests require network access to scaleway's API, failing when sandboxed
            doCheck = false;

            meta = with lib; {
              description = "Interact with Scaleway API from the command line";
              homepage = "https://github.com/scaleway/scaleway-cli";
              license = licenses.mit;
            };
          };
      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) scaleway-cli;
          inherit (nixpkgsFor.${system}) scw-flake;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.scw-flake);

      apps = forAllSystems (system:
        {
          scw = {
            type = "app";
            program = "${self.packages.${system}.scaleway-cli}/bin/scw";
          };
          scw-flake = {
            type = "app";
            program = "${self.packages.${system}.scw-flake}/bin/scw-flake.sh";
          };
        });
      
      defaultApp = forAllSystems (system: self.apps.${system}.scw-flake);
    };
}
