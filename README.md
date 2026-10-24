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

1. Install kitty and zsh
2. Set kitty as default terminal
