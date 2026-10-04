class ClaudeAcc < Formula
  desc "Menu bar control room for a Mac that runs Claude Code agents all day"
  homepage "https://github.com/outof-place/claude-acc"
  url "https://github.com/outof-place/claude-acc/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "d7e9b3adc47f45dc784ade9c35a6c1fbe2111e69d2993dce0854b682d7060920"
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
      libexec.install ".build/release/fanctl"
    end
    system "codesign", "--force", "--sign", "-", prefix/"Claude Acc.app"

    libexec.install "accswitch.py", "janitor.py", "devguard.py", "perf.py", "janitor-root.sh",
                    "perf-root.sh", "setup.sh", "install-fans.sh", "launchd", "hooks"

    # setup.sh copies everything into the user's account; opt paths survive upgrades
    (bin/"claude-acc-setup").write <<~SH
      #!/bin/bash
      exec "#{opt_libexec}/setup.sh" --app "#{opt_prefix}/Claude Acc.app" --fanctl "#{opt_libexec}/fanctl" "$@"
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
  end
end
