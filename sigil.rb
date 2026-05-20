class Sigil < Formula
  desc "Hook binary for the Grafana AI Observability (Sigil) agent plugins"
  homepage "https://github.com/grafana/sigil-sdk/tree/main/plugins/sigil"
  url "https://github.com/grafana/sigil-sdk/archive/refs/tags/plugins/sigil/v0.2.0.tar.gz"
  version "0.2.0"
  sha256 "8abb86359ddf1584f27b4128c92ecdd00ff46b0fb4d4e120b074fc1f390d1677"
  license "Apache-2.0"
  head "https://github.com/grafana/sigil-sdk.git", branch: "main"

  depends_on "go" => :build

  def install
    cd "plugins/sigil" do
      ldflags = %W[
        -s -w
        -X main.version=v#{version}
      ]

      system "go", "build",
        "-buildvcs=false",
        *std_go_args(ldflags: ldflags, output: bin/"sigil"),
        "./cmd/sigil"
    end
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/sigil --version")
  end
end
