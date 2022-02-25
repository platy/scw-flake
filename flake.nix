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
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in

    {

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          inherit (pkgs) scaleway-cli;
          scw-flake = pkgs.stdenv.mkDerivation rec {
            name = "scw-flake-${version}";

            src = ./.;

            buildInputs = [pkgs.bash pkgs.scaleway-cli];

            buildPhase =
              ''
                echo '#!${pkgs.bash}/bin/bash
                  unset PATH
                  PATH=${pkgs.scaleway-cli}/bin
                  ' | cat - scw-flake.sh > scw-flake.pathed.sh
                chmod +x scw-flake.pathed.sh;
              '';

            installPhase =
              ''
                mkdir -p $out/bin
                cp scw-flake.pathed.sh $out/bin/scw-flake.sh
              '';
          };
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
