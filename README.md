# Deep Clean

Make sure your git repos are nice and tidy with this simple script! Essentially, the script should
be added as a git alias to easily have access to it. With that setup, it's possible to just use
`git dc` to automatically clean the current git repo.

The script makes use of existing git facilities, such as `git remote prune` and `git gc`.

# Usage

From any git repository, simply run the alias you've set (`dc` by default) and optionally specify a
remote to prune :

```
$ git dc
```

or

```
$ git dc upstream
```

# Installation

Installing the script is super simple, just run the command below!
```
$ curl -O --silent https://raw.githubusercontent.com/marier-nico/git-deep-clean/main/install.sh && sh install.sh
```

The install script will prompt you to ask where you would like to install the script and what the
alias for it should be in your git config.

# Updating

The script will try to update every time it is run (and will do nothing if you have the latest
version), so you don't really have to think about updating.
