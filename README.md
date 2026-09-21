# dotfiles

Personal configuration managed with [mise](https://mise.jdx.dev). Source files
are kept in small package directories, while mise creates symlinks at the paths
expected by each application. Works on macOS and Linux.

```bash
gitleaks detect --source . -v
```

## Bootstrap a new machine

Install mise first using the official installation method, then run:

```bash
cd /path/to/dotfiles
mise trust
mise bootstrap --only dotfiles,tools --yes
```

The `pre-dotfiles` hook initializes the Neovim submodule before mise applies
the dotfiles. The bootstrap installs the versions declared in `mise.toml` and
creates the configured symlinks in `$HOME`.

Inspect the planned or current state with:

```bash
mise dotfiles status
mise dotfiles diff
mise dotfiles apply --dry-run
mise ls
mise doctor
```

## Repository layout

Source files stay as normal files in package directories. For example:

```text
tmux/tmux.conf             -> ~/.config/tmux/tmux.conf
starship/starship.toml     -> ~/.config/starship/starship.toml
scripts/tmux-sessionizer   -> ~/.local/scripts/tmux-sessionizer
zsh/.zshrc                 -> ~/.zshrc
```

Mise uses `symlink-each` for package directories so unmanaged files and
directories, such as tmux plugins and externally managed Claude skills, remain
in place.

VS Code configuration is intentionally not managed by this repository because
it is already synchronized through the GitHub account.

## Local / machine-specific overrides

Anything specific to one machine, OS, or distro goes in a gitignored local
file instead of the tracked files:

- `mise.local.toml` (copy from `mise.local.toml.example`) -- extra tools,
  version overrides, or tools restricted to one OS.
- `scripts/install/linux.local.sh` -- distro-specific package steps, sourced
  automatically by `scripts/install/linux.sh` if it exists.
- `~/.zsh_local` -- environment variables or aliases for one machine, sourced
  at the end of `.zshrc`.
