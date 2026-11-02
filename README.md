# Dotfiles

## Setup

Clone the bare repository into `~/.dotfiles`:

```bash
git clone --bare <repo-url> "\$HOME/.dotfiles"
```

Check out the tracked files into your home directory. This uses the repo as the source of truth and may overwrite existing files at those paths:

```bash
git --git-dir="\$HOME/.dotfiles/" --work-tree="\$HOME" checkout --force
```

Hide untracked files from the repository’s status output:

```bash
git --git-dir="\$HOME/.dotfiles/" --work-tree="\$HOME" \\
  config --local status.showUntrackedFiles no
```

### Post Setup

Package lists, GPU-specific packages, and the remaining manual steps (Nextcloud password and account) are in [fresh-arch-hyprland-install.md](https://github.com/jdbrannon/scripts/blob/main/docs/pc/linux/arch/fresh-arch-hyprland-install.md).

After that, log out and back in. `hyprland.lua` handles the rest (calendar sync timer, default calendar, Spotify theme).
