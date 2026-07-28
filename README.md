# homebrew-ferry

Homebrew tap for [Ferry](https://github.com/ramanbanka/ferry) — browse your Android
phone in Finder.

```bash
brew tap ramanbanka/ferry
brew trust ramanbanka/ferry
brew install --cask ferry
```

`brew trust` is Homebrew confirming you want it to run code from a tap outside its own
repositories. Ferry needs it because installing registers a background agent and
uninstalling stops it and unmounts cleanly — real commands rather than plain file
copies. It is asked once per machine.

That is all this repo is for. Homebrew requires a tap to live in a repo named
`homebrew-<name>`, so the cask cannot sit in the Ferry repo itself.

**Issues and pull requests belong in [ramanbanka/ferry](https://github.com/ramanbanka/ferry)**,
including anything about installation — this repo only holds the packaging.

## For maintainers

`Casks/ferry.rb` is partly generated. `scripts/release.sh` in the Ferry repo builds the
release tarball and writes the version and sha256 straight into this checkout, which it
expects at `../homebrew-ferry` (override with `TAP_DIR`). Commit what it wrote.

Never edit the version or checksum by hand. Tarballs embed timestamps, so every build
produces a different checksum, and a stale one makes Homebrew refuse to install for
everyone.

The `preflight` stanza that clears `com.apple.quarantine` is a workaround for Ferry
being unsigned: macOS kills a quarantined binary that has no Apple Developer ID, which
otherwise aborted the install on Macs whose security software marks new files. Delete
it once Ferry is signed and notarized.
