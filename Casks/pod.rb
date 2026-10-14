cask "pod" do
  version "1.0.0-rc1"
  sha256 "a4be96421c6bdbd84ee6cbd371d41013189b20a679e04bf38985edc515888548"

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

  # ~/.orca stays: Orca.app shares it. Claude account items in the Keychain stay too.
  zap trash: [
    "~/.pod",
    "~/Library/Application Support/codes.pod.native",
    "~/Library/Application Support/Pod",
    "~/Library/Application Support/PodNative",
    "~/Library/Caches/codes.pod.native",
    "~/Library/HTTPStorages/codes.pod.native",
    "~/Library/Preferences/codes.pod.app.plist",
    "~/Library/Preferences/codes.pod.native.plist",
    "~/Library/Saved Application State/codes.pod.native.savedState",
  ]
end
