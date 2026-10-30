# Ferry — Homebrew cask.
#
# Binaries are published at https://github.com/ramanbanka/ferry-releases. This repo
# exists only because Homebrew looks for taps in a repo named homebrew-<name>.
#
# Linting needs the cask to be resolvable through a tap — Homebrew 6.x removed
# `brew audit <path>`. Symlink this checkout in as a tap once:
#
#   ln -s "$PWD" "$(brew --repository)/Library/Taps/ramanbanka/homebrew-ferry"
#
#   brew audit --cask --strict ramanbanka/ferry/ferry
#   brew style              ramanbanka/ferry/ferry
#
# Edits are then picked up with no copying.

cask "ferry" do
  version "0.5.0"
  # Both lines above are written by scripts/release.sh in the ferry repo. Do not
  # edit by hand: tarballs embed timestamps, so every build has a different
  # checksum, and a mismatch makes Homebrew refuse to install for everyone.
  sha256 "71078dc26992e4b78b831979a85c252707643462ba0454298c0f002335cc3ce7"

  url "https://github.com/ramanbanka/ferry-releases/releases/download/v#{version}/ferry-#{version}-macos-arm64.tar.gz"
  name "Ferry"
  desc "Browse your Android phone in Finder, over USB or Wi-Fi"
  homepage "https://github.com/ramanbanka/ferry-releases"

  # Only arm64 builds are published today. An Intel cask would need a second
  # tarball and a sha256 per architecture.
  depends_on arch: :arm64
  # A cask CAN depend on another cask — this is why Ferry ships as a cask rather
  # than a formula. adb (android-platform-tools) is a cask, and formulae are not
  # allowed to depend on casks, which previously left users to install it by hand.
  depends_on cask: "android-platform-tools"
  # Used to post notifications from a properly signed bundle. Without it Ferry
  # falls back to osascript, whose banners are attributed to "Script Editor" and
  # whose button opens Script Editor instead of your files.
  depends_on formula: "terminal-notifier"
  depends_on :macos

  # Register the background agent so phones mount automatically: `brew install --cask
  # ferry` is the only command a user needs to run. `enable` also stops an older agent
  # first, which is what makes an upgrade switch to the new version.
  #
  # An installer script, not `postflight_steps`: steps run in Homebrew's sandbox, where
  # launchd and `open` both refuse to start anything, so Ferry installed but never ran.
  # Installer scripts run outside it (see "Cask artifact trust and sandboxing" in the
  # Cask Cookbook). It runs before the binary is linked, so it uses the staged copy;
  # every upgrade runs `disable` then this again, which points launchd at the new one.
  installer script: {
    executable: "ferry-#{version}-macos-arm64/ferry",
    args:       ["enable"],
  }
  # The tarball unpacks to a versioned directory; point at the binary inside it.
  binary "ferry-#{version}-macos-arm64/ferry"

  # Clear the quarantine flag before anything tries to run the binary.
  #
  # macOS refuses to execute a quarantined program that is not signed with an Apple
  # Developer ID, and kills it outright — no dialog, just SIGKILL. Homebrew does not
  # set the flag itself, but security software on managed Macs marks every newly
  # written file, which killed the setup command below and aborted the whole install.
  #
  # Remove this once Ferry is signed and notarized; it will no longer be needed.
  preflight_steps do
    run "/usr/bin/xattr",
        args:         ["-d", "com.apple.quarantine", "ferry-#{version}-macos-arm64/ferry"],
        chdir:        ".",
        must_succeed: false,
        print_stderr: false
  end

  # Stop and deregister the agent before the binary disappears, otherwise launchd
  # keeps trying to run a path that no longer exists and mounts are left behind.
  uninstall script: {
    executable:   "#{HOMEBREW_PREFIX}/bin/ferry",
    args:         ["disable"],
    must_succeed: false,
  }

  zap trash: [
    "~/Library/Application Support/Ferry",
    "~/Library/LaunchAgents/com.ferry.agent.plist",
    "~/Library/Logs/ferry.log",
    "~/Library/Logs/ferry.log.1",
  ]

  caveats <<~EOS
    On the phone, once:
      Settings > About phone > tap "Build number" 7 times
      Settings > Developer options > USB debugging > ON

    Then plug it in, unlock it, and tap "Allow" on "Allow USB debugging?".

    For Wi-Fi, also turn on Wireless debugging in Developer options.

    To check on it: ferry status
  EOS
end
