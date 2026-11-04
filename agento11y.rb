class Agento11y < Formula
  desc "CLI for the Grafana Agent Observability plugins"
  homepage "https://github.com/grafana/agento11y/tree/main/plugins/agento11y"
  url "https://github.com/grafana/agento11y/archive/refs/tags/plugins/agento11y/v0.57.0.tar.gz"
  version "0.57.0"
  sha256 "3b6b13eace4218628d54a100dbbcf67a634678e61be3c43821a970404393b03d"
  license "Apache-2.0"
  head "https://github.com/grafana/agento11y.git", branch: "main"

  depends_on "go" => :build

  def install
    version_string = if build.head?
      "dev-#{Utils.git_short_head}"
    else
      "v#{version}"
    end

    cd "plugins/agento11y" do
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
