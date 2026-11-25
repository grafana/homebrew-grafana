class Rustanka < Formula
  desc "Rust implementation of Grafana Tanka"
  homepage "https://github.com/grafana/rustanka"
  version "0.3.1"
  license "MIT"

  on_arm do
    url "https://github.com/grafana/rustanka/releases/download/v0.3.1/rustanka-darwin-arm64"
    sha256 "e894d948aa4ecdbf3abcd13ca9a8fa837a311391b2238b7215da488770eded4a"
  end
  on_intel do
    url "https://github.com/grafana/rustanka/releases/download/v0.3.1/rustanka-darwin-amd64"
    sha256 "1aa20b154d07c3747c4fe5b18bd973555d6680caa6342d256a10376adc4ce550"
  end

  depends_on :macos

  conflicts_with "rtk", because: "both install an rtk executable"

  def install
    bin.install File.basename(stable.url) => "rtk"
    (bin/"rtk").chmod(0555)
  end

  test do
    system "#{bin}/rtk", "--version"
  end
end
