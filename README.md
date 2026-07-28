# homebrew-ferry

Homebrew tap for [Ferry](https://github.com/ramanbanka/ferry) — browse your Android
phone in Finder.

```bash
brew tap ramanbanka/ferry
brew install --cask ferry
```

That is all this repo is for. Homebrew requires a tap to live in a repo named
`homebrew-<name>`, so the cask cannot sit in the Ferry repo itself.

**Issues and pull requests belong in [ramanbanka/ferry](https://github.com/ramanbanka/ferry)**,
including anything about installation — this repo holds one generated file.

## For maintainers

`Casks/ferry.rb` is generated. `scripts/release.sh` in the Ferry repo builds the
release tarball and writes the version and sha256 into it; copy the result here and
commit. Editing the version or checksum by hand is how the two drift apart, and a
wrong checksum makes Homebrew refuse to install for everyone.
