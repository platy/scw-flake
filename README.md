# Scaleway flake controller

## Setup

You need nix setup on your local system and you will need a scaleway acccount. Your local nix setup must have flakes enabled.

Make sure you have the scaleway cli configured properly:

```sh
nix run .#scw -- init
```

## Create a default scaleway instance with nix & flakes ready

```sh
nix run create myinstance
```

Other commands available:

* list
* id
* ip
* ssh
* terminate
