cask "pod" do
  version "1.0.0-rc3"
  sha256 "5f0338832a3ec2353438a1fc343ef6f3918dc2d402e94c5993b93f079c1144d8"

  url "https://github.com/outof-place/pod/releases/download/v#{version}/Pod-#{version}.dmg"
  name "Pod"
  desc "Run a pod of coding agents in parallel"
  homepage "https://pod.codes/"

  # Pod ships release candidates as GitHub prereleases; the `appcast` tag holds Sparkle's feed.
  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+(?:-[a-z]+\.?\d+)?)$/i)
    strategy :github_releases do |json, regex|
      json.map do |release|
        next if release["draft"]

        match = release["tag_name"]&.match(regex)
        next if match.blank?

        match[1]
      end
    end
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :golden_gate

  app "Pod.app"
  # The CLI is `podx`: `pod` is CocoaPods. podx resolves its own symlink to find the app.
  binary "#{appdir}/Pod.app/Contents/Helpers/Pod Runtime.app/Contents/Resources/bin/podx"

  # ~/.orca stays: Orca.app shares it. Keychain items stay too.
  # Application Support/Pod is listed entry by entry (read from an isolated RC1 profile), so
  # claude-accounts, claude-profiles and Codex homes survive: claude-acc keeps using those
  # account stores after Pod is gone.
  # Pod's terminal daemon runs as a launchd job in the user's GUI session, one job per launch,
  # labelled codes.pod.daemon.<profile hash>.<launch id>. Its plist is written to Application
  # Support/Pod/daemon/launchd (zapped with daemon below) and deleted once bootstrapped, never to a
  # LaunchAgents folder, and Pod boots out a job whose daemon has exited. Only zap stops a running
  # one: Homebrew runs `uninstall launchctl:` on `brew upgrade` too, which would end the terminal
  # sessions an update keeps. The job hosts Pod's terminals: zap from another terminal.
  zap launchctl: "codes.pod.daemon.*",
      trash:     [
        "~/.pod",
        "~/Library/Application Support/codes.pod.native",
        "~/Library/Application Support/Pod/.profile-state-access",
        "~/Library/Application Support/Pod/agent-hooks",
        "~/Library/Application Support/Pod/agent-session-authority.key",
        "~/Library/Application Support/Pod/blob_storage",
        "~/Library/Application Support/Pod/Cache",
        "~/Library/Application Support/Pod/Code Cache",
        "~/Library/Application Support/Pod/codex-hook-trust.json",
        "~/Library/Application Support/Pod/codex-session-backfill",
        "~/Library/Application Support/Pod/Crashpad",
        "~/Library/Application Support/Pod/daemon",
        "~/Library/Application Support/Pod/daemon-host.noindex",
        "~/Library/Application Support/Pod/DawnGraphiteCache",
        "~/Library/Application Support/Pod/DawnWebGPUCache",
        "~/Library/Application Support/Pod/declarative_performance_observer.db",
        "~/Library/Application Support/Pod/declarative_performance_observer.db-journal",
        "~/Library/Application Support/Pod/DevToolsActivePort",
        "~/Library/Application Support/Pod/DIPS",
        "~/Library/Application Support/Pod/GPUCache",
        "~/Library/Application Support/Pod/GPUPersistentCache",
        "~/Library/Application Support/Pod/GraphiteDawnCache",
        "~/Library/Application Support/Pod/http1-compatibility.json",
        "~/Library/Application Support/Pod/IndexedDB",
        "~/Library/Application Support/Pod/Local State",
        "~/Library/Application Support/Pod/Local Storage",
        "~/Library/Application Support/Pod/logs",
        "~/Library/Application Support/Pod/macos-press-and-hold-default.json",
        "~/Library/Application Support/Pod/Network Persistent State",
        "~/Library/Application Support/Pod/omp-managed-status-extension",
        "~/Library/Application Support/Pod/orca-data.json",
        "~/Library/Application Support/Pod/orca-profile-index.json",
        "~/Library/Application Support/Pod/orca-stats.json",
        "~/Library/Application Support/Pod/orchestration.db",
        "~/Library/Application Support/Pod/Partitions",
        "~/Library/Application Support/Pod/pod-plugin-defaults.json",
        "~/Library/Application Support/Pod/pod-ui-host",
        "~/Library/Application Support/Pod/Preferences",
        "~/Library/Application Support/Pod/profiles",
        "~/Library/Application Support/Pod/Session Storage",
        "~/Library/Application Support/Pod/Shared Dictionary",
        "~/Library/Application Support/Pod/shell-wrappers",
        "~/Library/Application Support/Pod/terminal-history",
        "~/Library/Application Support/Pod/Trust Tokens",
        "~/Library/Application Support/Pod/Trust Tokens-journal",
        "~/Library/Application Support/Pod/WebStorage",
        "~/Library/Application Support/PodNative",
        "~/Library/Caches/codes.pod.native",
        "~/Library/HTTPStorages/codes.pod.native",
        "~/Library/Preferences/codes.pod.app.plist",
        "~/Library/Preferences/codes.pod.native.plist",
        "~/Library/Saved Application State/codes.pod.native.savedState",
      ]

  caveats <<~EOS
    `brew uninstall --zap #{token}` stops the daemon that runs Pod's terminal sessions.
    Run it from a terminal outside Pod (Terminal.app, for example): inside Pod it ends
    its own terminal, and with it the zap.
  EOS
end
