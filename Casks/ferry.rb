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
  version "0.3.0"
  # Both lines above are written by scripts/release.sh in the ferry repo. Do not
  # edit by hand: tarballs embed timestamps, so every build has a different
  # checksum, and a mismatch makes Homebrew refuse to install for everyone.
  sha256 "2593eeaeb6aa9a7742eca9a521c25a4602756be19b2d4af0c8e7c4a253b3ba33"

  url "https://github.com/ramanbanka/ferry-releases/releases/download/v#{version}/ferry-#{version}-macos-arm64.tar.gz"
  name "Ferry"
  desc "Browse your Android phone in Finder over USB"
  homepage "https://github.com/ramanbanka/ferry-releases"

  # Only arm64 builds are published today. An Intel cask would need a second
  # tarball and a sha256 per architecture.
  depends_on arch: :arm64
  depends_on macos: :big_sur
  # A cask CAN depend on another cask — this is why Ferry ships as a cask rather
  # than a formula. adb (android-platform-tools) is a cask, and formulae are not
  # allowed to depend on casks, which previously left users to install it by hand.
  depends_on cask: "android-platform-tools"
  # Used to post notifications from a properly signed bundle. Without it Ferry
  # falls back to osascript, whose banners are attributed to "Script Editor" and
  # whose button opens Script Editor instead of your files.
  depends_on formula: "terminal-notifier"

  # The tarball unpacks to a versioned directory; point at the binary inside it.
  binary "ferry-#{version}-macos-arm64/ferry"

  # Clear the quarantine flag before anything tries to run the binary.
  #
  # macOS refuses to execute a quarantined program that is not signed with an Apple
  # Developer ID, and kills it outright — no dialog, just SIGKILL. Homebrew does not
  # set the flag itself, but security software on managed Macs marks every newly
  # written file, which killed the postflight command below and aborted the whole
  # install. Clearing it here runs before the binary is linked or executed.
  #
  # Remove this once Ferry is signed and notarized; it will no longer be needed.
  preflight do
    system_command "/usr/bin/xattr",
                   args:         ["-d", "com.apple.quarantine",
                                  "#{staged_path}/ferry-#{version}-macos-arm64/ferry"],
                   must_succeed: false
  end

  # Register the background agent so phones mount automatically. This is the whole
  # point of shipping as a cask: `brew install --cask ferry` is the only command a
  # user needs to run.
  #
  # `enable` registers Ferry with launchd and starts it, which is the whole setup.
  postflight do
    system_command "#{HOMEBREW_PREFIX}/bin/ferry",
                   args:         ["enable"],
                   print_stdout: true
  end

  # Stop and deregister the agent before the binary disappears, otherwise launchd
  # keeps trying to run a path that no longer exists and mounts are left behind.
  #
  # This runs the binary that is currently installed, which during an upgrade is the
  # older one — so a version whose CLI predates `disable` cannot be upgraded through
  # the cask and must be uninstalled first.
  uninstall_preflight do
    system_command "#{HOMEBREW_PREFIX}/bin/ferry",
                   args:         ["disable"],
                   must_succeed: false
  end

  zap trash: [
    "~/Library/LaunchAgents/com.ferry.agent.plist",
    "~/Library/Logs/ferry.log",
  ]

  caveats <<~EOS
    Ferry is set up and will mount phones automatically.

    One thing you must do on the phone, once:
      Settings > About phone > tap "Build number" 7 times
      Settings > Developer options > USB debugging > ON
    Then plug it in, unlock it, and accept the "Allow USB debugging?" prompt.

    Your phone then appears in Finder under ~/Ferry/<PhoneModel>.

      ferry status      # agent, mounts, connected phones
      ferry stop        # stop until your next login
      ferry disable     # stop, and keep it from starting at login

    Logs: ~/Library/Logs/ferry.log
  EOS
end
