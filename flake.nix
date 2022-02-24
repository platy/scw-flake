{
  description = "An over-engineered Hello World in bash";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = github:NixOS/nixpkgs;

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

        scaleway-cli = nixpkgs.scaleway-cli;
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
