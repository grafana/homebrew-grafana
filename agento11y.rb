class Agento11y < Formula
  desc "CLI for the Grafana AI Observability (Sigil) agent plugins"
  homepage "https://github.com/grafana/sigil-sdk/tree/main/plugins/sigil"
  url "https://github.com/grafana/sigil-sdk/archive/refs/tags/plugins/sigil/v0.19.0.tar.gz"
  version "0.19.0"
  sha256 "9cb3150c1fd0881d72e47c3321d26a908a6e29f7340c83e61b9d608484087178"
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
        *std_go_args(ldflags: ldflags, output: bin/"agento11y"),
        "./cmd/agento11y"
    end

    bin.install_symlink "agento11y" => "sigil"
  end

  test do
    expected = build.head? ? "dev-" : "v#{version}"
    assert_match expected, shell_output("#{bin}/agento11y --version")
    assert_match expected, shell_output("#{bin}/sigil --version")
  end
end
