class Sigil < Formula
  desc "Hook binary for the Grafana AI Observability (Sigil) agent plugins"
  homepage "https://github.com/grafana/sigil-sdk/tree/main/plugins/sigil"
  url "https://github.com/grafana/sigil-sdk/archive/refs/tags/plugins/sigil/v0.4.0.tar.gz"
  version "0.4.0"
  sha256 "0ebbaaf0a87a17fc1ad8e8e010c1cb50fd19fe2092e83bac018eddec69a65441"
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
