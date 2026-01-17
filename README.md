```
    ____  ____  ____  ______
   / __ )/ __ \/ __ \/_  __/
  / __  / / / / / / / / /   
 / /_/ / /_/ / /_/ / / /    
/_____/\____/\____/ /_/     

```

# Boot

Boot is like the good ol’ _Goodies Disk_ that came with early Macintosh computers. For your Terminal. Only a fraction of fun.


## What it does

1. Install [Homebrew](https://brew.sh) and [Zsh](https://www.zsh.org) (if needed).
3. Install [Starship](https://starship.rs), [fzf](https://github.com/junegunn/fzf), and my [tools tap](https://github.com/matmartinez/homebrew-tools).
3. Install Boot to `.zshrc` so to get some neat built-in scripts and aliases.

## Getting started

Quick install (no clone):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/matmartinez/boot/main/install.sh)"
```

This clones Boot into `~/.boot`.

Or, clone this repository to a permanent location of your liking on your hard drive. Maybe `~/Developer`? It looks really good on the Finder.

```sh
mkcd ~/Developer
git clone https://github.com/matmartinez/boot
cd boot
```

Then run the install script:

```sh
./install.sh
```

You’re done.
