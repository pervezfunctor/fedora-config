# Fedora Niri Config

## Bootstrap

Run the bootstrap script:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/pervezfunctor/fedora-niri-config/main/setup)"
```

The bootstrap script clones the repo to `~/.fedora-niri-config`, installs pixi and configures shell.

## Nushell setup commands

After the repo is available locally, run the Nushell entrypoint directly:

```sh
setup.nu
```

Available commands include:

```sh
setup.nu help
setup.nu niri
setup.nu flatpaks
setup.nu virt
```

## Dotfile layout

`setup.nu stow` is intentionally simple.

- Pass a package name like `kitty`, or `niri`
- The package is resolved from `$DOT_DIR/<package>`
- Files are linked into `~/.config/<package>/...`

Example:

```sh
setup.nu stow niri
```

This links files from `$DOT_DIR/niri` into `~/.config/niri`.

You could also install `homebrew` for linux.

```bash
setup.nu brew
```

And install packages using brew.

```bash
brew install --cask antigravity-linux
```
