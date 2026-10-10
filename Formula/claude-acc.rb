class ClaudeAcc < Formula
  desc "Menu bar control room for a Mac that runs Claude Code agents all day"
  homepage "https://github.com/outof-place/claude-acc"
  url "https://github.com/outof-place/claude-acc/archive/refs/tags/v1.31.7.tar.gz"
  sha256 "0558b21233169c1a449d27bf04d18e5def16192921f25eb78c67038480da1002"
  license "MIT"
  head "https://github.com/outof-place/claude-acc.git", branch: "main"

  depends_on arch: :arm64
  depends_on macos: :tahoe
  uses_from_macos "swift" => :build

  def install
    cd "app" do
      system "swift", "build", *std_swift_args
      contents = prefix/"Claude Acc.app/Contents"
      (contents/"MacOS").install ".build/release/ClaudeAcc"
      contents.install "Info.plist"
      libexec.install ".build/release/fanctl", ".build/release/claude-acc-hook", ".build/release/claude-acc-pause",
                      ".build/release/claude-acc-desktop"
    end
    # the desktop gateway helper keeps a fixed designated requirement, so its Screen Recording and
    # Accessibility grants survive upgrades (same as install.sh)
    system "codesign", "--force", "--sign", "-", "--identifier", "com.filip.claude-acc.desktop",
           "-r=designated => identifier \"com.filip.claude-acc.desktop\"", libexec/"claude-acc-desktop"
    system "codesign", "--force", "--sign", "-", prefix/"Claude Acc.app"

    # setup.sh copies every *.py next to it, so new scripts come along without touching this list
    libexec.install Dir["*.py"], "janitor-root.sh", "perf-root.sh", "root-install.sh", "root-run.sh", "setup.sh",
                    "install-fans.sh", "install-fsguard.sh", "sign-app.sh", "launchd", "hooks", "skills", "sdk",
                    "dictation", "orca-plugin"

    # setup.sh copies everything into the user's account; opt paths survive upgrades
    (bin/"claude-acc-setup").write <<~SH
      #!/bin/bash
      exec "#{opt_libexec}/setup.sh" --app "#{opt_prefix}/Claude Acc.app" --fanctl "#{opt_libexec}/fanctl" \\
        --hook "#{opt_libexec}/claude-acc-hook" --desktop "#{opt_libexec}/claude-acc-desktop" "$@"
    SH
    # the real command lives in ~/.local/bin, which may not be on PATH
    (bin/"claude-acc").write <<~SH
      #!/bin/sh
      command="$HOME/.local/bin/claude-acc"
      [ -x "$command" ] || { echo "claude-acc: run claude-acc-setup first" >&2; exit 1; }
      exec "$command" "$@"
    SH
  end

  def caveats
    <<~EOS
      Put the scripts, the launchd jobs and the menu bar app into your account:
        claude-acc-setup
      Run it again after every `brew upgrade claude-acc`.

      Fan control is a small root daemon, installed separately:
        claude-acc fans install

      The Orca plugin (status bar, panel, Cmd-J commands) installs with:
        claude-acc orca install
      then enable the plugin system and approve Claude Acc in Orca's Settings > Plugins.

      To keep agents from starting a second dev server of the same app, add the
      Claude Code hook from https://github.com/outof-place/claude-acc#dev-server-guard

      Before `brew uninstall`, remove what setup put in your account:
        claude-acc fans uninstall && claude-acc uninstall
    EOS
  end

  test do
    assert_path_exists prefix/"Claude Acc.app/Contents/MacOS/ClaudeAcc"
    assert_match "\"mode\"", shell_output("/usr/bin/python3 #{libexec}/devguard.py status --json")
    assert_match "rpm", shell_output("#{libexec}/fanctl read")
    assert_match "\"on\"", shell_output("/usr/bin/python3 #{libexec}/perf.py ultra status --json")
    assert_match "Aktualizacje", shell_output("/usr/bin/python3 #{libexec}/updates.py status")
    assert_path_exists libexec/"claude-acc-hook"
    assert_path_exists libexec/"claude-acc-pause"
    assert_path_exists libexec/"claude-acc-desktop"
    assert_path_exists libexec/"dictation/slownik.txt"
    assert_path_exists libexec/"sign-app.sh"
    assert_path_exists libexec/"root-run.sh"
    assert_path_exists libexec/"orca-plugin/orca-plugin.json"
    assert_match "\"known\"", shell_output("/usr/bin/python3 #{libexec}/awake.py status --json")
    assert_match "\"keychain_service\"", shell_output("/usr/bin/python3 #{libexec}/orcahost.py")
  end
end
