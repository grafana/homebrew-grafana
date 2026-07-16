class Agento11y < Formula
  desc "CLI for the Grafana AI Observability (Sigil) agent plugins"
  homepage "https://github.com/grafana/sigil-sdk/tree/main/plugins/sigil"
  url "https://github.com/grafana/sigil-sdk/archive/refs/tags/plugins/sigil/v0.18.0.tar.gz"
  version "0.18.0"
  sha256 "5a0032312312f23955ddbace70623c9c148b509198cbf3aed28d9ff8acac048e"
  license "Apache-2.0"
  revision 1
  head "https://github.com/grafana/sigil-sdk.git", branch: "main"

  depends_on "go" => :build

  def install
    version_string = if build.head?
      "dev-#{Utils.git_short_head}"
    else
      "v#{version}"
    end

    cd "plugins/sigil" do
      ldflags = %W[
        -s -w
        -X main.version=#{version_string}
      ]

      system "go", "build",
        "-buildvcs=false",
        *std_go_args(ldflags: ldflags, output: bin/"agento11y"),
        "./cmd/sigil"
    end

    bin.install_symlink "agento11y" => "sigil"
  end

  test do
    expected = build.head? ? "dev-" : "v#{version}"
    assert_match expected, shell_output("#{bin}/agento11y --version")
    assert_match expected, shell_output("#{bin}/sigil --version")
  end
end
