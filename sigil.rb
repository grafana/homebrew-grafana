class Sigil < Formula
  desc "CLI for the Grafana AI Observability (Sigil) agent plugins"
  homepage "https://github.com/grafana/sigil-sdk/tree/main/plugins/sigil"
  url "https://github.com/grafana/sigil-sdk/archive/refs/tags/plugins/sigil/v0.12.0.tar.gz"
  version "0.12.0"
  sha256 "7bc1be66c6d406622991b8a399bf216f4b8ddeff5307e1ab06208eac76de11bd"
  license "Apache-2.0"
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
        *std_go_args(ldflags: ldflags, output: bin/"sigil"),
        "./cmd/sigil"
    end
  end

  test do
    expected = build.head? ? "dev-" : "v#{version}"
    assert_match expected, shell_output("#{bin}/sigil --version")
  end
end
